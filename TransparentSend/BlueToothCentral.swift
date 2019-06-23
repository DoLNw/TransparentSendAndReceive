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
    
    
    
    
    static var writeServiceNum = 0
    static var writeCharNum = 0
    static var readServiceNum = 0
    static var readCharNum = 0
    static var notifyServiceNum = 0
    static var notifyCharNum = 0
}
