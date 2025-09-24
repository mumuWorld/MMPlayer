//
//  MMVideoViewController.swift
//  MMPlayer
//
//  Created by mumu on 2020/8/27.
//  Copyright © 2020 Mumu. All rights reserved.
//

import UIKit
import AVFoundation

class MMVideoViewController: MMBaseViewController {
    
    var videoItem: MMVideoItem?

    
    lazy var touchView:UIView = {
        let tV = UIView()
        return tV
    }()
    
    lazy var videoPlayView: MMVideoPlayView = {
        let item = MMVideoPlayView()
        return item
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(videoPlayView)
        setupNavigationItems()
        setupNavigationTitle()
        setupNavigationBarVisibility()
        
        videoPlayView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        if let item = videoItem {
            // 确保布局在播放前已经正确设置
            DispatchQueue.main.async { [weak self] in
                self?.videoPlayView.updateLayoutForSettingsChange()
                self?.videoPlayView.playVideo(with: item)
            }
        }
        
    }
    
    private func setupNavigationItems() {
        // 添加设置按钮到导航栏右侧
        let settingsButton = UIBarButtonItem(
            image: UIImage(systemName: "gear"),
            style: .plain,
            target: self,
            action: #selector(showSettings)
        )
        settingsButton.tintColor = UIColor.mm_colorFromHexString(color_vaule: "1296db")
        navigationItem.rightBarButtonItem = settingsButton
    }
    
    private func setupNavigationTitle() {
        // 设置导航栏标题为文件名
        if let item = videoItem, !item.name.isEmpty {
            title = item.name
        } else {
            title = "视频播放"
        }
    }
    
    private func setupNavigationBarVisibility() {
        // 根据设置决定导航栏初始状态
        updateNavigationBarVisibility()
        
        // 监听播放状态变化来控制导航栏显示
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleControlsVisibilityChanged),
            name: NSNotification.Name("MMVideoControlsVisibilityChanged"),
            object: nil
        )
        
        // 监听后台播放设置变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBackgroundPlaybackChanged),
            name: NSNotification.Name("MMVideoBackgroundPlaybackChanged"),
            object: nil
        )
        
        // 监听应用进入后台和前台
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    private func updateNavigationBarVisibility() {
        if MMVideoPlayerSettings.shared.controlsAlwaysVisible {
            // 常驻模式：始终显示导航栏
            navigationController?.setNavigationBarHidden(false, animated: true)
        } else {
            // 非常驻模式：导航栏跟随控制条状态
            // 这里需要从通知中获取控制条的当前状态
            // 暂时隐藏导航栏，让用户交互时显示
            navigationController?.setNavigationBarHidden(true, animated: true)
        }
    }
    
    @objc private func handleControlsVisibilityChanged(_ notification: Notification) {
        if MMVideoPlayerSettings.shared.controlsAlwaysVisible {
            // 常驻模式：始终显示导航栏
            navigationController?.setNavigationBarHidden(false, animated: true)
        } else {
            // 非常驻模式：导航栏跟随控制条状态
            if let userInfo = notification.userInfo,
               let isVisible = userInfo["isVisible"] as? Bool {
                navigationController?.setNavigationBarHidden(!isVisible, animated: true)
            }
        }
        
        // 更新视频播放区域布局
        videoPlayView.updateLayoutForSettingsChange()
    }
    
    @objc private func showSettings() {
        let settingsVC = MMVideoPlayerSettingsViewController()
        navigationController?.pushViewController(settingsVC, animated: true)
    }
    
    @objc private func handleBackgroundPlaybackChanged(_ notification: Notification) {
        // 后台播放设置已更改，无需立即处理，在进入后台时会检查设置
    }
    
    @objc private func appDidEnterBackground() {
        if !MMVideoPlayerSettings.shared.backgroundPlaybackEnabled {
            // 如果后台播放未启用，暂停播放
            videoPlayView.pausePlayback()
        }
    }
    
    @objc private func appWillEnterForeground() {
        // 应用回到前台时，恢复播放（如果之前在播放）
        videoPlayView.resumePlaybackIfNeeded()
    }
    
    override func naviBarPopItemStyle() -> PopItemStyle {
        return .PopItemWhite
    }
    
    deinit {
        // 确保在控制器销毁时停止播放
        videoPlayView.stopPlayback()
        
        // 移除通知监听
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - 键盘监听
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // 页面即将消失时暂停播放
        videoPlayView.pausePlayback()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        resignFirstResponder()
        
        // 如果是被导航栈pop掉，完全停止播放
        if navigationController?.viewControllers.contains(self) == false {
            videoPlayView.stopPlayback()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 确保视频播放页面的右滑返回手势正常
//        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
//        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
        
        // 页面重新出现时恢复播放（如果之前在播放）
        videoPlayView.resumePlaybackIfNeeded()
    }
    
    // 监听键盘按下事件
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard let key = presses.first?.key else {
            super.pressesBegan(presses, with: event)
            return
        }
        
        switch key.keyCode {
        case .keyboardSpacebar:
            // 处理空格键按下 - 切换播放/暂停状态
            togglePlayPause()
        case .keyboardLeftArrow:
            // 处理左箭头键 - 快退
            handleSeekBackward()
        case .keyboardRightArrow:
            // 处理右箭头键 - 快进
            handleSeekForward()
        default:
            super.pressesBegan(presses, with: event)
        }
    }
    
    private func togglePlayPause() {
        videoPlayView.handleSpaceKeyToggle()
    }
    
    private func handleSeekForward() {
        let seekTime = MMVideoPlayerSettings.shared.seekTime
        videoPlayView.handleSeekForward(seconds: seekTime)
    }
    
    private func handleSeekBackward() {
        let seekTime = MMVideoPlayerSettings.shared.seekTime
        videoPlayView.handleSeekBackward(seconds: seekTime)
    }
    
}

