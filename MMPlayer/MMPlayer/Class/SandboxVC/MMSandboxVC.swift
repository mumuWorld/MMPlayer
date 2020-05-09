//
//  MMSandboxVC.swift
//  MMPlayer
//
//  Created by mumu on 2020/5/8.
//  Copyright © 2020 Mumu. All rights reserved.
//

import UIKit
import SnapKit

class MMSandboxVC: MMBaseTableViewController {
    lazy var rootPath = MMFileManager.getSandboxPath()
  
    lazy var dataArray: [MMFileItem] = {
        let array = MMFileManager.getDirectorAllItems(path: rootPath)
        var newItems: [MMFileItem] = Array()
        if let items = array {
            for name in items {
                let path = rootPath.appendingFormat("/%@", name)
                if let item = MMFileManager.getPathProperty(path: path) {
                    item.name = name
                    newItems.append(item)
                }
            }
        }
        return newItems
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        initSubViews()
    }
    
    func initSubViews() -> Void {
        
        tableview.mm_registerNibCell(classType: MMTopBottomTVCell.self)
//        tableview.register(MMTopBottomTVCell.nib, forCellReuseIdentifier: MMTopBottomTVCell.reuseID)
        tableview.reloadData();
    }
}

extension MMSandboxVC {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:MMTopBottomTVCell = tableView.mm_dequeueReusableCell(classType: MMTopBottomTVCell.self, indexPath: indexPath)
        cell.itemModel = self.dataArray[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        MPPrintLog(message: indexPath)
    }
}
