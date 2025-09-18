//
//  MMBaseViewController.swift
//  MMQRCode
//
//  Created by yangjie on 2019/7/25.
//  Copyright © 2019 yangjie. All rights reserved.
//

import UIKit

// MARK: - 导航栏按钮配置结构
struct BarItemConfiguration {
    let image: String?
    let selectedImage: String?
    let title: String?
    let selectedTitle: String?
    let titleColor: UIColor?
    let selectedColor: UIColor?
    let tag: Int
    
    init(image: String? = nil,
         selectedImage: String? = nil,
         title: String? = nil,
         selectedTitle: String? = nil,
         titleColor: UIColor? = nil,
         selectedColor: UIColor? = nil,
         tag: Int = 0) {
        self.image = image
        self.selectedImage = selectedImage
        self.title = title
        self.selectedTitle = selectedTitle
        self.titleColor = titleColor
        self.selectedColor = selectedColor
        self.tag = tag
    }
    
    func createBarButtonItem(target: Any?, action: Selector) -> UIBarButtonItem? {
        return UIBarButtonItem.barButtomItem(
            title: title,
            selectedTitle: selectedTitle,
            titleColor: titleColor,
            selectedColor: selectedColor,
            image: image,
            selectedImg: selectedImage,
            target: target,
            selecter: action,
            tag: UInt(tag)
        )
    }
}

class MMBaseViewController: UIViewController {

    // 可被子类重写的左侧按钮配置
    lazy var leftBarItem: UIBarButtonItem? = {
        return createLeftBarItem()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupNavigationBar()
    }
    
    // MARK: - 导航栏配置方法，子类可重写
    
    /// 创建左侧按钮，子类可重写此方法自定义按钮
    @objc open func createLeftBarItem() -> UIBarButtonItem? {
        return leftBarItemConfiguration().createBarButtonItem(target: self, action: #selector(handleLeftBarItemClick))
    }
    
    /// 左侧按钮配置，子类可重写
    open func leftBarItemConfiguration() -> BarItemConfiguration {
        return BarItemConfiguration(
            image: "btn_back_black",
            selectedImage: nil,
            title: nil,
            tag: 10
        )
    }
    
    /// 设置导航栏
    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = leftBarItem
    }
    
    /// 左侧按钮点击事件，子类可重写
    @objc open func handleLeftBarItemClick() {
        handleBtnClick(sender: UIButton())
    }
    
    @objc func handleBtnClick(sender: UIButton) {
        MMPrintLog(message :sender)
        navigationController?.popViewController(animated: true)
    }
}

extension UIViewController {
    @objc enum PopItemStyle:Int {
        case PopItemBlack = 0,PopItemWhite
    }
    
    @objc func naviBarPopItemStyle() -> PopItemStyle {
        return .PopItemBlack
    }
    
    @objc func popToPreviousVC() {
        if self.navigationController != nil {
            self.navigationController?.popViewController(animated: true)
        }
    }
}
