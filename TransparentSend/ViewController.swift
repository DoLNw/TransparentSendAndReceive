//
//  ViewController.swift
//  CameraCapture1
//
//  Created by JiaCheng on 2018/10/22.
//  Copyright © 2018 JiaCheng. All rights reserved.
//

import UIKit
import AVFoundation
import CoreBluetooth

enum SendAndReceiveType: String {
    case Decimal
    case Hexadecimal
    case ASCII
    
    mutating func toggle() {
        switch self {
        case .Decimal:
            self = .Hexadecimal
        case .Hexadecimal:
            self = .ASCII
        case .ASCII:
            self = .Decimal
        }
    }
}

class ViewController: UIViewController {
    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    
    let blueToothCentral = BlueToothCentral()
    
    var writeType: CBCharacteristicWriteType?
    @IBOutlet weak var propertyTextView: UILabel!
    var propertyStr = "" {
        didSet {
            DispatchQueue.main.async { [unowned self] in
                self.propertyTextView.text = self.propertyStr
            }
        }
    }
    
    //目前服务还没有给出选择，特征还是要给出一个隐藏的数字的，为了方便。
    @IBOutlet weak var charNumSelectTextLabel: UITextField!
    @IBOutlet weak var serviceNumSelectLabel: UITextField!
    @IBAction func changeCharAndSerAct(_ sender: UIButton) {
        guard BlueToothCentral.peripheral != nil else { return }
        
        //由于之前的还在，要取消之前的通知
        if BlueToothCentral.characteristic.isNotifying {
            BlueToothCentral.peripheral.setNotifyValue(false, for: BlueToothCentral.characteristic)
        }
        BlueToothCentral.peripheral.discoverServices(nil)
        self.charNumSelectTextLabel.resignFirstResponder()
        self.serviceNumSelectLabel.resignFirstResponder()
    }
    
    
    //留了两个label本来做信号指示的，但是貌似label的background不能动画，先留一下吧。。。。
    @IBOutlet weak var sendLabel: UILabel!
    @IBOutlet weak var receiveLabel: UILabel!
    @IBOutlet weak var receiveCleraBtn: UIButton!
    @IBAction func sendClearAct(_ sender: UIButton) {
        self.sendTextView.text = ""
        self.checkSendData()
    }
    @IBAction func receiceClearAct(_ sender: UIButton) {
        self.receiveStr = ""
    }
    
    
    var receiveType = SendAndReceiveType.Hexadecimal
    @IBAction func receiveTypeAct(_ sender: UIButton) {
        receiveType.toggle()
        sender.setTitle(receiveType.rawValue, for: .normal)
    }
    var sendType = SendAndReceiveType.Hexadecimal
    @IBAction func sendTypeAct(_ sender: UIButton) {
        sendType.toggle()
        sender.setTitle(sendType.rawValue, for: .normal)
        self.checkSendData()
    }
    
    //MARK: - IBOutlet
    @IBOutlet weak var senBtn: UIButton!
    @IBOutlet weak var sendTextView: UITextView!
    
