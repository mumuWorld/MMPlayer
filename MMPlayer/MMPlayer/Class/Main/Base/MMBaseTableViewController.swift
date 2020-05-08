//
//  MMBaseTableViewController.swift
//  MMPlayer
//
//  Created by mumu on 2020/2/1.
//  Copyright © 2020 Mumu. All rights reserved.
//

import UIKit

let MMEmptyCellIdentify = "MMEmptyCellIdentify"

class MMBaseTableViewController: MQBaseViewController {
    
    lazy var tableview: UITableView = {
        let table = UITableView(frame: CGRect.zero, style: UITableView.Style.plain)
        table.delegate = self
        table.dataSource = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: MMEmptyCellIdentify)
        return table
    }()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        tableview.frame = view.bounds
        self.view.addSubview(tableview)
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

extension MMBaseTableViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MMEmptyCellIdentify, for: indexPath)
        return cell
    }
}
