//
//  MMHandleFileTool.swift
//  MMPlayer
//
//  Created by mumu on 2020/5/13.
//  Copyright © 2020 Mumu. All rights reserved.
//

import UIKit

class MMHandleFileTool {
    
    /// 统一的文件打开处理入口（从 AppDelegate 移过来）
    /// - Parameter url: 文件 URL
    class func handleOpenFile(url: URL) {
        if ProcessInfo.processInfo.isMacCatalystApp {
            handleMacOpenFile(url: url)
        } else {
            handleReceiveFile(path: url.absoluteString)
        }
    }
    
    /// 将文件拷贝到cache文件夹
    /// - Parameter path: 
    class func handleReceiveFile(path: String) -> Void {
        // 处理文件路径，并尝试使用 URL 方式处理
        let originalPath = MMFileManager.handleFitPath(path: path)
        let fileURL = URL(string: path) ?? URL(fileURLWithPath: originalPath)
        
        // 先尝试获取文件信息来判断文件类型
        let isVideoFile = isVideoFileByExtension(path: originalPath)
        
        if isVideoFile {
            // 对于视频文件，尝试多种访问方式
            if tryAccessSecurityScopedResource(url: fileURL) {
                return
            }
        }
        
        // 生成目标文件路径
        let fileName = fileURL.lastPathComponent
        guard let receivedPath = MMFileManager.receivedPath else { return }
        
        // 确保接收目录存在
        MMFileManager.createDirectory(path: receivedPath)
        
        let destinationPath = receivedPath.appendPathComponent(string: fileName)
        
        // 尝试使用 URL 进行复制
        if tryCopyFileUsingURL(from: fileURL, to: destinationPath) {
            MMPrintLog(message: "URL复制成功: \(destinationPath)")
            if isVideoFile {
                DispatchQueue.main.async {
                    handleVideoFile(at: destinationPath)
                }
            }
            return
        }
        
        // 备用方案：传统路径复制
        MMFileManager.copyFileFrom(path: path, toPath: destinationPath)
        
        // 验证文件是否复制成功
        if FileManager.default.fileExists(atPath: destinationPath) {
            MMPrintLog(message: "传统复制成功: \(destinationPath)")
            
            if isVideoFile {
                DispatchQueue.main.async {
                    handleVideoFile(at: destinationPath)
                }
            }
        } else {
            MMPrintLog(message: "所有复制方法都失败")
        }
    }
    
    /// 通过文件扩展名判断是否为视频文件
    /// - Parameter path: 文件路径
    /// - Returns: 是否为视频文件
    private class func isVideoFileByExtension(path: String) -> Bool {
        let url = URL(fileURLWithPath: path)
        let fileExtension = url.pathExtension.lowercased()
        
        let videoExtensions = ["mp4", "mov", "avi", "mkv", "wmv", "flv", "webm", "m4v", "3gp", "3g2", "asf", "rm", "rmvb", "ts", "mts", "vob"]
        
        return videoExtensions.contains(fileExtension)
    }
    
    /// Mac 文件打开处理（从 AppDelegate 移过来）
    /// - Parameter url: 文件 URL
    class func handleMacOpenFile(url: URL) {
        guard let item = MMFileManager.getPathProperty(path: url.path) else { return }
        openVideoFile(with: item)
    }
    
    /// 统一的视频文件处理方法
    /// - Parameter filePath: 视频文件路径
    private class func handleVideoFile(at filePath: String) {
        // 首先检查文件是否存在
        if !FileManager.default.fileExists(atPath: filePath) {
            MMErrorLog(message: "文件不存在: \(filePath)")
            return
        }
        
        guard let item = MMFileManager.getPathProperty(path: filePath) else {
            MMErrorLog(message: "无法获取文件信息: \(filePath)")
            return
        }
        
        MMPrintLog(message: "准备打开视频文件: \(item.name)")
        openVideoFile(with: item)
    }
    
    /// 尝试访问 Security-Scoped Resource
    /// - Parameter url: 文件 URL
    /// - Returns: 是否成功处理
    private class func tryAccessSecurityScopedResource(url: URL) -> Bool {
        MMPrintLog(message: "尝试访问 Security-Scoped Resource: \(url.absoluteString)")
        
        // 开始访问安全范围内的资源
        guard url.startAccessingSecurityScopedResource() else {
            MMPrintLog(message: "无法访问 Security-Scoped Resource")
            return false
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        // 检查文件是否可访问
        if FileManager.default.fileExists(atPath: url.path) {
            MMPrintLog(message: "Security-Scoped Resource 访问成功，直接播放")
            
            // 创建一个临时的 MMFileItem
            if let fileItem = createFileItemFromURL(url) {
                DispatchQueue.main.async {
                    openVideoFile(with: fileItem)
                }
                return true
            }
        }
        
        return false
    }
    
    /// 尝试使用 URL 复制文件
    /// - Parameters:
    ///   - fromURL: 源 URL
    ///   - toPath: 目标路径
    /// - Returns: 是否复制成功
    private class func tryCopyFileUsingURL(from fromURL: URL, to toPath: String) -> Bool {
        MMPrintLog(message: "尝试 URL 复制: \(fromURL.absoluteString) -> \(toPath)")
        
        let toURL = URL(fileURLWithPath: toPath)
        
        // 尝试使用 Security-Scoped Resource
        if fromURL.startAccessingSecurityScopedResource() {
            defer {
                fromURL.stopAccessingSecurityScopedResource()
            }
            
            do {
                // 删除已存在的目标文件
                if FileManager.default.fileExists(atPath: toPath) {
                    try FileManager.default.removeItem(at: toURL)
                }
                
                // 复制文件
                try FileManager.default.copyItem(at: fromURL, to: toURL)
                MMPrintLog(message: "Security-Scoped URL 复制成功")
                return true
            } catch {
                MMErrorLog(message: "Security-Scoped URL 复制失败: \(error)")
            }
        }
        
        // 尝试普通 URL 复制
        do {
            if FileManager.default.fileExists(atPath: toPath) {
                try FileManager.default.removeItem(at: toURL)
            }
            
            try FileManager.default.copyItem(at: fromURL, to: toURL)
            MMPrintLog(message: "普通 URL 复制成功")
            return true
        } catch {
            MMErrorLog(message: "普通 URL 复制失败: \(error)")
        }
        
        return false
    }
    
    /// 从 URL 创建 MMFileItem
    /// - Parameter url: 文件 URL
    /// - Returns: 文件项
    private class func createFileItemFromURL(_ url: URL) -> MMFileItem? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let item = MMFileItem(param: attributes)
            item.path = url.path
            return item
        } catch {
            MMErrorLog(message: "无法创建文件项: \(error)")
            return nil
        }
    }
    
    /// 打开视频文件的核心方法
    /// - Parameter item: 文件信息
    private class func openVideoFile(with item: MMFileItem) {
        switch item.type {
        case .video:
            let vc = MMVideoViewController()
            let video = MMVideoItem(fileItem: item)
            vc.videoItem = video
            UIViewController.currentViewController?.pushOrPresent(vc)
        default:
            MMPrintLog(message: "暂不支持的文件类型")
        }
    }
}
