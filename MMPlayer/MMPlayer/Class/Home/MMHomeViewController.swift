//
//  MMHomeViewController.swift
//  MMPlayer
//
//  Created by mumu on 2020/2/1.
//  Copyright © 2020 Mumu. All rights reserved.
//

import UIKit

class MMHomeViewController: MMBaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //初始化一个copy文件的文件夹
        MMFileManager.createDirectory(path: MMFileManager.receivedPath ?? "")
    }
    
    // 重写左侧按钮配置，保持原有的folder_icon图标
    override func leftBarItemConfiguration() -> BarItemConfiguration {
        return BarItemConfiguration(
            image: "folder_icon",
            selectedImage: nil,
            title: nil,
            tag: 10
        )
    }
    
    // 重写左侧按钮点击事件
    override func handleLeftBarItemClick() {
        MMPrintLog(message: "HomeViewController left bar item clicked")
        let boxVC = MMSandboxVC()
        navigationController?.pushViewController(boxVC, animated: true)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        let video = MMVideoViewController()
//        navigationController?.pushViewController(video, animated: true)
        
    }
}
