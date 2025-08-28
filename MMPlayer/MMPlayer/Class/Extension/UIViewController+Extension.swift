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

import UIKit

extension UIViewController {
    
    /// 推入导航栈，如果没有 navigationController 就 modally present
    func pushOrPresent(_ vc: UIViewController, animated: Bool = true) {
        if let nav = self.navigationController {
            nav.pushViewController(vc, animated: animated)
        } else {
            let navController = UINavigationController(rootViewController: vc)
            self.present(navController, animated: animated, completion: nil)
        }
    }
    
    /// 获取当前最顶层可见的 UIViewController
    static var currentViewController: UIViewController? {
        guard let rootVC = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive })?
                .windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }
        return getTopViewController(rootVC)
    }
    
    private static func getTopViewController(_ vc: UIViewController) -> UIViewController {
        if let nav = vc as? UINavigationController {
            return getTopViewController(nav.visibleViewController ?? nav)
        } else if let tab = vc as? UITabBarController {
            return getTopViewController(tab.selectedViewController ?? tab)
        } else if let presented = vc.presentedViewController {
            return getTopViewController(presented)
        } else {
            return vc
        }
    }
}
