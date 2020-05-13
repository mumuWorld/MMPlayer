//
//  MMFileItem.swift
//  MMPlayer
//
//  Created by mumu on 2020/5/9.
//  Copyright © 2020 Mumu. All rights reserved.
//

import UIKit

class MMFileItem: NSObject {
    var name = ""
    var path = ""{
        willSet {
            if type == .directory {
                return
            }
            let path: URL = URL(fileURLWithPath: newValue)
            let extenStr = path.pathExtension
            MPPrintLog(message: extenStr)
            switch extenStr {
            case "MP3": fallthrough
            case "mp3":
                type = .audio
            case "html":
                type = .html
            default:
                break
            }
        }
    }
    var size: Int = 0
    var extensionHidden: Bool = true
    /// 修改时间戳
    var modificationDate: Date?
    var modificationDateStr: String {
        get {
            if let date = modificationDate {
                return date.dataStr(formatter: .ShortYMDHM)
            }
            return ""
        }
    }
    
    /// 可见性
    var visibility: MMPlayerFileVisibilityType = .visible
    
    /// 文件类型 默认文件
    var type: MMPlayerFileItemType = .unkonw
    
    var subItems:[MMFileItem]?
    
    
    init(param:[FileAttributeKey : Any]?) {
        super.init()
        if let dict = param {
//            MPPrintLog(message: dict)
            if let fileSize = dict[.size] as? Int {
                size = fileSize
            }
            if let fileType = dict[.type] as? FileAttributeType { //FileAttributeType
                setTypeBy(attrType: fileType)
            }
            if let modifyDate = dict[.modificationDate] as? Date {
                modificationDate = modifyDate
            }
            if let extensionHid = dict[.extensionHidden] as? Bool {
                extensionHidden = extensionHid
            }
        } else {
            return
        }
    }
    
    func setTypeBy(attrType: FileAttributeType) {
        if attrType == .typeUnknown {
            type = .unkonw
        } else if attrType == .typeDirectory {
            type = .directory
        } else if attrType == .typeRegular {
            type = .regular
        } else {
            type = .regular
        }
    }
}
