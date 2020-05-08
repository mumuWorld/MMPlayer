//
//  MQTabbarController.swift
//  MMQRCode
//
//  Created by yangjie on 2019/7/25.
//  Copyright © 2019 yangjie. All rights reserved.
//

import UIKit

class MQTabbarController: UITabBarController {
//    var homeVC :MQHomeVC?
    override func viewDidLoad() {
        super.viewDidLoad()
//        homeVC = UIStoryboard(name: "MQHome", bundle: nil).instantiateViewController(withIdentifier: "homeVC") as? MQHomeVC
//        guard let home = homeVC else {
//            return;
//        }
        let home = MMHomeViewController()
        let homeNavi = MQBaseNavigationViewController(rootViewController: home)
        home.title = "MMPlayer"
        addChild(homeNavi)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
