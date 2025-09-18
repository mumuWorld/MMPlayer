//
//  MMVideoPlayerSettingsViewController.swift
//  MMPlayer
//
//  Created by yangjie on 2025/9/17.
//  Copyright © 2025 Mumu. All rights reserved.
//

import UIKit
import SnapKit

class MMVideoPlayerSettingsViewController: MMBaseViewController {
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.systemGroupedBackground
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DetailCell")
        return tableView
    }()
    
    private let seekTimeOptions = MMVideoPlayerSettings.seekTimeOptions
    private var currentSeekTime: Double {
        return MMVideoPlayerSettings.shared.seekTime
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        title = "播放器设置"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 确保设置页面的右滑返回手势正常工作
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }
    
    override func naviBarPopItemStyle() -> PopItemStyle {
        return .PopItemBlack
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemGroupedBackground
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension MMVideoPlayerSettingsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1 // 控制条常驻设置
        case 1:
            return 1 // 快进快退时间设置（改为单行）
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "界面设置"
        case 1:
            return "快进/快退时间设置"
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0:
            return "开启后控制条将始终显示；关闭后播放时控制条会自动隐藏，点击屏幕或交互时显示"
        case 1:
            return "使用左右箭头键进行快进和快退操作"
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            // 控制条常驻设置
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            cell.textLabel?.text = "控制条常驻显示"
            cell.selectionStyle = .none
            
            // 添加开关控件
            let switchControl = UISwitch()
            switchControl.isOn = MMVideoPlayerSettings.shared.controlsAlwaysVisible
            switchControl.addTarget(self, action: #selector(controlsAlwaysVisibleSwitchChanged(_:)), for: .valueChanged)
            cell.accessoryView = switchControl
            cell.backgroundColor = UIColor.systemBackground
            return cell
            
        case 1:
            // 快进快退时间设置（改为单行显示）
            let cell = UITableViewCell(style: .value1, reuseIdentifier: "DetailCell")
            cell.textLabel?.text = "快进/快退时间"
            cell.detailTextLabel?.text = MMVideoPlayerSettings.shared.formatSeekTime(currentSeekTime)
            cell.selectionStyle = .default
            cell.accessoryType = .disclosureIndicator
            cell.backgroundColor = UIColor.systemBackground
            return cell
            
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // 只处理快进快退时间设置（第二个section）
        guard indexPath.section == 1 else { return }
        
        // 弹出选择框
        showSeekTimeSelectionAlert()
    }
    
    @objc private func controlsAlwaysVisibleSwitchChanged(_ sender: UISwitch) {
        // 保存设置
        MMVideoPlayerSettings.shared.controlsAlwaysVisible = sender.isOn
        
        // 发送通知给当前播放的视频更新状态
        NotificationCenter.default.post(name: NSNotification.Name("MMVideoControlsVisibilityChanged"), object: nil)
        
        // 显示保存成功提示
        let message = sender.isOn ? "控制条将始终显示" : "控制条将在播放时自动隐藏"
        showSettingSavedAlert(message: message)
    }
    
    private func showSaveSuccessAlert(seekTime: Double) {
        let timeString = MMVideoPlayerSettings.shared.formatSeekTime(seekTime)
        let alert = UIAlertController(
            title: "设置已保存",
            message: "快进/快退时间已设置为 \(timeString)",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    private func showSeekTimeSelectionAlert() {
        let alert = UIAlertController(
            title: "快进/快退时间设置",
            message: "选择每次快进或快退的时间",
            preferredStyle: .actionSheet
        )
        
        // 添加时间选项
        for seekTime in seekTimeOptions {
            let timeString = MMVideoPlayerSettings.shared.formatSeekTime(seekTime)
            let isSelected = seekTime == currentSeekTime
            let title = isSelected ? "\(timeString) ✓" : timeString
            
            let action = UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.selectSeekTime(seekTime)
            }
            
            // 当前选中项使用不同颜色
            if isSelected {
                action.setValue(UIColor.systemBlue, forKey: "titleTextColor")
            }
            
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        // iPad适配
        if let popover = alert.popoverPresentationController {
            popover.sourceView = tableView
            popover.sourceRect = tableView.rectForRow(at: IndexPath(row: 0, section: 1))
        }
        
        present(alert, animated: true)
    }
    
    private func selectSeekTime(_ seekTime: Double) {
        // 保存设置
        MMVideoPlayerSettings.shared.seekTime = seekTime
        
        // 刷新表格以更新显示的值
        tableView.reloadData()
        
        // 显示保存成功提示
        showSaveSuccessAlert(seekTime: seekTime)
    }
    
    private func showSettingSavedAlert(message: String) {
        let alert = UIAlertController(
            title: "设置已保存",
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}