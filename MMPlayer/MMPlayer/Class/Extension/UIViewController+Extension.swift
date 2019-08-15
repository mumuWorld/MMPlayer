//
//  UIViewController+Extension.swift
//  MMQRCode
//
//  Created by yangjie on 2019/7/29.
//  Copyright © 2019 yangjie. All rights reserved.
//

import UIKit

protocol MQViewLoadSubViewProtocol {
    func initSubViews() -> Void
}

extension UIViewController {
    func setNavigationBarAlpha(hideShadowImg: Bool = false) -> Void {
        if self.navigationController != nil {
            self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
            if hideShadowImg {
                self.navigationController?.navigationBar.shadowImage = UIImage()
            }
        }
    }
    
    func recoverNavigationBar(hideShadowImg: Bool = false) -> Void {
        if self.navigationController != nil {
            self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
            if hideShadowImg {
                self.navigationController?.navigationBar.shadowImage = nil
            }
        }
    }
    
    func getNaviBarBackgroundImg() -> UIImageView? {
        if self.navigationController == nil {
            return nil
        }
        
        guard let subViews = self.navigationController?.navigationBar.subviews else { return nil }
        for subView in subViews {
            let str = String(describing: type(of: subView))
            if str == "_UIBarBackground" {
                let imgV = subView.subviews.first
                return imgV as? UIImageView
            }
        }
        return nil
    }
}