    @IBAction func sendAct(_ sender: UIButton) {
        self.sendTextView.resignFirstResponder()
        guard BlueToothCentral.characteristic != nil else {
            showErrorAlertWithTitle("Wrong", message: "Please check if you're connect.")
            return
        }
        
        //注意：有一种情况是你在发送区没有按完成直接点击发送，这样的话一个didendedit代理自动被执行按钮变红，还有这里的发送按钮actt也被执行，但是我这里数据data是nild不会被发出去的，所以字体改变这一步是不应该执行的。
        if let data = self.returnSendData() {
            if let writeType = self.writeType {
                BlueToothCentral.peripheral.writeValue(data, for: BlueToothCentral.characteristic, type: writeType)
            }
        } else {
            //刚开始点击发送还是要检查一下？其实不需要的如果刚开始启动的时候view里面没有zstring的时候
            //那下面再加一句的话如果编辑string后编辑界面还没消失直接点击发送这里检查一遍，代理didendediting也会检查一遍的。
            self.checkSendData()
            return
        }
        
        //貌似对字体动画无效,而且我也找不到别的字体的动画效果，只能背景颜色先代替一下喽?而且我发现连着写两个animate，两个会有冲突？？虽然有延时。所以改一改第二个写在completion里面而不是b串联着写下去是可以的。emmm，要不还是写成x字体突然变大再变小这样，虽然动画是没有用的。
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveEaseIn, animations: { [unowned self] in
            self.sendTextView.backgroundColor = UIColor(red: 0.196, green: 0.604, blue: 0.357, alpha: 0.25)
            }, completion: { (_) in
                //下面的delay只要写成0就可以了，因为它在上一个完成后调用。
                UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveEaseOut, animations: { [unowned self] in
                    self.sendTextView.backgroundColor = UIColor.white
                    }, completion: nil)
        })
        
        //字体以及label动画，貌似都不能动画。醉了。。
//        UIView.animate(withDuration: 3, animations: { [unowned self] in
//            self.sendTextView.font = UIFont(name: "Hiragino Maru Gothic ProN", size: 21)
//            self.sendLabel.backgroundColor = self.receiveBtn.backgroundColor
//        }) { [unowned self] (_)  in
//            UIView.animate(withDuration: 3, animations: { [unowned self] in
//                self.sendTextView.font = UIFont(name: "Hiragino Maru Gothic ProN", size: 18)
//                self.sendLabel.backgroundColor = UIColor.white
//            })
//        }
//        UIView.animate(withDuration: 3, animations: {
////            self.sendTextView.font = UIFont(name: "Hiragino Maru Gothic ProN", size: 21)
//            self.sendLabel.backgroundColor = self.receiveBtn.backgroundColor
//        }, completion: { (_) in
//            UIView.animate(withDuration: 3, animations: { [unowned self] in
////                self.sendTextView.font = UIFont(name: "Hiragino Maru Gothic ProN", size: 18)
//                self.sendLabel.backgroundColor = UIColor.white
//            })
//        })
    }
    
    @IBOutlet weak var receiveBtn: UIButton!
    @IBOutlet weak var receiveTextView: UITextView!
    var receiveStr = "" {
        didSet {
            DispatchQueue.main.async {
                self.receiveTextView.text = self.receiveStr
                self.receiveTextView.scrollRangeToVisible(NSRange(location:self.receiveTextView.text.lengthOfBytes(using: .utf8), length: 1))
            }
        }
    }
    @IBAction func receiveAct(_ sender: UIButton) {
        //这个样接收代理就会触发
        guard BlueToothCentral.characteristic != nil else {
            showErrorAlertWithTitle("Wrong", message: "Please check if you're connect.")
            return
        }
        //这里可以加一个判断，看看这个蓝牙的服务的特征是否是可读的，然后再读取呀！
        if (BlueToothCentral.characteristic.properties.rawValue & CBCharacteristicProperties.read.rawValue) != 0 {
            BlueToothCentral.peripheral.readValue(for: BlueToothCentral.characteristic)
        } else {
            print("cannot read")
            receiveStr += "cannot read\n"
        }
    }
    
    

    @IBOutlet weak var disConnectBtn: UIButton!
    @IBOutlet weak var connectBtn: UIButton!
    //    var disConnectBtn: UIButton!
//    var connectBtn: UIButton!
    
    //MARK: - Override Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "UnConnected"
        
        BlueToothCentral.centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.global())
        self.blueDisplay()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
        tapGesture.delegate = self
        self.view.addGestureRecognizer(tapGesture)
        
