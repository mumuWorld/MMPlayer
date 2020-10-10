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
