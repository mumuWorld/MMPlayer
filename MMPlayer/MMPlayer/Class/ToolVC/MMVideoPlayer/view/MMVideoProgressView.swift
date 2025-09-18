//
//  MMVideoProgressView.swift
//  MMPlayer
//
//  Created by mumu on 2020/8/27.
//  Copyright © 2020 Mumu. All rights reserved.
//

import UIKit
import AVFoundation

protocol MMVideoProgressViewDelegate: AnyObject {
    func progressView(_ progressView: MMVideoProgressView, seekTo progress: Double)
    
    func progressView(_ progressView: MMVideoPlayControlView, controlType: MMVideoPlayControlView.MMVideoPlayerControlType)
    
    // 新增：获取视频总时长
    func progressViewGetTotalDuration(_ progressView: MMVideoProgressView) -> Double
    
    // 新增：获取指定时间的视频截图
    func progressView(_ progressView: MMVideoProgressView, getThumbnailAt time: Double, completion: @escaping (UIImage?) -> Void)
}

class MMVideoProgressView: UIView {

    // MARK: - Constants
    private struct Constants {
        static let progressIndexWidth: CGFloat = 20
        static let progressIndexHeight: CGFloat = 20
        static let horizontalMargin: CGFloat = 80
        static let progressYOffset: CGFloat = 6
    }
    
    private var progressIndexWidth: CGFloat { Constants.progressIndexWidth }
    
    @IBOutlet weak var progressBgView: UIView!
    
    @IBOutlet weak var progressContainView: UIView!
    
    @IBOutlet weak var progressLoadingView: UIView!
    
    @IBOutlet weak var progressPlayingView: UIView!
    
    @IBOutlet weak var progressIndexImg: UIImageView!

    
    @IBOutlet weak var currentTimeLabel: UILabel!
    
    @IBOutlet weak var remainingTimeLabel: UILabel!
    
    var delegate: MMVideoProgressViewDelegate?
    
    private var lastIndexPositionX: CGFloat = 0
    private var maxIndexFrame: CGRect = CGRect.zero
    private var isDragging: Bool = false
    private var wasPlayingBeforeDrag: Bool = false
    private var thumbnailCache: [Int: UIImage] = [:]
    private var lastThumbnailRequestTime: TimeInterval = 0
    