//        self.receiveTextView.delegate = self
        self.sendTextView.delegate = self
        
        self.sendTextView.layer.cornerRadius = 3.5
        self.sendTextView.clipsToBounds = true
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //就是如果加了这句的话，如果本来连接上了之后还没有拿到character的时候就到这一步了，那么就有问题了呀！但是转场取消直接没按扭了，所以使用再下面一句
//        if BlueToothCentral.characteristic == nil {
//            self.connectBtn.isHidden = false
//        }
        if BlueToothCentral.peripheral == nil {
            self.connectBtn.isHidden = false
        }
    }
}

//MARK: - BlueToothDelegate
extension ViewController: CBCentralManagerDelegate, CBPeripheralDelegate {
    
    func startBlueTooth() {
        guard BlueToothCentral.isBlueOn else { return }
//        centralManager.scanForPeripherals(withServices: nil, options: nil)
        //过了一会儿没连上怎么办？
//        DispatchQueue.main.asyncAfter(deadline: .now()+5) { [unowned self] in
//            if self.peripheral == nil {
//                self.connectBtn.isHidden = false
//            }
//            let ac = UIAlertController(title: "Not Found", message: "Please check if the peripheral is OK!", preferredStyle: .alert)
//            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//            self.present(ac, animated: true)
//        }
        let scanTableController = storyboard?.instantiateViewController(withIdentifier: "ScanTableController") as! ScanTableViewController
        self.navigationController?.pushViewController(scanTableController, animated: true)
//        self.navigationController?.modalTransitionStyle = .coverVertical
//        self.navigationController?.present(scanTableController, animated: true)
        connectBtn.isHidden = true
//        connectBtn.removeFromSuperview()
//        blurView.contentView.addSubview(disConnectBtn)
    }
    @objc func blueBtnMethod(_ sender: UIButton) {
        if sender.currentTitle == "ScanPer" {
            startBlueTooth()
        } else if sender.currentTitle == "Discont" {
            guard BlueToothCentral.peripheral != nil else { return }
            BlueToothCentral.centralManager.cancelPeripheralConnection(BlueToothCentral.peripheral)
        }
    }
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            BlueToothCentral.isBlueOn = true
            DispatchQueue.main.sync {
                connectBtn.isHidden = false
                self.title = "UnConnected"
            }
//            BlueToothCentral.centralManager.scanForPeripherals(withServices: nil, options: nil)
        default:
            BlueToothCentral.isBlueOn = false
            DispatchQueue.main.sync {
                if (self.navigationController?.viewControllers.count)! > 1 {
                    self.navigationController?.popViewController(animated: true)
                }
                self.disConnectBtn.isHidden = true
                self.connectBtn.isHidden = true
                allBtnisHidden(true)
                self.title = ""
            }
            DispatchQueue.main.asyncAfter(deadline: .now()+0.25) { [unowned self] in
                //貌似转场没结束，直接按钮隐身是没用的，所以只能after动画结束了难受
                self.disConnectBtn.isHidden = true
                self.connectBtn.isHidden = true
            }
            if BlueToothCentral.peripheral != nil {
                centralManager(BlueToothCentral.centralManager, didDisconnectPeripheral: BlueToothCentral.peripheral, error: nil)
            }
        }
    }
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard peripheral.name != nil else { return }
        if BlueToothCentral.isFirstPer {
            BlueToothCentral.isFirstPer = false
            BlueToothCentral.peripherals = []
            BlueToothCentral.peripheralIDs = []
            BlueToothCentral.peripherals.append(peripheral.name ?? "Unknown")
            BlueToothCentral.peripheralIDs.append(peripheral)
        } else {
            for per in BlueToothCentral.peripheralIDs {
                if per == peripheral { return }
            }
            BlueToothCentral.peripherals.append(peripheral.name ?? "Unknown")
            BlueToothCentral.peripheralIDs.append(peripheral)
        }
