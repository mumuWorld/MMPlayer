//
//  MMVideoPlayView.swift
//  MMPlayer
//
//  Created by 杨杰 on 2025/8/29.
//  Copyright © 2025 Mumu. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

class MMVideoPlayView: UIView {
    
    private var playerLayer: AVPlayerLayer?
    
    var playerTool: MMVideoPlayerTool? {
        didSet {
            oldValue?.delegate = nil
            playerTool?.delegate = self
        }
    }

    var videoPlayer: AVPlayer? {
        return playerTool?.videoPlayer
    }
    
    /// 加载指示器
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    /// 错误提示标签
    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 16)
        label.isHidden = true
        return label
    }()
    
    /// 控制栏自动隐藏定时器
    private var controlHideTimer: Timer?
    
    /// 控制栏显示状态
    private var isControlsVisible = true {
        didSet {
            if oldValue != isControlsVisible {
                updateControlsVisibility()
            }
        }
    }
    
    /// 手势控制相关
    private var panStartPoint: CGPoint = .zero
    private var panStartVolume: Float = 0.0
    private var panStartBrightness: CGFloat = 0.0
    private var isSeekingGesture: Bool = false
    private var seekTime: TimeInterval = 0
    
    
    /// 手势提示视图
    private lazy var gestureHintView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        view.layer.cornerRadius = 8
        view.isHidden = true
        return view
    }()
    
    private lazy var gestureIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        return imageView
    }()
    
    private lazy var gestureLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        return label
    }()
    
    lazy var bottomControlView: MMVideoBottomControlView = {
       let bot = MMVideoBottomControlView()
        bot.progressView.delegate = self
        bot.controlView.delegate = self
        return bot
    }()
    
    lazy var playerContainerView: UIView = {
        let item = UIView()
        item.backgroundColor = .black
        return item
    }()
    
    // MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        addSubview(playerContainerView)
        addSubview(bottomControlView)
        addSubview(loadingIndicator)
        addSubview(errorLabel)
        addSubview(gestureHintView)
        
        // 手势提示视图内部布局
        gestureHintView.addSubview(gestureIconImageView)
        gestureHintView.addSubview(gestureLabel)
        
        // 初始布局，稍后根据设置调整
        setupPlayerContainerConstraints()
        
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        errorLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        gestureHintView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.greaterThanOrEqualTo(120)
            make.height.greaterThanOrEqualTo(80)
        }
        
        gestureIconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.centerX.equalToSuperview()
            make.size.equalTo(24)
        }
        
        gestureLabel.snp.makeConstraints { make in
            make.top.equalTo(gestureIconImageView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-16)
        }
        
        bottomControlView.status = 0;
        bottomControlView.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalToSuperview()
        }
        
        setupGestures()
    }
    
    private func setupPlayerContainerConstraints() {
        // 移除现有约束
        playerContainerView.snp.removeConstraints()
        
        if MMVideoPlayerSettings.shared.controlsAlwaysVisible {
            // 常驻模式：避免被导航栏和控制条遮挡
            playerContainerView.snp.makeConstraints { make in
                make.top.equalTo(safeAreaLayoutGuide.snp.top)
                make.leading.trailing.equalToSuperview()
                make.bottom.equalTo(bottomControlView.snp.top)
            }
        } else {
            // 非常驻模式：占满整个视图
            playerContainerView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
    
    private func setupGestures() {
        // 添加单击手势显示/隐藏控制栏
        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSingleTapGesture))
        singleTapGesture.numberOfTapsRequired = 1
        
        // 添加双击手势播放/暂停
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTapGesture))
        doubleTapGesture.numberOfTapsRequired = 2
        
        // 设置单击手势需要双击手势失败才能触发
        singleTapGesture.require(toFail: doubleTapGesture)
        
        // 添加滑动手势（仅在非Mac环境下）
        if !ProcessInfo.processInfo.isMacCatalystApp {
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
            panGesture.maximumNumberOfTouches = 1
            panGesture.delegate = self
            playerContainerView.addGestureRecognizer(panGesture)
        }
        
        playerContainerView.addGestureRecognizer(singleTapGesture)
        playerContainerView.addGestureRecognizer(doubleTapGesture)
        playerContainerView.isUserInteractionEnabled = true
    }
    
    // MARK: - 播放视频
    func playVideo(with item: MMVideoItem) {
        // 重置UI状态
        resetUI()
        
        // 移除旧的 observer和layer
        removePeriodicTimeObserver()
        removePlayerLayer()
        
        // 显示加载状态
        showLoading()
        
        playerTool = MMVideoPlayerTool(item: item)
        
        setupAudioSession()
        addPeriodicTimeObserver()
        
        // playerLayer将在layoutSubviews中创建和设置
    }
    
    private func removePlayerLayer() {
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
    }
    
    private func setupPlayerLayer() {
        guard playerTool != nil, playerLayer == nil else { return }
        
        playerLayer = AVPlayerLayer(player: playerTool?.videoPlayer)
        playerLayer?.videoGravity = .resizeAspect
        playerLayer?.frame = playerContainerView.bounds
        
        if let layer = playerLayer {
            playerContainerView.layer.addSublayer(layer)
        }
    }
    
    private func resetUI() {
        hideLoading()
        hideError()
        bottomControlView.controlView.playBtn.isSelected = false
        
        // 根据设置决定控制条初始状态和布局
        updateLayoutForCurrentSettings()
    }
    
    private func updateLayoutForCurrentSettings() {
        let alwaysVisible = MMVideoPlayerSettings.shared.controlsAlwaysVisible
        
        // 更新控制条状态
        if alwaysVisible {
            isControlsVisible = true
            // 常驻模式下直接设置透明度，避免闪烁
            bottomControlView.alpha = 1.0
        }
        
        // 更新播放容器布局
        setupPlayerContainerConstraints()
        
        // 强制立即布局
        layoutIfNeeded()
        
        // 布局完成后更新播放器layer的frame
        DispatchQueue.main.async { [weak self] in
            self?.updatePlayerLayerFrame()
        }
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            showError("音频会话设置失败: \(error.localizedDescription)")
        }
    }
    
    private func showLoading() {
        loadingIndicator.startAnimating()
        errorLabel.isHidden = true
    }
    
    private func hideLoading() {
        loadingIndicator.stopAnimating()
    }
    
    private func showError(_ message: String) {
        hideLoading()
        errorLabel.text = message
        errorLabel.isHidden = false
    }
    
    private func hideError() {
        errorLabel.isHidden = true
    }
    
    private var timeObserverToken: Any?

    private func removePeriodicTimeObserver() {
        if let token = timeObserverToken {
            playerTool?.videoPlayer?.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }
    
    private func addPeriodicTimeObserver() {
        guard let player = playerTool?.videoPlayer else { return }
        
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.updateTimeUI(time: time)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 如果有playerTool但没有playerLayer，创建playerLayer
        setupPlayerLayer()
        
        // 更新playerLayer的frame为playerContainerView的bounds
        updatePlayerLayerFrame()
    }
    
    private func updatePlayerLayerFrame() {
        if let playerLayer = playerLayer {
            playerLayer.frame = playerContainerView.bounds
        }
    }
    
    deinit {
        removePeriodicTimeObserver()
        stopControlHideTimer()
        removePlayerLayer()
    }
    
    // MARK: - 手势处理
    @objc private func handleSingleTapGesture() {
        // 常驻模式下不响应单击切换
        if !MMVideoPlayerSettings.shared.controlsAlwaysVisible {
            toggleControlsVisibility()
        }
    }
    
    @objc private func handleDoubleTapGesture() {
        togglePlayPause()
        showControls() // 双击时显示控制栏以便用户看到状态变化
    }
    
    private func togglePlayPause() {
        guard let playerTool = playerTool else { return }
        
        switch playerTool.state {
        case .playing:
            playerTool.pause()
        case .paused, .readyToPlay:
            playerTool.play()
        case .ended:
            // 如果播放结束，重新开始播放
            playerTool.play()
        default:
            break
        }
    }
    
    // MARK: - 键盘操作处理
    func handleSpaceKeyToggle() {
        togglePlayPause()
        showControls() // 显示控制栏以便用户看到状态变化
    }
    
    // MARK: - 播放控制
    func pausePlayback() {
        playerTool?.pause()
    }
    
    func stopPlayback() {
        playerTool?.stop()
        removePeriodicTimeObserver()
        removePlayerLayer()
        stopControlHideTimer()
    }
    
    func handleSeekForward(seconds: Double) {
        guard let playerTool = playerTool,
              let duration = playerTool.videoPlayer?.currentItem?.duration,
              let currentTime = playerTool.videoPlayer?.currentTime() else { return }
        
        let currentSeconds = CMTimeGetSeconds(currentTime)
        let totalSeconds = CMTimeGetSeconds(duration)
        let targetSeconds = min(currentSeconds + seconds, totalSeconds)
        let targetTime = CMTime(seconds: targetSeconds, preferredTimescale: 600)
        
        playerTool.seek(to: targetTime) { [weak self] _ in
            // 快进后继续播放
            if self?.playerTool?.state != .playing {
                self?.playerTool?.play()
            }
        }
        
        // 显示快进提示
        showSeekHint(isForward: true, seconds: seconds)
        showControls()
    }
    
    func handleSeekBackward(seconds: Double) {
        guard let playerTool = playerTool,
              let currentTime = playerTool.videoPlayer?.currentTime() else { return }
        
        let currentSeconds = CMTimeGetSeconds(currentTime)
        let targetSeconds = max(currentSeconds - seconds, 0)
        let targetTime = CMTime(seconds: targetSeconds, preferredTimescale: 600)
        
        playerTool.seek(to: targetTime) { [weak self] _ in
            // 快退后继续播放
            if self?.playerTool?.state != .playing {
                self?.playerTool?.play()
            }
        }
        
        // 显示快退提示
        showSeekHint(isForward: false, seconds: seconds)
        showControls()
    }
    
    // MARK: - 公开方法
    func updateLayoutForSettingsChange() {
        updateLayoutForCurrentSettings()
    }
    
    private func showSeekHint(isForward: Bool, seconds: Double) {
        let iconName = isForward ? "goforward" : "gobackward"
        let text = isForward ? "快进 \(Int(seconds))秒" : "快退 \(Int(seconds))秒"
        
        gestureIconImageView.image = UIImage(systemName: iconName)
        gestureLabel.text = text
        gestureHintView.isHidden = false
        
        // 2秒后隐藏提示
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.hideGestureHint()
        }
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        // Mac版本不支持滑动手势控制
        guard !ProcessInfo.processInfo.isMacCatalystApp else { return }
        
        let translation = gesture.translation(in: self)
        let velocity = gesture.velocity(in: self)
        let location = gesture.location(in: self)
        
        switch gesture.state {
        case .began:
            handlePanBegan(at: location)
        case .changed:
            handlePanChanged(translation: translation, velocity: velocity)
        case .ended, .cancelled:
            handlePanEnded()
        default:
            break
        }
    }
    
    private func handlePanBegan(at location: CGPoint) {
        panStartPoint = location
        
        // 获取当前音量和亮度
        panStartVolume = AVAudioSession.sharedInstance().outputVolume
        panStartBrightness = UIScreen.main.brightness
        
        // 重置状态
        isSeekingGesture = false
        seekTime = 0
        
        showControls() // 滑动开始时显示控制栏
    }
    
    private func handlePanChanged(translation: CGPoint, velocity: CGPoint) {
        let horizontalTranslation = translation.x
        let verticalTranslation = translation.y
        
        // 判断是水平滑动还是垂直滑动
        if abs(horizontalTranslation) > abs(verticalTranslation) {
            // 水平滑动：快进/快退
            handleSeekGesture(translation: horizontalTranslation)
        } else {
            // 垂直滑动：音量/亮度调节
            handleVolumeOrBrightnessGesture(translation: verticalTranslation)
        }
    }
    
    private func handleSeekGesture(translation: CGFloat) {
        guard let duration = playerTool?.videoPlayer?.currentItem?.duration else { return }
        
        if !isSeekingGesture {
            isSeekingGesture = true
            if let currentTime = playerTool?.videoPlayer?.currentTime() {
                seekTime = CMTimeGetSeconds(currentTime)
            }
        }
        
        let totalDuration = CMTimeGetSeconds(duration)
        let seekOffset = Double(translation) / Double(bounds.width) * totalDuration * 2 // 2倍灵敏度
        seekTime = max(0, min(seekTime + seekOffset, totalDuration))
        
        showGestureHint(type: .seek, value: seekTime)
    }
    
    private func handleVolumeOrBrightnessGesture(translation: CGFloat) {
        let screenWidth = bounds.width
        let isLeftSide = panStartPoint.x < screenWidth / 2
        
        if isLeftSide {
            // 左侧：调节亮度
            let brightnessOffset = -translation / bounds.height
            let newBrightness = max(0, min(panStartBrightness + brightnessOffset, 1))
            UIScreen.main.brightness = newBrightness
            
            showGestureHint(type: .brightness, value: Double(newBrightness))
        } else {
            // 右侧：调节音量
            let volumeOffset = -Float(translation / bounds.height)
            let newVolume = max(0, min(panStartVolume + volumeOffset, 1))
            
            // 使用MPVolumeView调节音量（兼容Mac）
            setSystemVolume(newVolume)
            showGestureHint(type: .volume, value: Double(newVolume))
        }
    }
    
    private func handlePanEnded() {
        hideGestureHint()
        
        if isSeekingGesture {
            // 执行跳转
            let targetTime = CMTime(seconds: seekTime, preferredTimescale: 600)
            playerTool?.seek(to: targetTime) { [weak self] _ in
                self?.playerTool?.play()
            }
            isSeekingGesture = false
        }
    }
    
    private func toggleControlsVisibility() {
        isControlsVisible = !isControlsVisible
        if isControlsVisible {
            startControlHideTimer()
        }
    }
    
    private func showControls() {
        isControlsVisible = true
        startControlHideTimer()
    }
    
    private func hideControls() {
        // 如果设置了控制条常驻，不隐藏
        if MMVideoPlayerSettings.shared.controlsAlwaysVisible {
            return
        }
        
        // 只有在播放状态下才自动隐藏控制栏
        if playerTool?.state == .playing {
            isControlsVisible = false
        }
    }
    
    private func updateControlsVisibility() {
        // 常驻模式下不使用动画，避免闪烁
        let animationDuration = MMVideoPlayerSettings.shared.controlsAlwaysVisible ? 0.0 : 0.3
        
        UIView.animate(withDuration: animationDuration) {
            self.bottomControlView.alpha = self.isControlsVisible ? 1.0 : 0.0
        }
        
        // 发送通知给视频控制器更新导航栏状态
        NotificationCenter.default.post(
            name: NSNotification.Name("MMVideoControlsVisibilityChanged"), 
            object: nil, 
            userInfo: ["isVisible": isControlsVisible]
        )
    }
    
    private func startControlHideTimer() {
        stopControlHideTimer()
        
        // 如果设置了控制条常驻，不启动隐藏定时器
        if MMVideoPlayerSettings.shared.controlsAlwaysVisible {
            return
        }
        
        // 只有在播放状态下才启动自动隐藏定时器
        if playerTool?.state == .playing {
            controlHideTimer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(hideControlsTimerFired), userInfo: nil, repeats: false)
        }
    }
    
    private func stopControlHideTimer() {
        controlHideTimer?.invalidate()
        controlHideTimer = nil
    }
    
    @objc private func hideControlsTimerFired() {
        hideControls()
    }
    
    // MARK: - 手势提示
    enum GestureHintType {
        case volume
        case brightness  
        case seek
        case speed
    }
    
    private func showGestureHint(type: GestureHintType, value: Double) {
        gestureHintView.isHidden = false
        
        switch type {
        case .volume:
            gestureIconImageView.image = UIImage(systemName: "speaker.wave.2.fill")
            gestureLabel.text = String(format: "音量 %.0f%%", value * 100)
        case .brightness:
            gestureIconImageView.image = UIImage(systemName: "sun.max.fill")
            gestureLabel.text = String(format: "亮度 %.0f%%", value * 100)
        case .seek:
            let isForward = seekTime > (playerTool?.videoPlayer?.currentTime().seconds ?? 0)
            gestureIconImageView.image = UIImage(systemName: isForward ? "goforward" : "gobackward")
            gestureLabel.text = formatTime(seconds: value)
        case .speed:
            gestureIconImageView.image = UIImage(systemName: "speedometer")
            let speedText = value == 1.0 ? "正常速度" : String(format: "%.1fx", value)
            gestureLabel.text = speedText
        }
    }
    
    private func hideGestureHint() {
        UIView.animate(withDuration: 0.2) {
            self.gestureHintView.alpha = 0
        } completion: { _ in
            self.gestureHintView.isHidden = true
            self.gestureHintView.alpha = 1
        }
    }
    
    // MARK: - 音量控制 (兼容Mac)
    private func setSystemVolume(_ volume: Float) {
        if ProcessInfo.processInfo.isMacCatalystApp {
            // Mac版本暂不支持系统音量调节，可以调节播放器音量
            playerTool?.videoPlayer?.volume = volume
        } else {
            // iOS版本使用MPVolumeView调节系统音量
            DispatchQueue.main.async { [weak self] in
                self?.adjustSystemVolume(to: volume)
            }
        }
    }
    
    private func adjustSystemVolume(to volume: Float) {
        let volumeView = MPVolumeView(frame: CGRect(x: -1000, y: -1000, width: 1, height: 1))
        addSubview(volumeView)
        
        for subview in volumeView.subviews {
            if let slider = subview as? UISlider {
                slider.value = volume
                break
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            volumeView.removeFromSuperview()
        }
    }
    
    // MARK: - 倍速播放
    private func handleSpeedButtonTapped() {
        guard let playerTool = playerTool else { return }
        
        let nextSpeed = playerTool.getNextPlaybackRate()
        playerTool.setPlaybackRate(nextSpeed)
        
        // 更新按钮显示
        bottomControlView.controlView.updateSpeedButtonTitle(nextSpeed)
        
        // 显示速度提示
        showGestureHint(type: .speed, value: Double(nextSpeed))
        
        // 2秒后隐藏提示
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.hideGestureHint()
        }
    }
}

