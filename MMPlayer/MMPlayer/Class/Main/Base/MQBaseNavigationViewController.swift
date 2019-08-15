//
//  MQBaseNavigationViewController.swift
//  MMQRCode
//
//  Created by yangjie on 2019/7/25.
//  Copyright © 2019 yangjie. All rights reserved.
//

import UIKit

class MQBaseNavigationViewController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        //隐藏底部线
        self.navigationBar.shadowImage = UIImage()
        
        self.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: MQMainTitleColor]
        self.interactivePopGestureRecognizer?.delegate = self as UIGestureRecognizerDelegate
    }
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//    }
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        if viewControllers.count >= 1 {
            viewController.hidesBottomBarWhenPushed = true
            var itemStyle = PopItemStyle.PopItemBlack
            
            if viewController.responds(to: #selector(naviBarPopItemStyle)) {
                itemStyle = viewController.naviBarPopItemStyle()
            }
            let popItem = UIBarButtonItem.barButtomItem(title: nil, selectedTitle: nil, titleColor: nil, selectedColor: nil, image: itemStyle == PopItemStyle.PopItemBlack ? "btn_back_black" : "btn_back_white" , selectedImg: nil, target: viewController, selecter: #selector(popToPreviousVC))
            viewController.navigationItem.leftBarButtonItem = popItem
        }
        super .pushViewController(viewController, animated: true)
    }
//    override func popViewController(animated: Bool) -> UIViewController? {
//        return super .popViewController(animated: animated)
//    }
}

extension MQBaseNavigationViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if viewControllers.count > 1 {
            return true
        }
        return false
    }
}