    // 拖拽预览容器
    private lazy var previewContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        view.isHidden = true
        return view
    }()
    
    // 预览截图
    private lazy var previewImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = UIColor.black
        imageView.layer.cornerRadius = 4
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    // 拖拽预览时间标签
    private lazy var previewTimeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .center
        return label
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
        setupGestures()
    }
    
    private func setupUI() {
        // 添加预览容器
        addSubview(previewContainer)
        previewContainer.addSubview(previewImageView)
        previewContainer.addSubview(previewTimeLabel)
        
        // 设置预览容器布局
        previewContainer.snp.makeConstraints { make in
            make.centerX.equalTo(progressIndexImg)
            make.bottom.equalTo(progressIndexImg.snp.top).offset(-8)
            make.width.equalTo(120)
            make.height.equalTo(80)
        }
        
        previewImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(8)
            make.height.equalTo(45)
        }
        
        previewTimeLabel.snp.makeConstraints { make in
            make.top.equalTo(previewImageView.snp.bottom).offset(4)
            make.leading.trailing.bottom.equalToSuperview().inset(8)
        }
        
        progressIndexImg.mm_size = CGSize(width: Constants.progressIndexWidth, height: Constants.progressIndexHeight)
    }
    
    private func setupGestures() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(sender:)))
        progressIndexImg.isUserInteractionEnabled = true
        progressIndexImg.addGestureRecognizer(pan)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(sender:)))
        progressBgView.addGestureRecognizer(tap)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let w = mm_width - Constants.horizontalMargin * 2
        let indexX = w * progress
        progressIndexImg.mm_centerX = indexX
        progressIndexImg.mm_y = Constants.progressYOffset
        
        maxIndexFrame = CGRect(x: 0, y: 0, width: w, height: frame.height)
        
        // 更新预览容器位置
        previewContainer.snp.remakeConstraints { make in
            make.centerX.equalTo(progressIndexImg)
            make.bottom.equalTo(progressIndexImg.snp.top).offset(-8)
            make.width.equalTo(120)
            make.height.equalTo(80)
        }
    }
    
    // MARK: - 手势处理
    @objc private func handleTapGesture(sender: UITapGestureRecognizer) {
        let point = sender.location(in: progressContainView)
        let progress = calculateProgress(for: point.x)
        seekToProgress(progress)
    }
    
    @objc private func handlePanGesture(sender: UIPanGestureRecognizer) {
        let moviePoint = sender.translation(in: progressIndexImg)
        
        switch sender.state {
        case .began:
            startDragging()
        case .changed:
            handleDragChanged(translation: moviePoint)
        case .ended:
            endDragging()
        case .cancelled, .failed:
            cancelDragging()
        default:
            break
        }
    }
    
    // MARK: - 拖拽处理
    private func startDragging() {
        isDragging = true
        lastIndexPositionX = progressIndexImg.mm_centerX
        maxIndexFrame = progressContainView.frame
        showPreviewContainer()
        
        // 记录拖拽前的播放状态（这里需要从委托获取）
        // wasPlayingBeforeDrag = playerTool?.state == .playing
    }
    
    private func handleDragChanged(translation: CGPoint) {
        let purposeX = lastIndexPositionX + translation.x
        let clampedX = max(0, min(purposeX, maxIndexFrame.width))
        
        progressIndexImg.mm_centerX = clampedX
        progressPlayingView.mm_right = clampedX
        
        // 更新预览时间和截图
        updatePreviewContent()
    }
    
    private func endDragging() {
        isDragging = false
        hidePreviewContainer()
        
        let progress = calculateProgress()
        seekToProgress(progress)
    }
    
    private func cancelDragging() {
        isDragging = false
        hidePreviewContainer()
        
        // 恢复到拖拽前的位置
        progressIndexImg.mm_centerX = lastIndexPositionX
        progressPlayingView.mm_right = lastIndexPositionX
    }
    
    private func seekToProgress(_ progress: CGFloat) {
        delegate?.progressView(self, seekTo: Double(progress))
    }
    
    func calculateProgress() -> CGFloat {
        let progressWidth = mm_width - Constants.horizontalMargin * 2
        let percent = progressIndexImg.mm_centerX / progressWidth
        return min(1, max(0, percent))
    }
    
    private func calculateProgress(for x: CGFloat) -> CGFloat {
        let progressWidth = mm_width - Constants.horizontalMargin * 2
        let percent = x / progressWidth
        return min(1, max(0, percent))
    }
    
    // MARK: - 预览容器
    private func showPreviewContainer() {
        previewContainer.isHidden = false
        updatePreviewContent()
    }
    
    private func hidePreviewContainer() {
        previewContainer.isHidden = true
    }
    
    private func updatePreviewContent() {
        let progress = calculateProgress()
        let totalDuration = delegate?.progressViewGetTotalDuration(self) ?? 0
        let previewTime = totalDuration * Double(progress)
        
        // 更新时间显示
        previewTimeLabel.text = formatTime(seconds: previewTime)
        
        // 防抖：限制截图请求频率
        let currentTime = CACurrentMediaTime()
        guard currentTime - lastThumbnailRequestTime > 0.1 else { return } // 100ms防抖
        lastThumbnailRequestTime = currentTime
        
        // 使用5秒间隔作为缓存key
        let cacheKey = Int(previewTime / 5) * 5
        
        // 检查缓存
        if let cachedImage = thumbnailCache[cacheKey] {
            previewImageView.image = cachedImage
            return
        }
        
        // 获取截图
        delegate?.progressView(self, getThumbnailAt: previewTime) { [weak self] image in
            DispatchQueue.main.async {
                self?.previewImageView.image = image
                
                // 缓存截图（限制缓存大小）
                if let image = image {
                    if self?.thumbnailCache.count ?? 0 > 20 {
                        self?.thumbnailCache.removeAll()
                    }
                    self?.thumbnailCache[cacheKey] = image
                }
            }
        }
    }
    
    private func formatTime(seconds: Double) -> String {
        guard seconds.isFinite && seconds >= 0 else { return "00:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    var progress: Double = 0
    
    func updatePregress(_ progress: Double) {
        // 如果正在拖拽，不更新UI位置
        guard !isDragging else {
            self.progress = progress
            return
        }
        
        self.progress = progress
        let w = mm_width - Constants.horizontalMargin * 2
        let indexX = w * progress
        progressIndexImg.mm_centerX = indexX
        progressIndexImg.mm_y = Constants.progressYOffset
        progressPlayingView.mm_right = indexX
    }
}

// MARK: - 扩展已移除，功能已合并到主类中

class MMVideoPlayControlView: UIView {
    
    var delegate: MMVideoProgressViewDelegate?

    enum MMVideoPlayerControlType {
        case play
        case pause
        case preItem
        case nextItem
        case speed
    }
    
    @IBOutlet weak var preBtn: UIButton!
    
    @IBOutlet weak var playBtn: UIButton!
    
    @IBOutlet weak var nextBtn: UIButton!
    
    // 倍速播放按钮（代码创建）
    private lazy var speedBtn: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("1.0x", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        button.layer.cornerRadius = 4
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(speedButtonTapped), for: .touchUpInside)
        return button
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    private func setupUI() {
        // 设置原有按钮样式
        subviews.first?.subviews.forEach { item in
            item.layer.cornerRadius = 4
            item.layer.masksToBounds = true
        }
        
        // 添加倍速按钮到右侧
        addSubview(speedBtn)
        speedBtn.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-16)
            make.width.equalTo(50)
            make.height.equalTo(30)
        }
    }
    
    @objc private func speedButtonTapped() {
        delegate?.progressView(self, controlType: .speed)
    }
    
    /// 更新倍速按钮显示
    func updateSpeedButtonTitle(_ speed: Float) {
        let speedText = speed == 1.0 ? "1.0x" : String(format: "%.1fx", speed)
        speedBtn.setTitle(speedText, for: .normal)
    }
    
    @IBAction func next(_ sender: UIButton) {
        delegate?.progressView(self, controlType: .nextItem)
    }
    
    @IBAction func playOrPause(_ sender: UIButton) {
        delegate?.progressView(self, controlType: sender.isSelected ? .pause : .play)
    }
    
    @IBAction func pre(_ sender: UIButton) {
        delegate?.progressView(self, controlType: .preItem)

    }
}

