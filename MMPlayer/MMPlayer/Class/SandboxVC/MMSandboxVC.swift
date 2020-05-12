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
    public var _currentPath: String = ""
    public var currentPath: String {
        get {
            if _currentPath.count < 1 {
                _currentPath = rootPath
            }
            return _currentPath;
        }
        set {
            _currentPath = newValue
        }
    }
    lazy var rootPath = MMFileManager.getSandboxPath()
    
    lazy var dataArray: [MMFileItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupData ()
        initSubViews()
    }
    
    func setupData () {
        let array = MMFileManager.getDirectorAllItems(path: currentPath)
        var newItems: [MMFileItem] = Array()
        if let items = array {
            for name in items {
                let path = currentPath.appendPathComponent(string: name)
                if let item = MMFileManager.getPathProperty(path: path) {
                    item.name = name
                    newItems.append(item)
                }
            }
        }
        dataArray = newItems
    }
    
    func initSubViews() -> Void {
        tableview.separatorStyle = .none
        tableview.mm_registerNibCell(classType: MMTopBottomTVCell.self)
        tableview.reloadData();
    }
    
    func pushToVC(path: String) -> Void {
        let vc = MMSandboxVC()
//        vc.dataArray = dataArr;
        vc.currentPath = path
        navigationController?.pushViewController(vc, animated: true)
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
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = self.dataArray[indexPath.row]
        if item.type == .directory {
            let path = currentPath.appendPathComponent(string: item.name)
            pushToVC(path: path)
        } else if item.type == .audio {
            let vc = MMAudioPlayerVC()
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}
