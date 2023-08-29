//
//  MPFileManager.swift
//  MMPlayer
//
//  Created by yangjie on 2019/8/15.
//  Copyright © 2019 Mumu. All rights reserved.
//

import UIKit
enum DirectorType {
    case root
    case docutment
}

class MMFileManager {
    
    static var cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first
    
    static var receivedPath = MMFileManager.cachePath?.appendPathComponent(string: "Received")
    
    class func getSandboxPath(fileType: DirectorType = .root) -> String {
        var type:FileManager.SearchPathDirectory = .applicationDirectory
        if fileType == .root {
            return NSHomeDirectory();
        } else if fileType == .docutment {
            type = .documentDirectory
        }
        let path = NSSearchPathForDirectoriesInDomains(type, .userDomainMask, true).first ?? ""
        return path
    }
    
    class func getDirectorAllItems(path: String) -> [String]? {
        MMPrintLog(message: "path->" + path)
        let manager = FileManager.default
        var items:[String] = Array()
        do {
            items = try manager.contentsOfDirectory(atPath: path)
        } catch {
            MMErrorLog(message: error)
        }
        return items
    }
    
    class func getPathProperty(path: String) -> MMFileItem? {
        if !judgePathIsRight(path: path) {
            return nil
        }
        let manager = FileManager.default
        MMPrintLog(message: "path->" + path)
        do {
            let dict = try manager.attributesOfItem(atPath: path)
            let item = MMFileItem.init(param: dict)
            item.path = path
            return item
        } catch {
            MMErrorLog(message: error)
        }
        return nil
    }
    
    
    /// 创建文件夹
    /// - Parameter path: 路径
    class func createDirectory(path: String) {
        if !judgePathIsRight(path: path) {
            return
        }
        let manager = FileManager.default
        MMPrintLog(message: "path->" + path)
        var pointer = ObjCBool(false)
        let exist = manager.fileExists(atPath: path, isDirectory: &pointer)
        if exist && pointer.boolValue == true {
            MMPrintLog(message: "文件已经存在")
            return
        }
        do {
            try manager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        } catch {
            MMErrorLog(message: error)
        }
    }
    
    
    /// 拷贝文件到路径
    class func copyFileFrom(path: String, toPath: String) {
        if !judgePathIsRight(path: path) || !judgePathIsRight(path: toPath) {
            return
        }
        let fitPath = handleFitPath(path: path)
        let manager = FileManager.default
        do {
            try manager.copyItem(atPath: fitPath, toPath: toPath)
        } catch {
            MMErrorLog(message: error)
        }
    }
    
    class func judgePathIsRight(path: String) -> Bool {
        if path.count < 1 {
            MMPrintLog(message: "路径不合法")
            return false
        }
        return true
    }
    
    class func handleFitPath(path: String) -> String {
        var newPath = path
        
        if path.hasPrefix("file:///private") {
            let  range = path.index(path.startIndex, offsetBy: 15)..<path.endIndex
            newPath = String(newPath[range])
        }
        return newPath
    }
}
