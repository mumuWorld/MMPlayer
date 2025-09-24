//
//  MMVideoPlayerSettings.swift
//  MMPlayer
//
//  Created by yangjie on 2025/9/17.
//  Copyright © 2025 Mumu. All rights reserved.
//

import Foundation

class MMVideoPlayerSettings {
    static let shared = MMVideoPlayerSettings()
    
    private let userDefaults = UserDefaults.standard
    private let seekTimeKey = "MMVideoPlayerSeekTime"
    private let controlsAlwaysVisibleKey = "MMVideoPlayerControlsAlwaysVisible"
    private let backgroundPlaybackEnabledKey = "MMVideoPlayerBackgroundPlaybackEnabled"
    
    private init() {}
    
    /// 快进快退时间（秒），默认5秒
    var seekTime: Double {
        get {
            let time = userDefaults.double(forKey: seekTimeKey)
            return time > 0 ? time : 5.0 // 默认5秒
        }
        set {
            userDefaults.set(newValue, forKey: seekTimeKey)
        }
    }
    
    /// 控制条常驻显示，默认false
    var controlsAlwaysVisible: Bool {
        get {
            return userDefaults.bool(forKey: controlsAlwaysVisibleKey)
        }
        set {
            userDefaults.set(newValue, forKey: controlsAlwaysVisibleKey)
        }
    }
    
    /// 后台播放开关，默认false
    var backgroundPlaybackEnabled: Bool {
        get {
            return userDefaults.bool(forKey: backgroundPlaybackEnabledKey)
        }
        set {
            userDefaults.set(newValue, forKey: backgroundPlaybackEnabledKey)
        }
    }
    
    /// 可选的快进快退时间选项
    static let seekTimeOptions: [Double] = [5.0, 10.0, 15.0, 30.0, 60.0]
    
    /// 格式化时间显示
    func formatSeekTime(_ seconds: Double) -> String {
        if seconds < 60 {
            return "\(Int(seconds))秒"
        } else {
            return "\(Int(seconds/60))分钟"
        }
    }
}