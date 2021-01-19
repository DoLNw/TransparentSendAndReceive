//
//  PickerData.swift
//  TransparentSend
//
//  Created by JiaCheng on 2021/1/18.
//  Copyright © 2021 JiaCheng. All rights reserved.
//

import Foundation

struct PickerData {
    var services = [Int]()
    var chars = [[Int]]()
    
    init() {
        // 把什么都不选的0加上去
        self.services.append(0)
        self.chars.append([0])
    }
}




