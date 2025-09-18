//
//  MMVideoPlayerTool.swift
//  MMPlayer
//
//  Created by mumu on 2020/10/10.
//  Copyright © 2020 Mumu. All rights reserved.
//

import Foundation
import AVFoundation

// MARK: - 播放状态枚举
enum MMVideoPlayerState {
    case unknown
    case preparing
    case readyToPlay
    case playing
    case paused
    case stopped
    case failed
    case ended
}

// MARK: - 播放器委托协议
protocol MMVideoPlayerToolDelegate: AnyObject {
    func playerTool(_ tool: MMVideoPlayerTool, didChangeState state: MMVideoPlayerState)
    func playerTool(_ tool: MMVideoPlayerTool, didFailWithError error: Error)
    func playerTool(_ tool: MMVideoPlayerTool, didUpdateLoadedTime loadedTime: TimeInterval)
    func playerToolDidReachEnd(_ tool: MMVideoPlayerTool)
}

class MMVideoPlayerTool: NSObject {
    weak var delegate: MMVideoPlayerToolDelegate?
    var videoPlayer: AVPlayer?
    var p_item: MMVideoItem?
    
    /// 图片帧生成
    var imageGenerator: AVAssetImageGenerator?
    
    /// 当前播放速率
    private var _playbackRate: Float = 1.0
    
    /// 播放状态
    private(set) var state: MMVideoPlayerState = .unknown {
        didSet {
            if oldValue != state {
                delegate?.playerTool(self, didChangeState: state)
            }
        }
    }
    
    init(item: MMVideoItem) {
        super.init()
        
        p_item = item
        
        guard let asset = item.asset else { 
            state = .failed
            return 
        }
        
        state = .preparing
        let videoItem = AVPlayerItem(asset: asset)
        videoPlayer = AVPlayer(playerItem: videoItem)
        imageGenerator = AVAssetImageGenerator(asset: asset)
        
        setupObservers()
    }
    
    deinit {
        removeObservers()
    }
}

// MARK: - 播放控制
extension MMVideoPlayerTool {
    var playbackRate: Float {
        get {
            return _playbackRate
        }
        set {
            _playbackRate = newValue
            if state == .playing {
                videoPlayer?.rate = newValue
            }
        }
    }
    
    /// 支持的播放速率
    static let supportedPlaybackRates: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
    
    func play() {
        guard let player = videoPlayer else { return }
        
        if state == .ended {
            // 重新开始播放
            player.seek(to: .zero)
        }
        
        // 设置播放速率然后播放
        player.rate = _playbackRate
        if state != .playing && state != .failed {
            state = .playing
        }
    }
    
    func pause() {
        videoPlayer?.pause()
        if state == .playing {
            state = .paused
        }
    }
    
    func stop() {
        videoPlayer?.pause()
        videoPlayer?.seek(to: .zero)
        state = .stopped
    }
    
    func seek(to time: CMTime, completion: ((Bool) -> Void)? = nil) {
        videoPlayer?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { success in
            print("test->seek: \(success)")
            completion?(success)
        }
    }
    
    /// 设置播放速率
    func setPlaybackRate(_ rate: Float) {
        guard Self.supportedPlaybackRates.contains(rate) else { return }
        
        _playbackRate = rate
        if state == .playing {
            videoPlayer?.rate = rate
        }
    }
    
    /// 获取下一个播放速率
    func getNextPlaybackRate() -> Float {
        let currentRate = playbackRate
        if let currentIndex = Self.supportedPlaybackRates.firstIndex(of: currentRate) {
            let nextIndex = (currentIndex + 1) % Self.supportedPlaybackRates.count
            return Self.supportedPlaybackRates[nextIndex]
        }
        return 1.0
    }
}

// MARK: - 观察者管理
extension MMVideoPlayerTool {
    // 使用唯一的context标识符
    private static var statusContext = 0
    private static var loadedTimeRangesContext = 0
    
    private func setupObservers() {
        guard let playerItem = videoPlayer?.currentItem else { return }
        
        // 播放状态观察
        playerItem.addObserver(
            self,
            forKeyPath: #keyPath(AVPlayerItem.status),
            options: [.new, .initial],
            context: &Self.statusContext
        )
        
        // 缓冲状态观察
        playerItem.addObserver(
            self,
            forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges),
            options: .new,
            context: &Self.loadedTimeRangesContext
        )
        
        // 播放结束通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidReachEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
        
        // 播放失败通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemFailedToPlayToEndTime),
            name: .AVPlayerItemFailedToPlayToEndTime,
            object: playerItem
        )
    }
    
    private func removeObservers() {
        if let playerItem = videoPlayer?.currentItem {
            // 使用对应的context移除观察者
            playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: &Self.statusContext)
            playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges), context: &Self.loadedTimeRangesContext)
        }
        
        NotificationCenter.default.removeObserver(self)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        // 使用context来识别观察者
        if context == &Self.statusContext {
            handlePlayerItemStatusChange()
        } else if context == &Self.loadedTimeRangesContext {
            handleLoadedTimeRangesChange()
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    private func handlePlayerItemStatusChange() {
        guard let playerItem = videoPlayer?.currentItem else { return }
        
        switch playerItem.status {
        case .readyToPlay:
            if state == .preparing {
                state = .readyToPlay
            }
        case .failed:
            state = .failed
            if let error = playerItem.error {
                delegate?.playerTool(self, didFailWithError: error)
            }
        case .unknown:
            break
        @unknown default:
            break
        }
    }
    
    private func handleLoadedTimeRangesChange() {
        guard let playerItem = videoPlayer?.currentItem else { return }
        
        let loadedTimeRanges = playerItem.loadedTimeRanges
        if let timeRange = loadedTimeRanges.first?.timeRangeValue {
            let loadedTime = CMTimeGetSeconds(CMTimeAdd(timeRange.start, timeRange.duration))
            delegate?.playerTool(self, didUpdateLoadedTime: loadedTime)
        }
    }
    
    @objc private func playerItemDidReachEnd() {
        state = .ended
        delegate?.playerToolDidReachEnd(self)
    }
    
    @objc private func playerItemFailedToPlayToEndTime(notification: Notification) {
        state = .failed
        if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error {
            delegate?.playerTool(self, didFailWithError: error)
        }
    }
}
