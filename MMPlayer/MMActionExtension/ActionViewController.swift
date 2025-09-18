//
//  ActionViewController.swift
//  MMActionExtension
//
//  Created by 杨杰 on 2025/9/17.
//  Copyright © 2025 Mumu. All rights reserved.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers
import Foundation

class ActionViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 设置简单的UI
        setupUI()
        
        // 处理接收到的文件
        handleExtensionContext()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        
        let label = UILabel()
        label.text = "正在处理视频文件..."
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.label
        label.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func handleExtensionContext() {
        guard let extensionContext = extensionContext,
              let inputItems = extensionContext.inputItems as? [NSExtensionItem] else {
            completeRequest()
            return
        }
        
        for item in inputItems {
            guard let attachments = item.attachments else { continue }
            
            for attachment in attachments {
                // 检查是否为视频文件
                if attachment.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                    print("发现视频文件，开始处理")
                    
                    // 使用 NSItemProviderLoadKeyIsInPlace 选项来获取 Security-Scoped Resource
                    let options: [AnyHashable: Any] = [
                        "NSItemProviderLoadKeyIsInPlace": true
                    ]
                    
                    attachment.loadItem(forTypeIdentifier: UTType.movie.identifier, options: options) { [weak self] (data, error) in
                        
                        if let error = error {
                            print("加载视频失败: \(error)")
                            DispatchQueue.main.async {
                                self?.completeRequest()
                            }
                            return
                        }
                        
                        if let videoURL = data as? URL {
                            print("获取到视频URL: \(videoURL.absoluteString)")
                            print("URL 是否为安全范围资源: \(videoURL.hasDirectoryPath)")
                            print("URL 路径: \(videoURL.path)")
                            
                            // 尝试直接使用 Security-Scoped Resource
                            if self?.tryProcessVideoWithSecurityScope(url: videoURL) == true {
                                return
                            }
                            
                            // 如果直接处理失败，尝试通过主应用打开
                            self?.openVideoInMainApp(url: videoURL)
                        } else {
                            print("无法获取视频URL")
                            DispatchQueue.main.async {
                                self?.completeRequest()
                            }
                        }
                    }
                    return
                }
            }
        }
        
        // 如果没有找到视频文件，直接完成
        completeRequest()
    }
    
    private func tryProcessVideoWithSecurityScope(url: URL) -> Bool {
        print("尝试使用 Security-Scoped Resource 处理视频")
        
        // 开始访问安全范围内的资源
        guard url.startAccessingSecurityScopedResource() else {
            print("无法开始访问 Security-Scoped Resource")
            return false
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        // 检查文件是否可访问
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: url.path) {
            print("Security-Scoped Resource 访问成功")
            
            // 获取文件信息
            do {
                let attributes = try fileManager.attributesOfItem(atPath: url.path)
                let fileSize = attributes[.size] as? Int64 ?? 0
                print("文件大小: \(fileSize) bytes")
                
                // 直接在 Extension 中复制文件到缓存目录
                if let copiedFilePath = copyVideoToCache(from: url) {
                    print("文件复制成功: \(copiedFilePath)")
                    
                    // 通过自定义 URL scheme 打开主应用，传递复制后的文件路径
                    let copiedURL = URL(fileURLWithPath: copiedFilePath)
                    openVideoInMainApp(url: copiedURL)
                    return true
                } else {
                    print("文件复制失败")
                }
                
            } catch {
                print("获取文件信息失败: \(error)")
            }
        } else {
            print("Security-Scoped Resource 文件不可访问")
        }
        
        return false
    }
    
    private func copyVideoToCache(from sourceURL: URL) -> String? {
        let fileManager = FileManager.default
        
        // 获取应用的缓存目录
        guard let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            print("无法获取缓存目录")
            return nil
        }
        
        let receivedDir = cacheDir.appendingPathComponent("Received")
        
        // 创建 Received 目录
        do {
            try fileManager.createDirectory(at: receivedDir, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("创建目录失败: \(error)")
            return nil
        }
        
        let fileName = sourceURL.lastPathComponent
        let destinationURL = receivedDir.appendingPathComponent(fileName)
        
        // 如果目标文件已存在，先删除
        if fileManager.fileExists(atPath: destinationURL.path) {
            do {
                try fileManager.removeItem(at: destinationURL)
                print("删除现有文件: \(destinationURL.path)")
            } catch {
                print("删除现有文件失败: \(error)")
            }
        }
        
        // 复制文件
        do {
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            print("文件复制成功: \(sourceURL.path) -> \(destinationURL.path)")
            return destinationURL.path
        } catch {
            print("文件复制失败: \(error)")
            return nil
        }
    }
    
    private func openVideoInMainApp(url: URL) {
        print("通过自定义 URL scheme 打开主应用")
        
        // 创建自定义 URL scheme
        let encodedPath = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? url.absoluteString
        let urlString = "mmplayer://video?path=\(encodedPath)"
        
        if let customURL = URL(string: urlString) {
            print("准备打开 URL: \(customURL.absoluteString)")
            
            // 在 Action Extension 中打开主应用
            var responder: UIResponder? = self
            while responder != nil {
                if let application = responder as? UIApplication {
                    application.open(customURL, options: [:]) { [weak self] success in
                        print("打开主应用结果: \(success)")
                        DispatchQueue.main.async {
                            self?.completeRequest()
                        }
                    }
                    return
                }
                responder = responder?.next
            }
            
            // 如果通过 responder chain 无法找到 UIApplication，尝试直接调用
            DispatchQueue.main.async { [weak self] in
                if #available(iOS 10.0, *) {
                    // 这里不能直接使用 UIApplication.shared，需要通过扩展上下文
                    self?.completeRequest()
                } else {
                    self?.completeRequest()
                }
            }
        } else {
            print("无法创建自定义 URL")
            DispatchQueue.main.async { [weak self] in
                self?.completeRequest()
            }
        }
    }
    
    private func completeRequest() {
        print("完成 Action Extension 请求")
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
