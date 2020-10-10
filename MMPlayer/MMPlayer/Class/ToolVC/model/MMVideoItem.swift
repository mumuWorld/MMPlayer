//
//  MMVideoItem.swift
//  MMPlayer
//
//  Created by mumu on 2020/10/10.
//  Copyright © 2020 Mumu. All rights reserved.
//

import Foundation
import AVFoundation

class MMVideoItem: NSObject {
    var name = ""
    var path = ""
    var size: Int = 0
    //精准时间
    var time: Float = 0
    //向上对齐时间
    var fitTime: Int = 0
    
    var asset:AVAsset?
    
    init(fileItem: MMFileItem) {
        name = fileItem.name
        path = fileItem.path
        size = fileItem.size
        let fileUrl = URL(fileURLWithPath: fileItem.path)
        asset = AVURLAsset(url: fileUrl, options: [AVURLAssetPreferPreciseDurationAndTimingKey : true])
        time = Float(CMTimeGetSeconds(asset!.duration))
        fitTime = Int(ceil(time))
    }
}