extension MMVideoPlayView {
    private func updateTimeUI(time: CMTime) {
            guard let duration = playerTool?.videoPlayer?.currentItem?.duration else { return }
            let totalSeconds = CMTimeGetSeconds(duration)
            let currentSeconds = CMTimeGetSeconds(time)
            
            if !totalSeconds.isFinite { return }
        
           let progress = Double(currentSeconds / totalSeconds)
        bottomControlView.progressView.currentTimeLabel.text = formatTime(seconds: currentSeconds)
        bottomControlView.progressView.remainingTimeLabel.text = "-\(formatTime(seconds: totalSeconds - currentSeconds))"
        
        bottomControlView.progressView.updatePregress(progress)

        }
        
        private func formatTime(seconds: Double) -> String {
            guard seconds.isFinite else { return "--:--" }
            let mins = Int(seconds) / 60
            let secs = Int(seconds) % 60
            return String(format: "%02d:%02d", mins, secs)
        }
}


// MARK: - MMVideoProgressViewDelegate
extension MMVideoPlayView: MMVideoProgressViewDelegate {
    func progressView(_ progressView: MMVideoPlayControlView, controlType: MMVideoPlayControlView.MMVideoPlayerControlType) {
        switch controlType {
        case .play:
            playerTool?.play()
        case .pause:
            playerTool?.pause()
        case .preItem:
            break
        case .nextItem:
            break
        case .speed:
            handleSpeedButtonTapped()
        }
    }
    
