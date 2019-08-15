//
//  UIView+Extension.swift
//  MMQRCode
//
//  Created by yangjie on 2019/8/5.
//  Copyright © 2019 yangjie. All rights reserved.
//

import UIKit

extension UIView {
    func checkSubViewRemove(checkViewStr: String) -> Void {
        if self.subviews.count < 1 {
            return
        }
        for subView in self.subviews {
            let str = String(describing: type(of: subView))
            if str == checkViewStr {
                subView.removeFromSuperview()
            }
        }
    }
}
