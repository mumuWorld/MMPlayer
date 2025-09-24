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
    
    // 当前选中的文件项
    private var selectedFileItem: MMFileItem?
    private var selectedIndexPath: IndexPath?

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
            if let receivedPath = MMFileManager.appGroupReceivedPath, let receivedItem = MMFileManager.getPathProperty(path: receivedPath) {
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
    
    // MARK: - 长按处理
    func handleLongPress(at indexPath: IndexPath) {
        let item = dataArray[indexPath.row]
        
        // 不对"我收到的文件"目录进行操作
        if item.name == "我收到的文件" {
            return
        }
        
        selectedFileItem = item
        selectedIndexPath = indexPath
        
        showActionSheet()
    }
    
    // MARK: - 底部工具条
    private func showActionSheet() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // 移动
        let moveAction = UIAlertAction(title: "移动", style: .default) { [weak self] _ in
            self?.moveFile()
        }
        
        // 删除
        let deleteAction = UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            self?.deleteFile()
        }
        
        // More
        let moreAction = UIAlertAction(title: "更多", style: .default) { [weak self] _ in
            self?.showMoreOptions()
        }
        
        // 取消
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        
        alertController.addAction(moveAction)
        alertController.addAction(deleteAction)
        alertController.addAction(moreAction)
        alertController.addAction(cancelAction)
        
        // iPad适配
        if let popover = alertController.popoverPresentationController {
            if let selectedIndexPath = selectedIndexPath,
               let cell = tableview.cellForRow(at: selectedIndexPath) {
                popover.sourceView = cell
                popover.sourceRect = cell.bounds
            }
        }
        
        present(alertController, animated: true)
    }
    
    // MARK: - 文件重命名
    private func renameFile() {
        guard let item = selectedFileItem else { return }
        
        let alertController = UIAlertController(
            title: "修改文件名",
            message: "请输入新的文件名",
            preferredStyle: .alert
        )
        
        alertController.addTextField { textField in
            textField.text = item.name
            textField.placeholder = "文件名"
        }
        
        let confirmAction = UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            guard let newName = alertController.textFields?.first?.text,
                  !newName.isEmpty else {
                MMToastView.show(message: "文件名不能为空")
                return
            }
            self?.performRenameFile(newName: newName)
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
    
    private func performRenameFile(newName: String) {
        guard let item = selectedFileItem,
              let indexPath = selectedIndexPath else { return }
        
        let fileManager = FileManager.default
        let oldPath = item.path
        let parentPath = (oldPath as NSString).deletingLastPathComponent
        let newPath = parentPath.appendPathComponent(string: newName)
        
        // 检查新文件名是否已存在
        if fileManager.fileExists(atPath: newPath) {
            MMToastView.show(message: "文件名已存在")
            return
        }
        
        do {
            try fileManager.moveItem(atPath: oldPath, toPath: newPath)
            
            // 更新数据源
            item.name = newName
            item.path = newPath
            
            // 更新UI
            tableview.reloadRows(at: [indexPath], with: .none)
            
            // 显示成功提示
            MMToastView.show(message: "重命名成功")
            
        } catch {
            MMErrorLog(message: "重命名文件失败: \(error)")
            MMToastView.show(message: "重命名失败: \(error.localizedDescription)")
        }
        
        // 清空选中状态
        selectedFileItem = nil
        selectedIndexPath = nil
    }
    
    // MARK: - 其他app打开文件
    private func openWithOtherApps() {
        guard let item = selectedFileItem else { return }
        
        let fileURL = URL(fileURLWithPath: item.path)
        
        // 检查文件是否存在
        guard FileManager.default.fileExists(atPath: item.path) else {
            MMToastView.show(message: "文件不存在")
            return
        }
        
        // 创建文档交互控制器
        let documentController = UIDocumentInteractionController(url: fileURL)
        documentController.delegate = self
        
        // 尝试显示选项菜单
        if documentController.presentOptionsMenu(from: view.bounds, in: view, animated: true) {
            // 成功显示选项菜单
        } else {
            // 如果没有可用的应用，显示提示
            MMToastView.show(message: "没有可用的应用打开此文件")
        }
        
        // 清空选中状态
        selectedFileItem = nil
        selectedIndexPath = nil
    }
    
    // MARK: - 文件详情
    private func showFileDetails() {
        guard let item = selectedFileItem else { return }
        
        let fileManager = FileManager.default
        let filePath = item.path
        
        // 获取文件属性
        var fileSize: String = "未知"
        var modificationDate: String = "未知"
        var permissions: String = "未知"
        var fileType: String = "未知"
        
        do {
            let attributes = try fileManager.attributesOfItem(atPath: filePath)
            
            // 文件大小
            if let size = attributes[.size] as? Int64 {
                fileSize = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
            }
            
            // 修改时间
            if let date = attributes[.modificationDate] as? Date {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .medium
                formatter.locale = Locale(identifier: "zh_CN")
                modificationDate = formatter.string(from: date)
            }
            
            // 权限
            if let posixPermissions = attributes[.posixPermissions] as? Int {
                permissions = String(format: "%o", posixPermissions)
            }
            
            // 文件类型
            if let type = attributes[.type] as? FileAttributeType {
                switch type {
                case .typeRegular:
                    fileType = "普通文件"
                case .typeDirectory:
                    fileType = "文件夹"
                case .typeSymbolicLink:
                    fileType = "符号链接"
                default:
                    fileType = "其他"
                }
            }
            
        } catch {
            MMErrorLog(message: "获取文件属性失败: \(error)")
        }
        
        // 创建详情弹框
        let alertController = UIAlertController(
            title: "文件详情",
            message: nil,
            preferredStyle: .alert
        )
        
        let detailsMessage = """
        文件名: \(item.name)
        
        位置: \(filePath)
        
        大小: \(fileSize)
        
        修改时间: \(modificationDate)
        
        权限: \(permissions)
        
        类型: \(fileType)
        """
        
        alertController.message = detailsMessage
        
        let closeAction = UIAlertAction(title: "关闭", style: .default)
        alertController.addAction(closeAction)
        
        present(alertController, animated: true)
        
        // 清空选中状态
        selectedFileItem = nil
        selectedIndexPath = nil
    }
    
    // MARK: - 文件操作
    private func deleteFile() {
        guard let item = selectedFileItem else { return }
        
        let alertController = UIAlertController(
            title: "删除文件",
            message: "确定要删除 \"\(item.name)\" 吗？此操作不可恢复。",
            preferredStyle: .alert
        )
        
        let deleteAction = UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            self?.performDeleteFile()
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
    
    private func performDeleteFile() {
        guard let item = selectedFileItem,
              let indexPath = selectedIndexPath else { return }
        
        let fileManager = FileManager.default
        
        do {
            try fileManager.removeItem(atPath: item.path)
            
            // 从数据源中移除
            dataArray.remove(at: indexPath.row)
            
            // 更新UI
            tableview.deleteRows(at: [indexPath], with: .fade)
            
            // 显示成功提示
            MMToastView.show(message: "删除成功")
            
        } catch {
            MMErrorLog(message: "删除文件失败: \(error)")
            MMToastView.show(message: "删除失败: \(error.localizedDescription)")
        }
        
        // 清空选中状态
        selectedFileItem = nil
        selectedIndexPath = nil
    }
 // MARK: - 移动文件
    private func moveFile() {
        guard let item = selectedFileItem else { return }
        
        // 创建目标路径选择器
        let alertController = UIAlertController(
            title: "移动文件",
            message: "选择目标位置",
            preferredStyle: .actionSheet
        )
        
        // 添加常用目录选项
        let documentsAction = UIAlertAction(title: "Documents", style: .default) { [weak self] _ in
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            self?.performMoveFile(to: documentsPath)
        }
        
        let cachesAction = UIAlertAction(title: "Caches", style: .default) { [weak self] _ in
            let cachesPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
            self?.performMoveFile(to: cachesPath)
        }
        
        let receivedAction = UIAlertAction(title: "我收到的文件", style: .default) { [weak self] _ in
            self?.performMoveFile(to: MMFileManager.appGroupReceivedPath)
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel) { [weak self] _ in
            self?.selectedFileItem = nil
            self?.selectedIndexPath = nil
        }
        
        alertController.addAction(documentsAction)
        alertController.addAction(cachesAction)
        alertController.addAction(receivedAction)
        alertController.addAction(cancelAction)
        
        // iPad适配
        if let popover = alertController.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = view.bounds
        }
        
        present(alertController, animated: true)
    }
    
    private func performMoveFile(to destinationPath: String) {
        guard let item = selectedFileItem,
              let indexPath = selectedIndexPath else { return }
        
        let fileManager = FileManager.default
        let fileName = item.name
        let sourcePath = item.path
        let targetPath = destinationPath.appendPathComponent(string: fileName)
        
        // 检查目标路径是否已存在同名文件
        if fileManager.fileExists(atPath: targetPath) {
            MMToastView.show(message: "目标位置已存在同名文件")
            return
        }
        
        // 确保目标目录存在
        if !fileManager.fileExists(atPath: destinationPath) {
            do {
                try fileManager.createDirectory(atPath: destinationPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                MMErrorLog(message: "创建目标目录失败: \(error)")
                MMToastView.show(message: "移动失败: 无法创建目标目录")
                return
            }
        }
        
        do {
            try fileManager.moveItem(atPath: sourcePath, toPath: targetPath)
            
            // 从当前数据源中移除
            dataArray.remove(at: indexPath.row)
            
            // 更新UI
            tableview.deleteRows(at: [indexPath], with: .fade)
            
            // 显示成功提示
            MMToastView.show(message: "移动成功")
            
        } catch {
            MMErrorLog(message: "移动文件失败: \(error)")
            MMToastView.show(message: "移动失败: \(error.localizedDescription)")
        }
        
        // 清空选中状态
        selectedFileItem = nil
        selectedIndexPath = nil
    }
    
    // MARK: - More选项
    private func showMoreOptions() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // 修改文件名
        let renameAction = UIAlertAction(title: "修改文件名", style: .default) { [weak self] _ in
            self?.renameFile()
        }
        
        // 查看文件详情
        let detailAction = UIAlertAction(title: "查看文件详情", style: .default) { [weak self] _ in
            self?.showFileDetail()
        }
        
        // 其他app打开
        let openWithAction = UIAlertAction(title: "其他app打开", style: .default) { [weak self] _ in
            self?.openWithOtherApp()
        }
        
        // 取消
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        
        alertController.addAction(renameAction)
        alertController.addAction(detailAction)
        alertController.addAction(openWithAction)
        alertController.addAction(cancelAction)
        
        // iPad适配
        if let popover = alertController.popoverPresentationController {
            if let selectedIndexPath = selectedIndexPath,
               let cell = tableview.cellForRow(at: selectedIndexPath) {
                popover.sourceView = cell
                popover.sourceRect = cell.bounds
            }
        }
        
        present(alertController, animated: true)
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
        MMPrintLog(message: indexPath )
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = self.dataArray[indexPath.row]
        if item.type == .directory {
            var path: String
            
            // 特殊处理"我收到的文件"
            if item.name == "我收到的文件" {
                path = MMFileManager.appGroupReceivedPath ?? ""
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

// MARK: - UIDocumentInteractionControllerDelegate
extension MMSandboxVC: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
    
    func documentInteractionControllerViewForPreview(_ controller: UIDocumentInteractionController) -> UIView? {
        return view
    }
    
    func documentInteractionControllerRectForPreview(_ controller: UIDocumentInteractionController) -> CGRect {
        return view.bounds
    }
}
