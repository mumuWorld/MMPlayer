//
//  CellProtorol.swift
//  MMPlayer
//
//  Created by mumu on 2020/5/9.
//  Copyright © 2020 Mumu. All rights reserved.
//

import UIKit

protocol CellProtocol {
    static var reuseID: String { get }
    static var nib: UINib { get }
    static var className: String { get }
}