    func progressView(_ progressView: MMVideoProgressView, seekTo progress: Double) {
        guard let duration = playerTool?.videoPlayer?.currentItem?.duration else { return }
        let totalSeconds = CMTimeGetSeconds(duration)
        let targetSeconds = totalSeconds * progress
        let targetTime = CMTime(seconds: targetSeconds, preferredTimescale: 600)
        
        playerTool?.seek(to: targetTime) { [weak self] finished in
            if finished {
                self?.playerTool?.play()
            }
        }
    }
    
    func progressViewGetTotalDuration(_ progressView: MMVideoProgressView) -> Double {
        guard let duration = playerTool?.videoPlayer?.currentItem?.duration else { return 0 }
        return CMTimeGetSeconds(duration)
    }
    
    func progressView(_ progressView: MMVideoProgressView, getThumbnailAt time: Double, completion: @escaping (UIImage?) -> Void) {
        guard let player = playerTool?.videoPlayer,
              let asset = player.currentItem?.asset else {
            completion(nil)
            return
        }
        
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 120, height: 68) // 16:9 比例
        
        let time = CMTime(seconds: time, preferredTimescale: 600)
        
        imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, cgImage, _, result, error in
            DispatchQueue.main.async {
                if let cgImage = cgImage, result == .succeeded {
                    completion(UIImage(cgImage: cgImage))
                } else {
                    completion(nil)
                }
            }
        }
    }
}

