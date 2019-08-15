//
//  UIKit+Extension.swift
//  Swift_SweetSugar
//
//  Created by mumu on 2019/4/1.
//  Copyright © 2019年 Mumu. All rights reserved.
//

import UIKit

extension UIView {
    
    /// x
    var mm_x: CGFloat {
        get {
            return frame.origin.x
        }
        set(newValue) {
            var tempFrame: CGRect = frame
            tempFrame.origin.x    = newValue
            frame                 = tempFrame
        }
    }
    
    /// y
    var mm_y: CGFloat {
        get {
            return frame.origin.y
        }
        set(newValue) {
            var tempFrame: CGRect = frame
            tempFrame.origin.y    = newValue
            frame                 = tempFrame
        }
    }
    
    /// height
    var mm_height: CGFloat {
        get {
            return frame.size.height
        }
        set(newValue) {
            var tempFrame: CGRect = frame
            tempFrame.size.height = newValue
            frame                 = tempFrame
        }
    }
    
    /// width
    var mm_width: CGFloat {
        get {
            return frame.size.width
        }
        set(newValue) {
            var tempFrame: CGRect = frame
            tempFrame.size.width = newValue
            frame = tempFrame
        }
    }
    
    /// size
    var mm_size: CGSize {
        get {
            return frame.size
        }
        set(newValue) {
            var tempFrame: CGRect = frame
            tempFrame.size = newValue
            frame = tempFrame
        }
    }
    
    /// centerX
    var mm_centerX: CGFloat {
        get {
            return center.x
        }
        set(newValue) {
            var tempCenter: CGPoint = center
            tempCenter.x = newValue
            center = tempCenter
        }
    }
    
    /// centerY
    var mm_centerY: CGFloat {
        get {
            return center.y
        }
        set(newValue) {
            var tempCenter: CGPoint = center
            tempCenter.y = newValue
            center = tempCenter;
        }
    }
}

extension CGRect {
    var mm_y: CGFloat {
        get {
            return self.origin.y
        }
        set {
            origin.y = newValue
        }
    }
    var mm_x: CGFloat {
        get {
            return self.origin.x
        }
        set {
            origin.x = newValue
        }
    }
    var mm_height: CGFloat {
        get {
            return self.size.height
        }
        set {
            size.height = newValue
        }
    }
    var mm_width: CGFloat {
        get {
            return self.size.width
        }
        set {
            size.width = newValue
        }
    }
}

extension UIButton {
    class func buttonWith(title: String?, selectedTitle: String?, titleColor: UIColor?, selectedColor: UIColor?, image: String?, selectedImg: String?, target: Any?, selecter: Selector?, tag: UInt = 10) ->UIButton {
        let button = UIButton(type: .custom)
        if let tmpTit = title {
            button .setTitle(tmpTit, for: .normal)
            if let tmpColor = titleColor {
                button.setTitleColor(tmpColor, for: .normal)
            }
        }
        if let tmpTit = selectedTitle {
            if let tmpColor = selectedColor {
                button.setTitleColor(tmpColor, for: .selected)
            }
            button .setTitle(tmpTit, for: .selected)
        }
        if let tmpImg = image {
            button.setImage(UIImage.init(named: tmpImg), for: .normal)
        }
        if let tmpImg = selectedImg {
            button.setImage(UIImage.init(named: tmpImg), for: .selected)
        }
        if let tmpTarget = target,let tmpSel = selecter {
            button.addTarget(tmpTarget, action: tmpSel, for: .touchUpInside)
        }
        button.tag = Int(bitPattern: tag)
        return button
    }
}

extension UILabel {
    class func labelWith(title: String?, titleColor: UIColor?, font: UIFont?, alignment: NSTextAlignment = NSTextAlignment.left) -> UILabel {
        let label = UILabel(frame: CGRect.zero)
        if let titleT = title {
            label.text = titleT
        }
        if let colorT = titleColor {
            label.textColor = colorT
        }
        if let fontT = font {
            label.font = fontT
        }
        label.textAlignment = alignment
        label.sizeToFit()
        return label
    }
}

extension UITableView {
    class func tableViewWith(type: UITableView.Style = UITableView.Style.plain,nibCells: Array<String>?, classCells: Array<String>?, delegate: Any?, frame: CGRect = CGRect.zero) -> UITableView {
        let tableView = UITableView(frame: frame, style: type)
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        if let nibArray = nibCells,nibArray.count > 0 {
            for cellStr in nibArray {
                tableView.register(UINib(nibName: cellStr, bundle: nil), forCellReuseIdentifier: cellStr)
            }
        }
        if let classArray = classCells,classArray.count > 0 {
            for cellStr in classArray {
                tableView.register(NSClassFromString(cellStr), forCellReuseIdentifier: cellStr)
            }
        }
        if let data = delegate {
            tableView.delegate = data as! UITableViewDelegate
            tableView.dataSource = data as! UITableViewDataSource
        }
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        return tableView
    }
}
