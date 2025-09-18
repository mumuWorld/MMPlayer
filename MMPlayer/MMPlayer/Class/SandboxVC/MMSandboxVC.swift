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

    lazy var rightBarItem: UIBarButtonItem = {
        let item = UIBarButtonItem.barButtomItem(title: nil, selectedTitle: nil, titleColor: nil, selectedColor: nil, image: "navi_more", selectedImg: nil, target: self, selecter: #selector(handleRightBarItemClick(sender:)), tag: 10)
        return item
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupData ()
        initSubViews()
        let url = URL(string: currentPath)
        navigationItem.title = url?.lastPathComponent
        
        navigationItem.leftBarButtonItem = leftBarItem
    }
    
    func setupData () {
        let array = MMFileManager.getDirectorAllItems(path: currentPath)
        var newItems: [MMFileItem] = Array()
        
        // 如果是根目录，添加"我收到的文件"选项
        if currentPath == rootPath {
            if let receivedPath = MMFileManager.receivedPath, let receivedItem = MMFileManager.getPathProperty(path: receivedPath) {
                receivedItem.name = "我收到的文件"
                newItems.append(receivedItem)
            }
        }
        
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
        navigationItem.rightBarButtonItem = rightBarItem
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
    
    @objc func handleRightBarItemClick(sender: UIButton) {
        MMPrintLog(message: sender)
        
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
        MMPrintLog(message: indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = self.dataArray[indexPath.row]
        if item.type == .directory {
            var path: String
            
            // 特殊处理"我收到的文件"
            if item.name == "我收到的文件" {
                path = MMFileManager.receivedPath ?? ""
            } else {
                path = currentPath.appendPathComponent(string: item.name)
            }
            
            pushToVC(path: path)
        } else if item.type == .audio {
            let vc = MMAudioPlayerVC()
            let audio = MMAudioItem(fileItem: item)
            vc.audioItem = audio
            navigationController?.pushViewController(vc, animated: true)
        } else if item.type == .video {
            let vc = MMVideoViewController()
            let video = MMVideoItem(fileItem: item)
            vc.videoItem = video
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
}
