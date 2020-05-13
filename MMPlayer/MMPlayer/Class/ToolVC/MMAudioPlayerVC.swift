//
//  MMAudioPlayerVC.swift
//  MMPlayer
//
//  Created by mumu on 2020/5/12.
//  Copyright © 2020 Mumu. All rights reserved.
//

import UIKit

class MMAudioPlayerVC: MMBaseViewController {
    
     var audioItem: MMAudioItem?
    
    lazy var player: MMAudioPlayerTool = MMAudioPlayerTool.shared
    
    @IBOutlet weak var playBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let item = audioItem else {
            return
        }
        if player.audioItem?.name == item.name { //证明当前播放实例已经存在
            return
        }
        playBtn.isSelected = true
        player.audioItem = item
        navigationItem.title = audioItem?.name
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if playBtn.isSelected && !player.isPlaying {
            player.play()
        }
    }

    @IBAction func handleBtnClick(_ sender: UIButton) {
        switch sender.tag {
        case 10:
            if player.isPlaying {
                player.pause()
            } else {
                player.play()
            }
            sender.isSelected = !sender.isSelected
            
        default: break
        }
        
    }
    
    deinit {
//        player.stop()
    }

}
