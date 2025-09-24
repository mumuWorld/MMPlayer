//
//  ActionViewController.swift
//  MMAction
//
//  Created by 杨杰 on 2025/9/23.
//  Copyright © 2025 Mumu. All rights reserved.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers
import Foundation

class ActionViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 处理分享的内容
        if let extensionContext = self.extensionContext {
            handleSharedContent(context: extensionContext)
        }
    }

    @IBAction func done() {
        // 完成请求
        completeRequest()
    }
    
    private func handleSharedContent(context: NSExtensionContext) {
        guard let inputItems = context.inputItems as? [NSExtensionItem] else { 
            print("No input items found")
            completeRequest()
            return 
        }
        
        var hasMediaAttachment = false
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
                
                // 检查多种音频类型
                let audioTypes = [
                    UTType.audio.identifier,
                    UTType.mp3.identifier,
                    UTType.wav.identifier,
                    UTType.aiff.identifier,
                    "public.audio"
                ]
                
                // 合并所有媒体类型
                let mediaTypes = videoTypes + audioTypes
                
                for mediaType in mediaTypes {
                    if attachment.hasItemConformingToTypeIdentifier(mediaType) {
                        let isVideo = videoTypes.contains(mediaType)
                        print("发现\(isVideo ? "视频" : "音频")类型: \(mediaType)")
                        hasMediaAttachment = true
                        dispatchGroup.enter()
                        
                        // 使用 loadItem 加载媒体，让系统决定返回类型
                        attachment.loadItem(forTypeIdentifier: mediaType, options: nil) { [weak self] (data, error) in
                            defer { dispatchGroup.leave() }
                            
                            DispatchQueue.main.async {
                                if let error = error {
                                    print("Error loading media: \(error)")
                                    return
                                }
                                
                                print("收到数据类型: \(type(of: data))")
                                
                                // 尝试多种方式获取URL
                                var mediaURL: URL? = nil
                                
                                if let url = data as? URL {
                                    mediaURL = url
                                } else if let data = data as? Data {
                                    // 如果是Data，尝试创建临时文件
                                    let fileExtension = isVideo ? "mp4" : "mp3"
                                    let tempURL = self?.saveDataToTempFile(data: data, fileExtension: fileExtension)
                                    mediaURL = tempURL
                                } else if let string = data as? String {
                                    mediaURL = URL(string: string)
                                } else if let securedResource = data as? NSSecureCoding {
                                    print("收到安全编码资源: \(securedResource)")
                                    // 可能是 _EXItemProviderSandboxedResource 类型
                                }
                                
                                if let url = mediaURL {
                                    print("获取到媒体URL: \(url.absoluteString)")
                                    if url.isFileURL {
                                        print("URL是否可访问: \(url.startAccessingSecurityScopedResource())")
                                    }
                                    self?.openMainAppWithMedia(url: url, isVideo: isVideo)
                                    if url.isFileURL {
                                        url.stopAccessingSecurityScopedResource()
                                    }
                                } else {
                                    print("无法处理数据类型: \(type(of: data))")
                                }
                            }
                        }
                        break // 找到媒体类型就退出内层循环
                    }
                }
            }
        }
        
        if !hasMediaAttachment {
            print("没有找到媒体附件")
            completeRequest()
        } else {
            // 等待所有媒体处理完成后再完成请求
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
    
    private func openMainAppWithMedia(url: URL, isVideo: Bool) {
        // 先将媒体文件复制到 App Group 共享目录，获取新的URL
        if let sharedURL = handleMedia(url: url) {
            // 使用共享目录中的URL创建自定义 scheme
            let mediaType = isVideo ? "video" : "audio"
            let urlString = "mmplayer://\(mediaType)?path=\(sharedURL.absoluteString)"
            if let customURL = URL(string: urlString) {
                openURL(customURL)
            }
        } else {
            // 如果复制失败，使用原始URL
            let mediaType = isVideo ? "video" : "audio"
            let urlString = "mmplayer://\(mediaType)?path=\(url.absoluteString)"
            if let customURL = URL(string: urlString) {
                openURL(customURL)
            }
        }
    }
    
    private func handleMedia(url: URL) -> URL? {
        print("开始处理媒体文件: \(url.absoluteString)")
        
        // 使用App Group共享目录
        let fm = FileManager.default
        guard let containerURL = fm.containerURL(forSecurityApplicationGroupIdentifier: "group.mumu.player") else {
            print("无法获取App Group共享目录")
            return nil
        }
        
        print("App Group共享目录路径: \(containerURL.path)")
        
        // 创建received子目录用于存放接收的媒体文件
        let receivedDir = containerURL.appendingPathComponent("received")
        print("接收目录路径: \(receivedDir.path)")
        
        do {
            // 确保received目录存在
            if !fm.fileExists(atPath: receivedDir.path) {
                print("创建received目录")
                try fm.createDirectory(at: receivedDir, withIntermediateDirectories: true, attributes: nil)
            } else {
                print("received目录已存在")
            }
            
            // 生成不重复的文件名
            let fileName = url.lastPathComponent
            print("原始文件名: \(fileName)")
            
            var targetURL = receivedDir.appendingPathComponent(fileName)
            var counter = 1
            
            // 如果文件已存在，添加数字后缀
            while fm.fileExists(atPath: targetURL.path) {
                let nameWithoutExt = (fileName as NSString).deletingPathExtension
                let ext = (fileName as NSString).pathExtension
                let newFileName = ext.isEmpty ? "\(nameWithoutExt)_\(counter)" : "\(nameWithoutExt)_\(counter).\(ext)"
                targetURL = receivedDir.appendingPathComponent(newFileName)
                counter += 1
                print("文件已存在，尝试新文件名: \(newFileName)")
            }
            
            print("最终目标路径: \(targetURL.path)")
            
            // 复制文件
            try fm.copyItem(at: url, to: targetURL)
            print("媒体文件已成功保存到App Group共享目录: \(targetURL.path)")
            
            // 检查文件是否存在并获取文件大小
            let attributes = try fm.attributesOfItem(atPath: targetURL.path)
            if let fileSize = attributes[.size] as? Int64 {
                print("保存的文件大小: \(fileSize) bytes")
            }
            
            return targetURL
        } catch {
            print("保存到App Group共享目录失败: \(error.localizedDescription)")
            return nil
        }
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
