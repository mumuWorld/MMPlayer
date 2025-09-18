//
//  ShareViewController.swift
//  MMShareExtension
//
//  Created by 杨杰 on 2023/5/25.
//  Copyright © 2023 Mumu. All rights reserved.
//

import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers
import Foundation

class ShareViewController: SLComposeServiceViewController {

    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        return true
    }

    override func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
        
        if let extensionContext = extensionContext {
            handleSharedContent(context: extensionContext)
        } else {
            // 如果没有扩展上下文，直接完成
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }

    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
    }
    
    private func handleSharedContent(context: NSExtensionContext) {
        guard let inputItems = context.inputItems as? [NSExtensionItem] else { 
            print("No input items found")
            completeRequest()
            return 
        }
        
        var hasVideoAttachment = false
        let dispatchGroup = DispatchGroup()
        
        for item in inputItems {
            guard let attachments = item.attachments else { continue }
            
            for attachment in attachments {
                print("检查附件类型: \(attachment.registeredTypeIdentifiers)")
                
                // 检查多种视频类型
                let videoTypes = [
                    UTType.movie.identifier,
                    UTType.video.identifier,
                    UTType.quickTimeMovie.identifier,
                    UTType.mpeg4Movie.identifier,
                    "public.movie"
                ]
                
                for videoType in videoTypes {
                    if attachment.hasItemConformingToTypeIdentifier(videoType) {
                        print("发现视频类型: \(videoType)")
                        hasVideoAttachment = true
                        dispatchGroup.enter()
                        
                        // 使用 loadItem 加载视频，让系统决定返回类型
                        attachment.loadItem(forTypeIdentifier: videoType, options: nil) { [weak self] (data, error) in
                            defer { dispatchGroup.leave() }
                            
                            DispatchQueue.main.async {
                                if let error = error {
                                    print("Error loading video: \(error)")
                                    return
                                }
                                
                                print("收到数据类型: \(type(of: data))")
                                
                                // 尝试多种方式获取URL
                                var videoURL: URL? = nil
                                
                                if let url = data as? URL {
                                    videoURL = url
                                } else if let data = data as? Data {
                                    // 如果是Data，尝试创建临时文件
                                    let tempURL = self?.saveDataToTempFile(data: data, fileExtension: "mp4")
                                    videoURL = tempURL
                                } else if let string = data as? String {
                                    videoURL = URL(string: string)
                                } else if let securedResource = data as? NSSecureCoding {
                                    print("收到安全编码资源: \(securedResource)")
                                    // 可能是 _EXItemProviderSandboxedResource 类型
                                }
                                
                                if let url = videoURL {
                                    print("获取到视频URL: \(url.absoluteString)")
                                    if url.isFileURL {
                                        print("URL是否可访问: \(url.startAccessingSecurityScopedResource())")
                                    }
                                    self?.openMainAppWithVideo(url: url)
                                    if url.isFileURL {
                                        url.stopAccessingSecurityScopedResource()
                                    }
                                } else {
                                    print("无法处理数据类型: \(type(of: data))")
                                }
                            }
                        }
                        break // 找到视频类型就退出内层循环
                    }
                }
            }
        }
        
        if !hasVideoAttachment {
            print("没有找到视频附件")
            completeRequest()
        } else {
            // 等待所有视频处理完成后再完成请求
            dispatchGroup.notify(queue: .main) { [weak self] in
                self?.completeRequest()
            }
        }
    }
    
    private func completeRequest() {
        DispatchQueue.main.async { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }
    
    private func saveDataToTempFile(data: Data, fileExtension: String) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString + "." + fileExtension
        let tempURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try data.write(to: tempURL)
            print("保存临时文件到: \(tempURL.absoluteString)")
            return tempURL
        } catch {
            print("保存临时文件失败: \(error)")
            return nil
        }
    }
    
    private func openMainAppWithVideo(url: URL) {
        // 先将视频复制到 App Group 共享目录，获取新的URL
        if let sharedURL = handleVideo(url: url) {
            // 使用共享目录中的URL创建自定义 scheme
            let urlString = "mmplayer://video?path=\(sharedURL.absoluteString)"
            if let customURL = URL(string: urlString) {
                openURL(customURL)
            }
        } else {
            // 如果复制失败，使用原始URL
            let urlString = "mmplayer://video?path=\(url.absoluteString)"
            if let customURL = URL(string: urlString) {
                openURL(customURL)
            }
        }
    }
    
    private func handleVideo(url: URL) -> URL? {
        // 复制到 App Group 目录下的 received 文件夹
        let fm = FileManager.default
        if let containerURL = fm.containerURL(forSecurityApplicationGroupIdentifier: "group.mumu.player") {
            // 使用与主应用相同的 received 路径
            let receivedDir = containerURL.appendingPathComponent("received")
            do {
                if !fm.fileExists(atPath: receivedDir.path) {
                    try fm.createDirectory(at: receivedDir, withIntermediateDirectories: true, attributes: nil)
                }
                
                // 生成不重复的文件名
                let fileName = url.lastPathComponent
                var targetURL = receivedDir.appendingPathComponent(fileName)
                var counter = 1
                
                // 如果文件已存在，添加数字后缀
                while fm.fileExists(atPath: targetURL.path) {
                    let nameWithoutExt = (fileName as NSString).deletingPathExtension
                    let ext = (fileName as NSString).pathExtension
                    let newFileName = ext.isEmpty ? "\(nameWithoutExt)_\(counter)" : "\(nameWithoutExt)_\(counter).\(ext)"
                    targetURL = receivedDir.appendingPathComponent(newFileName)
                    counter += 1
                }
                
                try fm.copyItem(at: url, to: targetURL)
                print("视频已保存到接收目录: \(targetURL)")
                return targetURL
            } catch {
                print("保存到接收目录失败: \(error)")
                return nil
            }
        }
        return nil
    }
    
    @objc func openURL(_ url: URL) {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                application.open(url, options: [:], completionHandler: nil)
                return
            }
            responder = responder?.next
        }
    }
}
