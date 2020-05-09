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
        MPPrintLog(message: "path->" + path)
        let manager = FileManager.default
        var items:[String] = Array()
        do {
            items = try manager.contentsOfDirectory(atPath: path)
        } catch {
            MPErrorLog(message: error)
        }
        return items
    }
    
    class func getPathProperty(path: String) -> MMFileItem? {
        let manager = FileManager.default
        MPPrintLog(message: "path->" + path)
        do {
            let dict = try manager.attributesOfItem(atPath: path)
            let item = MMFileItem.init(param: dict)
            item.path = path
            return item
        } catch {
            MPErrorLog(message: error)
        }
        return nil
    }
}