//        guard peripheral.identifier == UUID(uuidString: "32631FF3-E023-3448-0F0C-2A7437257A72") else {
//            return
//        }
//        self.peripheral = peripheral
//        ViewController.centralManager.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        //如果连接之前已经有一个连接着了，那么需要把它先disconnect？不然虽然可能可以两个连着，但也只有一个的引用呀现在。
        if BlueToothCentral.peripheral != nil {
            
        }
        
        
        print("didConnect: ")
        BlueToothCentral.peripheral = peripheral
        BlueToothCentral.centralManager.stopScan()
        BlueToothCentral.peripheral.delegate = self
        BlueToothCentral.peripheral.discoverServices(nil)
        
        //注意self.title这个也需要在主线程
        DispatchQueue.main.sync { [unowned self] in
            self.title = peripheral.name
            self.disConnectBtn.isHidden = false
            self.connectBtn.isHidden = true
            self.allBtnisHidden(false)
            //注意在手势触发蓝牙扫描转场的时候，因为在Transition这一个类里面，所以无法对我们的按钮进行操控（也就是不能像startBlueTooth方法一样对connectbtn隐藏，且使activityView动画），所以为了稍微正常一点，我把connectbtn的隐藏在这下面也写一下，activityView就没有动画了，反正也被遮住了看不到🤦‍♂️。
            self.navigationController?.popViewController(animated: true)
        }
    }
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("didFailToConnect: ")
    }
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("didDisconnectPeripheral: ")
        BlueToothCentral.peripheral = nil
        BlueToothCentral.characteristic = nil
        DispatchQueue.main.async { [unowned self] in
            self.senBtn.isEnabled = false
            self.receiveBtn.isEnabled = false
            self.senBtn.backgroundColor = UIColor.black.withAlphaComponent(0.37)
            self.receiveBtn.backgroundColor = UIColor.black.withAlphaComponent(0.37)
            self.propertyStr = ""
            
            self.allBtnisHidden(true)
            if BlueToothCentral.isBlueOn {
                self.disConnectBtn.isHidden = true
                self.connectBtn.isHidden = false
                self.title = "UnConnected"
            } else {
                self.disConnectBtn.isHidden = true
                self.connectBtn.isHidden = true
                self.title = ""
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard BlueToothCentral.peripheral == peripheral else { return }
        DispatchQueue.main.sync { [unowned self] in
            if let text = self.serviceNumSelectLabel.text, let num = Int(text), ((peripheral.services?.count)!>=num) {
                peripheral.discoverCharacteristics(nil, for: ((peripheral.services?[num-1])!))
                print((peripheral.services?[num-1])!)
            } else {
                peripheral.discoverCharacteristics(nil, for: (peripheral.services?.first)!)
                print((peripheral.services?.first)!)
                if self.serviceNumSelectLabel.text != "" {
                    self.serviceNumSelectLabel.text = "1"
                }
            }
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard BlueToothCentral.peripheral == peripheral else { return }
        //此处last还是first有讲究吗？我记得之前一直设置订阅订阅不上去的，怎么解决的?这里要sync而不是async
        DispatchQueue.main.sync { [unowned self] in
            if let text = self.charNumSelectTextLabel.text, let num = Int(text), ((service.characteristics?.count)!>=num) {
                BlueToothCentral.characteristic = service.characteristics?[num-1]
            } else {
                BlueToothCentral.characteristic = service.characteristics?.first
                if self.charNumSelectTextLabel.text != "" {
                    self.charNumSelectTextLabel.text = "1"
                }
            }
        }
        
//        BlueToothCentral.characteristic = service.characteristics?.last
        print(BlueToothCentral.characteristic!)
        propertyStr = ""
        if (BlueToothCentral.characteristic.properties.rawValue & CBCharacteristicProperties.read.rawValue) != 0 {
            BlueToothCentral.peripheral.readValue(for: BlueToothCentral.characteristic)
            if propertyStr != "" {
                self.propertyStr += "\nRead"
            } else {
                self.propertyStr += "Read"
            }
            DispatchQueue.main.async {
                self.receiveBtn.isEnabled = true
                self.receiveBtn.backgroundColor = UIColor(red: 0.196, green: 0.604, blue: 0.357, alpha: 0.67)
            }
        } else {
            print("cannot read")
            DispatchQueue.main.async {
                self.receiveBtn.isEnabled = false
                self.receiveBtn.backgroundColor = UIColor.black.withAlphaComponent(0.37)
            }
        }
        
        
        if (BlueToothCentral.characteristic.properties.rawValue & CBCharacteristicProperties.notify.rawValue) != 0 {
            BlueToothCentral.peripheral.setNotifyValue(true, for: BlueToothCentral.characteristic)
            if propertyStr != "" {
                self.propertyStr += "\nNotify"
            } else {
                self.propertyStr += "Notify"
            }
        } else {
            print("cannot notify")
        }
        
        
        self.writeType = nil
        if (BlueToothCentral.characteristic.properties.rawValue & CBCharacteristicProperties.write.rawValue) != 0 {
            self.writeType = CBCharacteristicWriteType.withResponse
            if propertyStr != "" {
                self.propertyStr += "\nWriteWithResponse"
            } else {
                self.propertyStr += "WriteWithResponse"
            }
        } else {
            print("cannot writeWithResponse")
        }
        if (BlueToothCentral.characteristic.properties.rawValue & CBCharacteristicProperties.writeWithoutResponse.rawValue) != 0 {
            self.writeType = CBCharacteristicWriteType.withoutResponse
            if propertyStr != "" {
                self.propertyStr += "\nWriteWithoutResponse"
            } else {
                self.propertyStr += "WriteWithoutResponse"
            }
        } else {
            print("cannot writeWithoutResponse")
        }
        DispatchQueue.main.async {
            //如果不能发送，那么把发送按钮变灰
            if self.writeType == nil {
                self.senBtn.isEnabled = false
                self.senBtn.backgroundColor = UIColor.black.withAlphaComponent(0.37)
            } else {
                self.senBtn.isEnabled = true
                self.senBtn.backgroundColor = UIColor(red: 0.196, green: 0.604, blue: 0.357, alpha: 0.67)
            }
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
//        print("Updated")
        if let error = error {
            print(error.localizedDescription)
        } else {
            let valueData = characteristic.value!
            let data = NSData(data: valueData)
            //由于接收到的数据是四个字节即八个16进制它自动会给出一个空格，所以不是一字节一个空格,要做一些处理
            let valueStr = data.description.replacingOccurrences(of: "<", with: "").replacingOccurrences(of: ">", with: "").replacingOccurrences(of: " ", with: "")
//            receiveStr += "Updated\n"
//            print(valueStr)
            guard valueStr.count > 0 else { return }
            //一下为了把收到的数据两个两个的分开，即一个字节一个字节分开处理
            var firstIndex = valueStr.startIndex
            var secondindex = valueStr.index(firstIndex, offsetBy: 1)
            //啊啊啊啊啊，以前我这里从valueStr到valueStrs一直是少一个16进制的
            var valueStrs = [String]()
            //            for _ in 0..<valueStr.count/2-1 {
            //                valueStrs.append(String(valueStr[firstIndex...secondindex]))
            //                firstIndex = valueStr.index(secondindex, offsetBy: 1)
            //                secondindex = valueStr.index(firstIndex, offsetBy: 1)
            //            }
            for _ in 0..<valueStr.count/2-1 {
                valueStrs.append(String(valueStr[firstIndex...secondindex]))
                firstIndex = valueStr.index(secondindex, offsetBy: 1)
                secondindex = valueStr.index(firstIndex, offsetBy: 1)
            }
            //所以这里最后要加一句这个呀，本来没加
            valueStrs.append(String(valueStr[firstIndex...secondindex]))
            
//            print(valueStrs)
            
            var values = ""
            //收到的是16进制的String表示
            switch receiveType {
            case .Hexadecimal:
//                String(str, radix: 16, uppercase: true)
                values = valueStrs.joined(separator: " ").uppercased()
            case .Decimal:
                var dataInt = [String]()
                for uint8str in valueStrs {
                    if let uint8 = UInt8(uint8str, radix: 16) {
                        dataInt.append("\(uint8)")
                    }
                }
                values = dataInt.joined(separator: " ")
            case .ASCII:
//                print("Hexadecimal receive: " + valueStr)
                var dataInt = [String]()
                for uint8str in valueStrs {
                    if let uint8 = UInt8(uint8str, radix: 16) {
                        if (uint8 >= 1 && uint8 <= 8) || (uint8 >= 11 && uint8 <= 12) || (uint8 >= 14 && uint8 <= 31) || (uint8 == 127 ) {
                            dataInt.append(uint8str)
                        } else {
                            let char = Character(UnicodeScalar(uint8))
                            dataInt.append("\(char)")
                        }
                    }
                }
                if dataInt.last == "\n" {
                    dataInt.removeLast()
                    if dataInt.last == "\r" {
                        dataInt.removeLast()
                    }
                }
                values = dataInt.joined(separator: " ")
//                print("Hexadecimal receive: " + values)
            }
            
            receiveStr += "\(values)\n"
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("Notidied")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("write to peripheral withresponse")
    }
    
}


//MARK: - TextField and Gesture Delegate
extension ViewController: UITextFieldDelegate, UIGestureRecognizerDelegate, UITextViewDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return false
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        self.checkSendData()
    }
    //下面是实时监测输入的数字来实现return按键，因为它不像UITextField有shouldreturn代理。
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    @objc func tapAction(_ gestureRecognizer: UITapGestureRecognizer) {
        
//        self.textField.resignFirstResponder()
//        //下面是前一个按下变到后一个类似于tab键
//        self.textField.becomeFirstResponder()
        self.sendTextView.resignFirstResponder()
        self.receiveTextView.resignFirstResponder()
        self.charNumSelectTextLabel.resignFirstResponder()
        self.serviceNumSelectLabel.resignFirstResponder()
    }
}


//MARK: - Extral Methods
extension ViewController {
    func checkSendData() {
        guard self.writeType != nil else { return }
        
        let sendStr = sendTextView.text!
        let numbers = sendStr.split(separator: " ")
        //最后要将各类的string表示转换成data发送出去
        switch sendType {
        case .Decimal:
            for number in numbers {
                if let _ = UInt8(number) {
                    continue
                } else {
                    self.sendTextView.layer.borderColor = self.receiveCleraBtn.backgroundColor?.cgColor
                    self.sendTextView.layer.borderWidth = 1.5
                    self.sendTextView.layer.cornerRadius = 3.5
                    self.sendTextView.clipsToBounds = true
                    self.senBtn.isEnabled = false
                    self.senBtn.backgroundColor = self.receiveCleraBtn.backgroundColor
                    return
                }
            }
        case .Hexadecimal:
            self.sendTextView.text = sendStr.uppercased()
            for number in numbers {
                if let _ = UInt8(number, radix: 16) {
                    continue
                } else {
                    self.sendTextView.layer.borderColor = self.receiveCleraBtn.backgroundColor?.cgColor
                    self.sendTextView.layer.borderWidth = 1.5
                    self.sendTextView.layer.cornerRadius = 3.5
                    self.sendTextView.clipsToBounds = true
                    self.senBtn.isEnabled = false
                    self.senBtn.backgroundColor = self.receiveCleraBtn.backgroundColor
                    return
                }
            }
        case .ASCII:
            var isRight = true
            var slashCount = 0
            var sendStrCopy = sendStr
            while sendStrCopy.last == "\\"{
                slashCount += 1
                sendStrCopy.removeLast()
            }
            if slashCount % 2 != 0 {
                isRight = false
            }
            while sendStrCopy.contains(#"\"#) {
                let index = sendStrCopy.firstIndex(of: "\\")!
                let secondIndex = sendStrCopy.index(after: index)
                
                switch sendStrCopy[secondIndex] {
                case "\\":
                    sendStrCopy.remove(at: index)
                    fallthrough
                case "0":
                    fallthrough
                case "t":
                    fallthrough
                case "n":
                    fallthrough
                case "r":
                    sendStrCopy.remove(at: index)
                default:
                    isRight = false
                    sendStrCopy.remove(at: index)
                    break
                }
            }
            if let _ = sendStr.data(using: .utf8), isRight {
                
            } else {
                self.sendTextView.layer.borderColor = self.receiveCleraBtn.backgroundColor?.cgColor
                self.sendTextView.layer.borderWidth = 1.5
                self.sendTextView.layer.cornerRadius = 3.5
                self.sendTextView.clipsToBounds = true
                self.senBtn.isEnabled = false
                self.senBtn.backgroundColor = self.receiveCleraBtn.backgroundColor
                return
            }
        }
        self.sendTextView.layer.borderColor = UIColor.white.withAlphaComponent(0).cgColor
        //a下面这句话是错的，UIColor created with component values far outside the expected range.
//        self.sendTextView.layer.borderColor = UIColor(white: 3, alpha: 0).cgColor
        self.sendTextView.layer.borderWidth = 0
        self.senBtn.isEnabled = true
        //颜色我现在好难实现。。。随意直接根据现有的赋值吧。。而且下面那个本身不specify alpha也可以的，因为一样的，我只想让你知道它怎么用的。
        self.senBtn.backgroundColor = UIColor(red: 0.196, green: 0.604, blue: 0.357, alpha: 0.67)
    }
    
    //我前面要做的是如果发送的数据不合适，显示红框且不能发送，所以此处不用可选其实也可以。
    func returnSendData() -> Data? {
        let sendStr = sendTextView.text!
        var uint8s = [UInt8]()
        let numbers = sendStr.split(separator: " ")
        //最后要将各类的string表示转换成data发送出去
        switch sendType {
        case .Decimal:
            for number in numbers {
                if let uint8 = UInt8(number) {
                    uint8s.append(uint8)
                } else {
                    return nil
                }
            }
            return Data(uint8s)
        case .Hexadecimal:
            for number in numbers {
                if let uint8 = UInt8(number, radix: 16) {
                    uint8s.append(uint8)
                } else {
                    return nil
                }
            }
            return Data(uint8s)
        case .ASCII:
            //终于知道了，转义字符从text中读取的时候，会给它前面默认加一个"\"变成非转义的"\"所以就出现了我下面的很多错误了
            //转义字符: 由于单个转换，无法..
            //目前是感觉\n直接被编译器那个了，所以我要多加一个\n试试？  或者把他们一个个转成UnicodeScalar("\n").value这样，还是用UInt8发送（目前证实这条根本不对，从view的textf读入已经自动加了"\"导致错误了）
            
            //现在还有一个问题，就是没来就想是一个\一个n的现在就没解决了
            var sendStrCopy = sendStr
            var slashIndexs = [String.Index]()
            while sendStrCopy.contains(#"\"#) {
                let index = sendStrCopy.firstIndex(of: "\\")!
                
                let secondIndex = sendStrCopy.index(after: index)
                
                switch sendStrCopy[secondIndex] {
                case "0":
                    sendStrCopy.insert("\0", at: index)
                    sendStrCopy.remove(at: secondIndex)
                    sendStrCopy.remove(at: secondIndex)
                case "t":
                    sendStrCopy.insert("\t", at: index)
                    sendStrCopy.remove(at: secondIndex)
                    sendStrCopy.remove(at: secondIndex)
                case "n":
                    sendStrCopy.insert("\n", at: index)
                    sendStrCopy.remove(at: secondIndex)
                    sendStrCopy.remove(at: secondIndex)
                case "r":
                    sendStrCopy.insert("\r", at: index)
                    sendStrCopy.remove(at: secondIndex)
                    sendStrCopy.remove(at: secondIndex)
                case "\\":
                    slashIndexs.append(index)
                    sendStrCopy.remove(at: index)
                    sendStrCopy.remove(at: index)
                default:
                    break
                }
            }
            for index in slashIndexs.reversed() {
                sendStrCopy.insert(#"\"#, at: index)
            }
            
            //            print(sendStr.debugDescription)
//            print(sendStrCopy)
//            print(sendStrCopy.debugDescription)
            
            return sendStrCopy.data(using: .utf8)
            //            return sendStr.data(using: .ascii)
            
            //本来想先转为ASCII码，再转成data发送的。因为一开始没有发现读入字符串后转义变非转义的问题，然后因为写了这个打印了一下知道了错误所在
            //            for scalar in sendStr.unicodeScalars {
            //                if scalar.value < 256 {
            //                    uint8s.append(UInt8(scalar.value))
            //                }
            //            }
            //            print(uint8s)
            //            return Data(uint8s)
            
        }
    }
    
    func allBtnisHidden(_ ye: Bool) {
    }
    
    func showErrorAlertWithTitle(_ title: String?, message: String?) {
        DispatchQueue.main.async {
            let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(ac, animated: true)
        }
    }
}


//MARK: - Extral Displays

extension ViewController {
    func blueDisplay() {
//        let visualEffect = UIBlurEffect(style: .dark)
//
//        let blurView = UIVisualEffectView(effect: visualEffect)
//        blurView.frame = CGRect(x: self.view.bounds.width-120, y: self.view.bounds.height*0.75, width: 100, height: 100)
//        blurView.alpha = 0.7
//        blurView.layer.cornerRadius = 10
//        blurView.clipsToBounds = true
        
//        connectBtn = UIButton(type: .custom)
        connectBtn.addTarget(self, action: #selector(blueBtnMethod(_:)), for: .touchUpInside)
//        connectBtn.frame = visualEffectView.bounds
        //        blueBtn.tintColor = UIColor.white
        //        blueBtn.titleLabel?.text = "OK"
        connectBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        connectBtn.titleLabel?.textAlignment = .center
        connectBtn.isHidden = false
        connectBtn.setTitle("Not OK", for: .normal)
        connectBtn.setTitle("ScanPer", for: .highlighted)
        connectBtn.setTitleColor(UIColor.white, for: .normal)
        connectBtn.setTitleColor(UIColor.red, for: .highlighted)
        visualEffectView.contentView.addSubview(connectBtn) //必须添加到contentView
        
//        disConnectBtn = UIButton(type: .custom)
        disConnectBtn.addTarget(self, action: #selector(blueBtnMethod(_:)), for: .touchUpInside)
//        disConnectBtn.frame = visualEffectView.bounds
        //        blueBtn.tintColor = UIColor.white
        //        blueBtn.titleLabel?.text = "OK"
        disConnectBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        disConnectBtn.titleLabel?.textAlignment = .center
        disConnectBtn.isHidden = true
        disConnectBtn.setTitle("Conted", for: .normal)
        disConnectBtn.setTitle("Discont", for: .highlighted)
        disConnectBtn.setTitleColor(UIColor.red, for: .normal)
        disConnectBtn.setTitleColor(UIColor.red, for: .highlighted)
        visualEffectView.contentView.addSubview(disConnectBtn) //必须添加到contentView
        
//        activityView = UIActivityIndicatorView(style: .white)
//        activityView.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
//        activityView.isHidden = true
//        visualEffectView.contentView.addSubview(activityView)
        
//        self.view.addSubview(blurView)
    }
}
