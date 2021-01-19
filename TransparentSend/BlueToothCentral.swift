//
//  BlueToothCentral.swift
//  TransparentSend
//
//  Created by JiaCheng on 2018/12/15.
//  Copyright © 2018 JiaCheng. All rights reserved.
//

import Foundation
import CoreBluetooth

class BlueToothCentral {
    //MARK: - Property
    static var peripherals = [String]()
    static var peripheralIDs = [CBPeripheral]()
    static var isBlueOn = false
    static var isFirstPer = false
    static var centralManager: CBCentralManager!
    static var peripheral: CBPeripheral!
    
    static var characteristic: CBCharacteristic!   //写
    static var notifyCharacteristic: CBCharacteristic!
    static var readCharacteristic: CBCharacteristic!
    static var characteristics = [CBService: [CBCharacteristic]]()
    static var services = [CBService]()
    
    
    // 存的时候是存的没有0的，用的时候都是-1来提取
    // 0 代表当前该写、读取、通知特征还没有
    static var writeServiceNum = 0
    static var writeCharNum = 0
    static var readServiceNum = 0
    static var readCharNum = 0
    static var notifyServiceNum = 0
    static var notifyCharNum = 0
}
