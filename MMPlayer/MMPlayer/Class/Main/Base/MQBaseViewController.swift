//
//  MQBaseViewController.swift
//  MMQRCode
//
//  Created by yangjie on 2019/7/25.
//  Copyright © 2019 yangjie. All rights reserved.
//

import UIKit

class MQBaseViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

}

extension UIViewController {
    @objc enum PopItemStyle:Int {
        case PopItemBlack = 0,PopItemWhite
    }
    
    @objc func naviBarPopItemStyle() -> PopItemStyle {
        return .PopItemBlack
    }
    
    @objc func popToPreviousVC() {
        if self.navigationController != nil {
            self.navigationController?.popViewController(animated: true)
        }
    }
}
