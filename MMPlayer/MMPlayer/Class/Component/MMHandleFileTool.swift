//
//  MMHandleFileTool.swift
//  MMPlayer
//
//  Created by mumu on 2020/5/13.
//  Copyright © 2020 Mumu. All rights reserved.
//

import UIKit

class MMHandleFileTool {
    
    /// 将文件拷贝到cache文件夹
    /// - Parameter path: 
    class func handleReceiveFile(path: String) -> Void {
        MMFileManager.copyFileFrom(path: path, toPath: MMFileManager.receivedPath ?? "")
    }
}
