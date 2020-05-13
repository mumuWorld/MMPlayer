//
//  MMToastView.swift
//  MMQRCode
//
//  Created by yangjie on 2019/8/2.
//  Copyright © 2019 yangjie. All rights reserved.
//

import UIKit

enum MMToastPostion {
    case Center,Bottom,Top
}
class MMToastView: UIView {
    
    class func show(message: String, deadTime: CGFloat = 1.0, position: MMToastPostion = MMToastPostion.Center) -> Void {
        let textLabel = UILabel.labelWith(title: message, titleColor: UIColor.white, font: UIFont.systemFont(ofSize: 14), alignment: NSTextAlignment.center)
        textLabel.numberOfLines = 0
        let maxWidth = MQScreenWidth - 40 - 20;
        let fitSize = message.boundingRect(with: CGSize(width: maxWidth, height: CGFloat(MAXFLOAT)), options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14)], context: nil).size
        
        let containerView:MMToastView? = MMToastView(frame: CGRect.zero)
        containerView?.layer.cornerRadius = 4
        guard let toastView = containerView else {
            return
        }
        toastView.backgroundColor = UIColor.mm_colorFromHex(color_vaule: 0x000000, alpha: 0.67)
        //设置frame
        toastView.mm_width = min(maxWidth + 20, fitSize.width + 20)
        toastView.mm_height = fitSize.height + 20
        if position == .Center {
            toastView.mm_centerX = MQScreenWidth * 0.5
            toastView.mm_centerY = MQScreenHeight * 0.5
        } else if position == .Bottom {
            
        }
        textLabel.mm_size = fitSize
        textLabel.mm_x = 10
        textLabel.mm_y = 10
        toastView.addSubview(textLabel)
        let mainWindow = UIApplication.shared.delegate?.window
        guard let tWindow = mainWindow else {
            MPErrorLog(message: "没有找到主窗口")
            return
        }
        tWindow!.checkSubViewRemove(checkViewStr: "MQToastView")
        tWindow?.addSubview(toastView)
        toastView.alpha = 0.2
        UIView.animate(withDuration: 0.25) {
            toastView.alpha = 1
        }
        let deadline = DispatchTime.secondTime(value: Double(deadTime))
        DispatchQueue.main.asyncAfter(deadline: deadline) {
            UIView.animate(withDuration: 0.2, animations: {
                if containerView != nil {
                    toastView.alpha = 0
                }
            }, completion: { (_) in
                if containerView != nil {
                    toastView.removeFromSuperview()
                }
            })
        }
    }
    
}
