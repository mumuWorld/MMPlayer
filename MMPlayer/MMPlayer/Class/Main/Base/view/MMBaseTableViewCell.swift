//
//  MMBaseTableViewCell.swift
//  MMPlayer
//
//  Created by mumu on 2020/5/8.
//  Copyright © 2020 Mumu. All rights reserved.
//

import UIKit
import SnapKit

class MMBaseTableViewCell: UITableViewCell {
    
    lazy var botLineView: UIView = {
        let layer = UIView()
        layer.backgroundColor = UIColor.lightGray
        return layer
    }()
    
    
    /// 🐷: top是高度
    var botLineEdgeinsets: UIEdgeInsets = UIEdgeInsets.zero {
        willSet {
            botLineView.snp.remakeConstraints { (make) in
                make.left.equalToSuperview().offset(newValue.left)
                make.right.equalToSuperview().offset(-newValue.right)
                make.bottom.equalToSuperview().offset(newValue.bottom)
                make.height.equalTo(newValue.top)
            }
        }
    }
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initSubviews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initSubviews()
    }
    
    func initSubviews() -> Void {
        contentView.addSubview(self.botLineView)
        botLineEdgeinsets = UIEdgeInsets.zero
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
