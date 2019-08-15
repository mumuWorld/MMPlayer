//
//  MQConstant.swift
//  MMQRCode
//
//  Created by yangjie on 2019/7/25.
//  Copyright © 2019 yangjie. All rights reserved.
//

import UIKit

let MQScreenWidth = UIScreen.main.bounds.size.width;

let MQScreenHeight = UIScreen.main.bounds.size.height;

let MQAdaptScale = MQScreenWidth / 375.0

let MQMainColor = UIColor.mm_colorFromHex(color_vaule: 0x2882fc)

let MQMainTitleColor = UIColor.mm_colorFromHex(color_vaule: 0x444444)

let MQNavigationBarHeight: CGFloat = UIDevice.MQIsIphoneXAll ? 88.0 : 64.0

let MQHomeIndicatorHeight: CGFloat = UIDevice.MQIsIphoneXAll ? 34.0 : 0

let MQStatusBarHeight = UIDevice.MQIsIphoneXAll ? 44.0 : 20.0

let MQTabBarHeight = UIDevice.MQIsIphoneXAll ? 83.0 : 49.0

extension UIDevice {
   class var MQIsIphoneXAll:Bool {
        let maxH = max(MQScreenWidth, MQScreenHeight)
        if maxH == 812 || maxH == 896 {
            return true
        }
        return false
    }
}


func MPPrintLog<T>(message : T, file : String = #file, funcName : String = #function, lineNum : Int = #line) {
    #if DEBUG
    // 1.获取文件名,包含后缀名
    let name = (file as NSString).lastPathComponent
    // 1.1 切割文件名和后缀名
    let fileArray = name.components(separatedBy: ".")
    // 1.2 获取文件名
    let fileName = fileArray[0]
    // 2.打印内容
    print("⭕️ [\(fileName) \(funcName)](\(lineNum)): \(message)")
    #endif
}

func MPErrorLog<T>(message : T, file : String = #file, funcName : String = #function, lineNum : Int = #line) {
    #if DEBUG
    // 1.获取文件名,包含后缀名
    let name = (file as NSString).lastPathComponent
    // 1.1 切割文件名和后缀名
    let fileArray = name.components(separatedBy: ".")
    // 1.2 获取文件名
    let fileName = fileArray[0]
    // 2.打印内容
    print("❌ [\(fileName) \(funcName)](\(lineNum)): \(message)")
    #endif
}

