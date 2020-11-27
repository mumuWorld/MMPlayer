//
//  MMVideoPlayerTool.swift
//  MMPlayer
//
//  Created by mumu on 2020/10/10.
//  Copyright © 2020 Mumu. All rights reserved.
//

import Foundation
import AVFoundation

class MMVideoPlayerTool {
    var videoPlayer: AVPlayer?
    var p_item:MMVideoItem?
    
    /// 图片帧生成
    var imageGenerator: AVAssetImageGenerator?
    
    init(item: MMVideoItem) {
        p_item = item
        
        guard let asset = item.asset else { return }
        
        let videoItem = AVPlayerItem(asset: asset)
        videoPlayer = AVPlayer(playerItem: videoItem)
        imageGenerator = AVAssetImageGenerator(asset: asset)
    }
}

// MARK: - 播放控制
extension MMVideoPlayerTool {
    func play() -> Void {
        videoPlayer?.play()
    }
    
    func stop() -> Void {
//        videoPlayer?.stop()
    }
    
    func pause() -> Void {
        videoPlayer?.pause()
    }
}
