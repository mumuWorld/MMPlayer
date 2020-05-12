//
//  String+MM_Extension.swift
//  MMPlayer
//
//  Created by mumu on 2020/5/12.
//  Copyright © 2020 Mumu. All rights reserved.
//

import Foundation

extension String {
    func appendPathComponent(string: String) -> String {
        if self.last == "/" {
            return self + string
        }
        return self + "/" + string
    }
}
