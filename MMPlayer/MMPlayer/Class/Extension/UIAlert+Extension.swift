//
//  UIAlert+Extension.swift
//  MMQRCode
//
//  Created by yangjie on 2019/7/26.
//  Copyright © 2019 yangjie. All rights reserved.
//

import UIKit

extension UIAlertController {
    class func alert(title: String?, content: String?, confirmTitle: String?, confirmHandler: ((UIAlertAction) -> Void)? = nil, cancelTitle: String?, cancelHandler: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {
        let alertC = UIAlertController(title: title, message: content, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: confirmTitle ?? "确定", style: .default) { (action: UIAlertAction) in
            guard let confirm = confirmHandler else {
                return
            }
            confirm(action)
        }
        let cancelAction = UIAlertAction(title: cancelTitle ?? "取消", style: .cancel) { (action: UIAlertAction) in
            guard let cancel = cancelHandler else {
                return
            }
            cancel(action)
        }
        alertC.addAction(confirmAction)
        alertC.addAction(cancelAction)
        return alertC
    }
    
    class func alertOnlyConfirm(title: String?, content: String?, confirmTitle: String?, confirmHandler: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {
        let alertC = UIAlertController(title: title, message: content, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: confirmTitle ?? "确定", style: .default) { (action: UIAlertAction) in
            guard let confirm = confirmHandler else {
                return
            }
            confirm(action)
        }
        alertC.addAction(confirmAction)
        return alertC
    }
}
