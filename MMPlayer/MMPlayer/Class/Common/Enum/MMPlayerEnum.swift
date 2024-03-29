//
//  MMPlayerEnum.swift
//  MMPlayer
//
//  Created by mumu on 2019/9/7.
//  Copyright © 2019 Mumu. All rights reserved.
//

import Foundation

enum MMPlayerMediaType {
    case music
    case video
}


enum MMPlayerFileItemType {
    case unkonw
    case regular    //常规文件
    case directory  //目录
    case audio      //音频
    case html       //网页
    case video      //视频
}

enum MMPlayerFileVisibilityType {
    case visible
    case invisible
}
