//
//  MMTopBottomTVCell.swift
//  MMPlayer
//
//  Created by mumu on 2020/5/8.
//  Copyright © 2020 Mumu. All rights reserved.
//

import UIKit

class MMTopBottomTVCell: MMBaseTableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var detailLabel: UILabel!
    
    @IBOutlet weak var arrowImg: UIImageView!
    
    var itemModel: MMFileItem? {
        willSet {
            guard let item = newValue else {
                return
            }
            nameLabel.text = item.name
            var size = item.size
            var sizeType = "bt"
            if item.size > 1024 {
               size =  item.size / 1024
                sizeType = "kb"
                if (size > 1024) {
                    size = size / 1024
                    sizeType = "M"
                    if size > 1024 {
                        size = size / 1024
                        sizeType = "G"
                    }
                }
            }
            
            detailLabel.text = item.modificationDateStr + "  \(size)\(sizeType)"
            arrowImg.isHidden = item.type != .directory
        }
    }
    

    override func awakeFromNib() {
        super.awakeFromNib()
        botLineEdgeinsets = UIEdgeInsets(top: 1, left: 0, bottom: 0, right: 0)
        //长按手势
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleGesture(sender:)))
        self.contentView.addGestureRecognizer(longPress)
    }

    @objc func handleGesture(sender: UILongPressGestureRecognizer) {
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}

extension MMTopBottomTVCell: CellProtocol {
    static var reuseID: String {
        return NSStringFromClass(MMTopBottomTVCell.self)
    }
    
    static var nib: UINib {
        return UINib.init(nibName: reuseID, bundle: nil)
    }
    
    static var className: String {
        return NSStringFromClass(MMTopBottomTVCell.self)
    }
    
    
}
