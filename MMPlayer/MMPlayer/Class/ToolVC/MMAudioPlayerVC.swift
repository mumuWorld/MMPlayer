//
//  MMAudioPlayerVC.swift
//  MMPlayer
//
//  Created by mumu on 2020/5/12.
//  Copyright © 2020 Mumu. All rights reserved.
//

import UIKit
import AVFoundation

class MMAudioPlayerVC: MQBaseViewController {
    
    lazy var player = AVAudioPlayer()
    
    var audioItem: MMAudioItem?
    
    @IBOutlet weak var playBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let item = audioItem else {
            return
        }
        let url = URL(fileURLWithPath: item.path)
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player.play()
            playBtn.isSelected = false
        } catch {
            MPErrorLog(message: error)
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