// MARK: - MMVideoPlayerToolDelegate
extension MMVideoPlayView: MMVideoPlayerToolDelegate {
    func playerTool(_ tool: MMVideoPlayerTool, didChangeState state: MMVideoPlayerState) {
        DispatchQueue.main.async {
            self.handlePlayerStateChange(state)
        }
    }
    
    func playerTool(_ tool: MMVideoPlayerTool, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.showError("播放失败: \(error.localizedDescription)")
        }
    }
    
    func playerTool(_ tool: MMVideoPlayerTool, didUpdateLoadedTime loadedTime: TimeInterval) {
        DispatchQueue.main.async {
            // 更新缓冲进度
            // 这里可以添加缓冲进度条的更新逻辑
        }
    }
    
    func playerToolDidReachEnd(_ tool: MMVideoPlayerTool) {
        DispatchQueue.main.async {
            self.bottomControlView.controlView.playBtn.isSelected = false
            // 可以在这里添加重播按钮或其他逻辑
        }
    }
    
    private func handlePlayerStateChange(_ state: MMVideoPlayerState) {
        switch state {
        case .preparing:
            showLoading()
            showControls()
        case .readyToPlay:
            hideLoading()
            hideError()
            // 确保playerLayer已创建
            setupPlayerLayer()
            // 更新倍速按钮显示
            if let playerTool = playerTool {
                bottomControlView.controlView.updateSpeedButtonTitle(playerTool.playbackRate)
            }
            // 自动开始播放
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.playerTool?.play()
            }
        case .playing:
            hideLoading()
            hideError()
            bottomControlView.controlView.playBtn.isSelected = true
            startControlHideTimer()
        case .paused:
            bottomControlView.controlView.playBtn.isSelected = false
            stopControlHideTimer()
            showControls()
        case .stopped:
            bottomControlView.controlView.playBtn.isSelected = false
            stopControlHideTimer()
            showControls()
        case .failed:
            hideLoading()
            bottomControlView.controlView.playBtn.isSelected = false
            stopControlHideTimer()
            showControls()
        case .ended:
            bottomControlView.controlView.playBtn.isSelected = false
            stopControlHideTimer()
            showControls()
            // 播放结束时重置倍速
            playerTool?.setPlaybackRate(1.0)
            bottomControlView.controlView.updateSpeedButtonTitle(1.0)
        case .unknown:
            break
        }
    }
}

// MARK: - UIGestureRecognizerDelegate
extension MMVideoPlayView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // 让屏幕边缘手势（返回手势）优先
        if otherGestureRecognizer is UIScreenEdgePanGestureRecognizer {
            return true
        }
        return false
    }
}

// MARK: - Helper Extension
extension UIView {
    func findViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.findViewController()
        } else {
            return nil
        }
    }
}
