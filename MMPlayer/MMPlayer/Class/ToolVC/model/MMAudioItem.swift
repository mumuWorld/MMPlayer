//
//  MMAudioItem.swift
//  MMPlayer
//
//  Created by mumu on 2020/5/12.
//  Copyright © 2020 Mumu. All rights reserved.
//

import UIKit
import AVFoundation

class MMAudioItem: NSObject {
    var name = ""
    var path = ""
    var size: Int = 0
    //精准时间
    var time: Float = 0
    //向上对齐时间
    var fitTime: Int = 0
    
    init(fileItem: MMFileItem) {
        name = fileItem.name
        path = fileItem.path
        size = fileItem.size
        let fileUrl = URL(fileURLWithPath: fileItem.path)
        let asset = AVURLAsset(url: fileUrl, options: [AVURLAssetPreferPreciseDurationAndTimingKey : true])
        time = Float(CMTimeGetSeconds(asset.duration))
        fitTime = Int(ceil(time))
    }
}
