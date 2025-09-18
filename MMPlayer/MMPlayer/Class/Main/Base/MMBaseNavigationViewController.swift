//
//  MMBaseNavigationViewController.swift
//  MMQRCode
//
//  Created by yangjie on 2019/7/25.
//  Copyright © 2019 yangjie. All rights reserved.
//

import UIKit

class MMBaseNavigationViewController: UINavigationController {
    
    // 跟踪导航操作类型
    private var isPushing = false
    private var isPopping = false

    override func viewDidLoad() {
        super.viewDidLoad()
        //隐藏底部线
        self.navigationBar.shadowImage = UIImage()
        
        self.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: MQMainTitleColor]
        self.interactivePopGestureRecognizer?.delegate = self as UIGestureRecognizerDelegate
        
        // 设置自己为导航控制器的委托
        self.delegate = self
    }
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//    }
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        isPushing = true
        if viewControllers.count >= 1 {
            viewController.hidesBottomBarWhenPushed = true
//            var itemStyle = PopItemStyle.PopItemBlack
//            
//            if viewController.responds(to: #selector(naviBarPopItemStyle)) {
//                itemStyle = viewController.naviBarPopItemStyle()
//            }
//            let popItem = UIBarButtonItem.barButtomItem(title: nil, selectedTitle: nil, titleColor: nil, selectedColor: nil, image: itemStyle == PopItemStyle.PopItemBlack ? "btn_back_black" : "btn_back_white" , selectedImg: nil, target: viewController, selecter: #selector(popToPreviousVC))
//            viewController.navigationItem.leftBarButtonItem = popItem
        }
        super.pushViewController(viewController, animated: true)
    }
}

extension MMBaseNavigationViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if viewControllers.count > 1 {
            return true
        }
        return false
    }
}

// MARK: - UINavigationControllerDelegate
extension MMBaseNavigationViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {

        // 重置操作标志
        isPushing = false
        isPopping = false
    }
}