class MMVideoBottomControlView: UIView {
    
    lazy var controlView: MMVideoPlayControlView = loadXibView(index: 1) as! MMVideoPlayControlView
    
    lazy var progressView:MMVideoProgressView = loadXibView(index: 0) as! MMVideoProgressView
    
    let stackView: UIStackView = {
       let item = UIStackView()
        item.axis = .vertical
        item.alignment = .fill
        item.distribution = .equalSpacing
        return item
    }()
    /// 0竖屏 1横屏
    var status: Int = 0 {
        willSet {
//            if newValue == 0 {
//                var rect: CGRect = bounds
//                rect.size.height = 32
//                progressView.frame = rect
//                rect.size.height = 30
//                rect.origin.y = progressView.mm_height
//                controlView.frame = rect
//            } else {
//
//            }
        }
    }
    
    func loadXibView(index:Int) -> Any {
        let playControl = UINib.init(nibName: "MMToolsView", bundle: nil).instantiate(withOwner: nil, options: nil)[index]
        return playControl
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.mm_colorFromHex(color_vaule: 0x006400, alpha: 0.6)
        self.addSubview(stackView)
        stackView.addArrangedSubview(progressView)
        stackView.addArrangedSubview(controlView)
        stackView.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.bottom.greaterThanOrEqualToSuperview().offset(-HomeIndicatorHeight)
        }
        progressView.snp.makeConstraints { make in
            make.height.equalTo(35)
        }
        controlView.snp.makeConstraints { make in
            make.height.equalTo(35)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
}
