//
//  MMHomeViewController.swift
//  MMPlayer
//
//  Created by mumu on 2020/2/1.
//  Copyright © 2020 Mumu. All rights reserved.
//

import UIKit

class MMHomeViewController: MMBaseTableViewController {
    
    lazy var leftBarItem: UIBarButtonItem = {
        let item = UIBarButtonItem.barButtomItem(title: nil, selectedTitle: nil, titleColor: nil, selectedColor: nil, image: "folder_icon", selectedImg: nil, target: self, selecter: #selector(handleBtnClick(sender:)), tag: 10)
        return item
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = leftBarItem
        //初始化一个copy文件的文件夹
        MMFileManager.createDirectory(path: MMFileManager.receivedPath ?? "")
    }
    
    @objc func handleBtnClick(sender: UIButton) {
        MPPrintLog(message :sender)
        let boxVC = MMSandboxVC()
        navigationController?.pushViewController(boxVC, animated: true)
    }

}
