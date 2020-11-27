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

    var playerTool: MMVideoPlayerTool?
    
    lazy var touchView:UIView = {
        let tV = UIView()
        return tV
    }()
    
    var playerLayer: CALayer?
    
    lazy var bottomControlView: MMVideoBottomControlView = {
       let bot = MMVideoBottomControlView()
        return bot
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(bottomControlView)
        bottomControlView.frame = CGRect.init(x: 0, y: MQScreenHeight - (100 + MQHomeIndicatorHeight), width: MQScreenWidth, height: 100+MQHomeIndicatorHeight)
        bottomControlView.status = 0;
        
        if let item = videoItem {
            playerTool = MMVideoPlayerTool(item: item)
            playerLayer = AVPlayerLayer.init(player: playerTool?.videoPlayer)
            playerLayer?.frame = view.bounds
            if let layer = playerLayer {
                view.layer.addSublayer(layer)
            }
//            playerTool?.play()
        }
        
    }
}
