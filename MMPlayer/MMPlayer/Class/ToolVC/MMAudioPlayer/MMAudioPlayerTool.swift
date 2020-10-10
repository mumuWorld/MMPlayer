//
//  MMAudioPlayerTool.swift
//  MMPlayer
//
//  Created by mumu on 2020/5/13.
//  Copyright © 2020 Mumu. All rights reserved.
//

import UIKit
import AVFoundation

class MMAudioPlayerTool: NSObject {
    public static let shared = MMAudioPlayerTool()
    
    private override init() {
    }
    
    var audioItem: MMAudioItem? {
        willSet {
            guard let item = newValue, item.path.count > 0 else {
                MPErrorLog(message: "文件资源有误，初始化失败")
                return
            }
            let url = URL(fileURLWithPath: item.path)
            do {
                player = try AVAudioPlayer(contentsOf: url)
                player.numberOfLoops = 0 //不循环
                player.prepareToPlay()
            } catch {
                MPErrorLog(message: error)
            }
        }
    }
    
    lazy var player = AVAudioPlayer()
    
    var isPlaying: Bool { get { player.isPlaying } }
    
}
// MARK: - 播放控制
extension MMAudioPlayerTool {
    func play() -> Void {
        player.play()
    }
    
    func stop() -> Void {
        player.stop()
    }
    
    func pause() -> Void {
        player.pause()
    }
}

extension MMAudioPlayerTool {
    func handleEnterBackground() -> Void {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setActive(true, options: AVAudioSession.SetActiveOptions.notifyOthersOnDeactivation)
            try session.setCategory(.playback, options: .mixWithOthers)
        } catch {
            MPErrorLog(message: error)
        }
    }
}
