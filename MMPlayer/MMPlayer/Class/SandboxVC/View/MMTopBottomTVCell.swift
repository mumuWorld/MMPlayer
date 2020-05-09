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
            let size = item.size / 1024
            detailLabel.text = item.modificationDateStr + "  \(size)kb"
            arrowImg.isHidden = item.type != .directory
        }
    }
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
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
