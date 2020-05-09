//
//  UITableView+Extension.swift
//  MMPlayer
//
//  Created by mumu on 2020/5/9.
//  Copyright © 2020 Mumu. All rights reserved.
//

import UIKit

extension UITableView {
    func mm_registerNibCell<T: UITableViewCell>(classType: T.Type)  {
        let name = String(describing: classType)
        let nib = UINib(nibName: name, bundle: nil)
        register(nib, forCellReuseIdentifier: name)
    }
    
    func mm_registerClassCell<T: UITableViewCell>(classType: T.Type)  {
        let name = String(describing: classType)
        register(classType, forCellReuseIdentifier: name)
        
    }
    
    func mm_dequeueReusableCell<T: UITableViewCell>(classType: T.Type,indexPath: IndexPath) -> T {
        let name = String(describing: classType)
        guard let cell = dequeueReusableCell(withIdentifier: name) as? T else {
            fatalError("\(name) is not registed")
        }
        return cell
    }
}

