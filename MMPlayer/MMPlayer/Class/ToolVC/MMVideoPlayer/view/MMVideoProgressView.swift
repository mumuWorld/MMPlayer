//
//  MMVideoProgressView.swift
//  MMPlayer
//
//  Created by mumu on 2020/8/27.
//  Copyright © 2020 Mumu. All rights reserved.
//

import UIKit

class MMVideoProgressView: UIView {

    @IBOutlet weak var progressBgView: UIView!
    
    @IBOutlet weak var progressContainView: UIView!
    
    @IBOutlet weak var progressLoadingView: UIView!
    
    @IBOutlet weak var progressPlayingView: UIView!
    
    @IBOutlet weak var progressIndexImg: UIImageView!

    var lastIndexPositionX: CGFloat = 0
    var maxIndexFrame: CGRect = CGRect.zero
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleTapGes(sender:)))
//        pan.delegate = self
        progressIndexImg.isUserInteractionEnabled = true
        progressIndexImg.addGestureRecognizer(pan)
        
        let tap_2 = UITapGestureRecognizer(target: self, action: #selector(handleTapGes(sender:)))
        progressBgView.addGestureRecognizer(tap_2)
        let left = MQScreenWidth - 80
        maxIndexFrame = CGRect.init(x: left, y: 0, width: left - 80, height: 0)
    }
    
    
    @objc func handleTapGes(sender: UIGestureRecognizer) {
        if sender.view == progressBgView {
            let point = sender.location(in: progressContainView)
            progressIndexImg.mm_x = point.x
            MPPrintLog(message: "point=\(point)")
        } else if sender.view == progressIndexImg {
            let pan = sender as! UIPanGestureRecognizer
            let moviePoint = pan.translation(in: progressIndexImg)
            MPPrintLog(message: "point=\(moviePoint)")
            
            switch sender.state {
            case .began:
                lastIndexPositionX = progressIndexImg.mm_x
                maxIndexFrame = progressContainView.frame
                MPPrintLog(message: "began")
            case .changed:
                handleIndexImgPosition(moviePoint: moviePoint)
                MPPrintLog(message: "changed")
            case .ended:
                //这里开发播放
                MPPrintLog(message: "end")
            case .cancelled:
                //回复当前进度
                MPPrintLog(message: "cancelled")
            default:
                break
            }
        }
    }
}

extension MMVideoProgressView {
    func handleIndexImgPosition(moviePoint: CGPoint) {
        let purposeX = lastIndexPositionX + moviePoint.x
        progressIndexImg.mm_x = max(maxIndexFrame.minX, min(purposeX, maxIndexFrame.maxX))
        progressPlayingView.mm_right = progressIndexImg.mm_right
    }
}

class MMVideoPlayControlView: UIView {
    
}

class MMVideoBottomControlView: UIView {
    
    lazy var controlView: MMVideoPlayControlView = loadXibView(index: 1) as! MMVideoPlayControlView
    
    lazy var progressView:MMVideoProgressView = loadXibView(index: 0) as! MMVideoProgressView
    
    /// 0竖屏 1横屏
    var status: Int = 0 {
        willSet {
            if newValue == 0 {
                var rect: CGRect = bounds
                rect.size.height = 32
                progressView.frame = rect
                rect.size.height = 30
                rect.origin.y = progressView.mm_height
                controlView.frame = rect
            } else {
                
            }
        }
    }
    
    func loadXibView(index:Int) -> Any {
        let playControl = UINib.init(nibName: "MMToolsView", bundle: nil).instantiate(withOwner: nil, options: nil)[index]
        return playControl
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.mm_colorFromHex(color_vaule: 0x006400, alpha: 0.6)
        addSubview(controlView)
        addSubview(progressView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
}
