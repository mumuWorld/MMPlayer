//
//  UIBarButtonItem+MM_Extension.swift
//  MMQRCode
//
//  Created by yangjie on 2019/7/26.
//  Copyright © 2019 yangjie. All rights reserved.
//

import UIKit

extension UIBarButtonItem {
    class func barButtomItem(title: String?, selectedTitle: String?, titleColor: UIColor?, selectedColor: UIColor?, image: String?, selectedImg: String?, target: Any?, selecter: Selector?, tag: UInt = 10) -> UIBarButtonItem {
        let button = UIButton.buttonWith(title: title, selectedTitle: selectedTitle, titleColor: titleColor, selectedColor: selectedColor, image: image, selectedImg: selectedImg, target: target, selecter: selecter, tag: tag)
        button.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        let item = UIBarButtonItem(customView: button)
        return item
    }
}
