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
    //留了两个label本来做信号指示的，但是貌似label的background不能动画，先留一下吧。。。。
    @IBOutlet weak var sendLabel: UILabel!
    @IBOutlet weak var receiveLabel: UILabel!
    @IBOutlet weak var receiveCleraBtn: UIButton!
    @IBAction func sendClearAct(_ sender: UIButton) {
        self.sendTextView.text = ""
        self.checkSendData()
    }
    @IBAction func receiceClearAct(_ sender: UIButton) {
        self.receiveTextView.text = ""
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
        guard self.characteristic != nil else {
            showErrorAlertWithTitle("Wrong", message: "Please check if you're connect.")
            return
        }
        //注意：有一种情况是你在发送区没有按完成直接点击发送，这样的话一个didendedit代理自动被执行按钮变红，还有这里的发送按钮actt也被执行，但是我这里数据data是nild不会被发出去的，所以字体改变这一步是不应该执行的。
        if let data = self.returnSendData() {
            self.peripheral.writeValue(data, for: self.characteristic, type: .withoutResponse)
        } else {
            //刚开始点击发送还是要检查一下？其实不需要的如果刚开始启动的时候view里面没有zstring的时候
            //那下面再加一句的话如果编辑string后编辑界面还没消失直接点击发送这里检查一遍，代理didendediting也会检查一遍的。
            self.checkSendData()
            return
        }
        
        //貌似对字体动画无效,而且我也找不到别的字体的动画效果，只能背景颜色先代替一下喽?而且我发现连着写两个animate，两个会有冲突？？虽然有延时。所以改一改第二个写在completion里面而不是b串联着写下去是可以的。emmm，要不还是写成x字体突然变大再变小这样，虽然动画是没有用的。
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveEaseIn, animations: { [unowned self] in
            self.sendTextView.backgroundColor = self.receiveBtn.backgroundColor?.withAlphaComponent(0.25)
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
        guard self.characteristic != nil else {
            showErrorAlertWithTitle("Wrong", message: "Please check if you're connect.")
            return
        }
        self.peripheral.readValue(for: self.characteristic)
    }
    
    
    
    //MARK: - Property
    static var peripherals = [String]()
    static var peripheralIDs = [CBPeripheral]()
    //由于扩展中不能写存储属性，所以只能写在这里了
    static var isBlueOn = false
    static var isFirstPer = false
    static var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral!
    private var characteristic: CBCharacteristic!
    var disConnectBtn: UIButton!
    var ConnectBtn: UIButton!
    var activityView: UIActivityIndicatorView!
    
    
    //MARK: - Override Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "UnConnected"
        
        ViewController.centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.global())
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
        self.activityView.stopAnimating()
        
        if self.characteristic == nil {
            self.ConnectBtn.isHidden = false
        }
    }
}

//MARK: - BlueToothDelegate
extension ViewController: CBCentralManagerDelegate, CBPeripheralDelegate {
    
    func startBlueTooth() {
        guard ViewController.isBlueOn else { return }
//        centralManager.scanForPeripherals(withServices: nil, options: nil)
        //过了一会儿没连上怎么办？
//        DispatchQueue.main.asyncAfter(deadline: .now()+5) { [unowned self] in
//            if self.peripheral == nil {
//                self.activityView.stopAnimating()
//                self.activityView.isHidden = true
//                self.ConnectBtn.isHidden = false
//            }
//            let ac = UIAlertController(title: "Not Found", message: "Please check if the peripheral is OK!", preferredStyle: .alert)
//            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//            self.present(ac, animated: true)
//        }
        let scanTableController = storyboard?.instantiateViewController(withIdentifier: "ScanTableController") as! ScanTableViewController
        self.navigationController?.pushViewController(scanTableController, animated: true)
//        self.navigationController?.modalTransitionStyle = .coverVertical
//        self.navigationController?.present(scanTableController, animated: true)
        ConnectBtn.isHidden = true
        activityView.isHidden = false
        activityView.startAnimating()
//        ConnectBtn.removeFromSuperview()
//        blurView.contentView.addSubview(disConnectBtn)
    }
    @objc func blueBtnMethod(_ sender: UIButton) {
        if sender.currentTitle == "ScanPer" {
            startBlueTooth()
        } else if sender.currentTitle == "Discont" {
            guard self.peripheral != nil else { return }
            ViewController.centralManager.cancelPeripheralConnection(self.peripheral)
        }
    }
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            ViewController.isBlueOn = true
            DispatchQueue.main.sync {
                ConnectBtn.isHidden = false
                self.title = "UnConnected"
            }
        default:
            ViewController.isBlueOn = false
            DispatchQueue.main.sync {
                if (self.navigationController?.viewControllers.count)! > 1 {
                    self.navigationController?.popViewController(animated: true)
                }
                self.disConnectBtn.isHidden = true
                self.ConnectBtn.isHidden = true
                allBtnisHidden(true)
                self.title = ""
            }
            DispatchQueue.main.asyncAfter(deadline: .now()+0.25) { [unowned self] in
                //貌似转场没结束，直接按钮隐身是没用的，所以只能after动画结束了难受
                self.disConnectBtn.isHidden = true
                self.ConnectBtn.isHidden = true
            }
            if self.peripheral != nil {
                centralManager(ViewController.centralManager, didDisconnectPeripheral: self.peripheral, error: nil)
            }
        }
    }
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard peripheral.name != nil else { return }
        
        if ViewController.isFirstPer {
            ViewController.isFirstPer = false
            ViewController.peripherals = []
            ViewController.peripheralIDs = []
            ViewController.peripherals.append(peripheral.name ?? "Unknown")
            ViewController.peripheralIDs.append(peripheral)
        } else {
            for per in ViewController.peripheralIDs {
                if per == peripheral { return }
            }
            ViewController.peripherals.append(peripheral.name ?? "Unknown")
            ViewController.peripheralIDs.append(peripheral)
        }
//        guard peripheral.identifier == UUID(uuidString: "32631FF3-E023-3448-0F0C-2A7437257A72") else {
//            return
//        }
//        self.peripheral = peripheral
//        ViewController.centralManager.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("didConnect: ")
        //注意self.title这个也需要在主线程
        DispatchQueue.main.sync { [unowned self] in
            self.title = peripheral.name
            self.activityView.stopAnimating()
            self.activityView.isHidden = true
            self.disConnectBtn.isHidden = false
            self.allBtnisHidden(false)
            
            self.navigationController?.popViewController(animated: true)
        }
        
        self.peripheral = peripheral
        ViewController.centralManager.stopScan()
        self.peripheral.delegate = self
        self.peripheral.discoverServices(nil)
    }
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("didFailToConnect: ")
    }
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("didDisconnectPeripheral: ")
        self.peripheral = nil
        self.characteristic = nil
        DispatchQueue.main.async { [unowned self] in
            self.allBtnisHidden(true)
            if ViewController.isBlueOn {
                self.disConnectBtn.isHidden = true
                self.activityView.isHidden = true
                self.activityView.stopAnimating()
                self.ConnectBtn.isHidden = false
                self.title = "UnConnected"
            } else {
                self.disConnectBtn.isHidden = true
                self.activityView.isHidden = true
                self.activityView.stopAnimating()
                self.ConnectBtn.isHidden = true
                self.title = ""
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard self.peripheral == peripheral else { return }
        
        print((peripheral.services?.first)!)
        peripheral.discoverCharacteristics(nil, for: (peripheral.services?.first)!)
    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard self.peripheral == peripheral else { return }
        //此处last还是first有讲究吗？我记得之前一直设置订阅订阅不上去的，怎么解决的？
        self.characteristic = service.characteristics?.first
        print(self.characteristic!)
        
        if (self.characteristic.properties.rawValue & CBCharacteristicProperties.notify.rawValue) != 0 {
            peripheral.setNotifyValue(true, for: self.characteristic)
        } else {
            print("cannot notify")
        }
        if (self.characteristic.properties.rawValue & CBCharacteristicProperties.read.rawValue) != 0 {
            peripheral.readValue(for: self.characteristic)
        } else {
            print("cannot read")
        }
        
    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("Updated")
        if let error = error {
            print(error.localizedDescription)
        } else {
            let valueData = characteristic.value!
            let data = NSData(data: valueData)
            //由于接收到的数据是四个字节即八个16进制它自动会给出一个空格，所以不是一字节一个空格,要做一些处理
            let valueStr = data.description.replacingOccurrences(of: "<", with: "").replacingOccurrences(of: ">", with: "").replacingOccurrences(of: " ", with: "")
//            receiveStr += "Updated\n"
            
            //一下为了把收到的数据两个两个的分开，即一个字节一个字节分开处理
            var firstIndex = valueStr.startIndex
            var secondindex = valueStr.index(firstIndex, offsetBy: 1)
            var valueStrs = [String]()
            for _ in 0..<valueStr.count/2-1 {
                valueStrs.append(String(valueStr[firstIndex...secondindex]))
                firstIndex = valueStr.index(secondindex, offsetBy: 1)
                secondindex = valueStr.index(firstIndex, offsetBy: 1)
            }
//            print(valueStrs)
            
            var values = ""
            //收到的是16进制的String表示
            switch receiveType {
            case .Hexadecimal:
//                String(str, radix: 16, uppercase: true)
                values = valueStrs.joined(separator: " ")
            case .Decimal:
                var dataInt = [String]()
                for uint8str in valueStrs {
                    if let uint8 = UInt8(uint8str, radix: 16) {
                        dataInt.append("\(uint8)")
                    }
                }
                values = dataInt.joined(separator: " ")
            case .ASCII:
                var dataInt = [String]()
                for uint8str in valueStrs {
                    if let uint8 = UInt8(uint8str, radix: 16) {
                        dataInt.append("\(Character(UnicodeScalar(uint8)))")
                        print("\(Character(UnicodeScalar(uint8)))")
                    }
                }
                values = dataInt.joined(separator: " ")
                //若接收到的不是127还是128以内的（应该127），这样接收字符串可能要Unicode或者别的什么的编码，可是没有找到合适的函数。。先不写了。
//                let scanner = Scanner(string: valueStr)
//                var result:UInt32 = 0
//                scanner.scanHexInt32(&result)
//                print(Character(UnicodeScalar(0x1F79C)!))
//                receiveStr += "\(UnicodeScalar(0x1F79C)!) \(Character(UnicodeScalar(0x1F79C)!))"
            }
            
            receiveStr += "\(values)\n"
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("Notidied")
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
    }
}


//MARK: - Extral Methods
extension ViewController {
    func checkSendData() {
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
            //ASCII发送不需要分开转换的吧？
            if let _ = sendStr.data(using: .utf8){
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
        self.senBtn.backgroundColor = self.receiveBtn.backgroundColor?.withAlphaComponent(0.53)
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
            return Data(bytes: uint8s)
        case .Hexadecimal:
            for number in numbers {
                if let uint8 = UInt8(number, radix: 16) {
                    uint8s.append(uint8)
                } else {
                    return nil
                }
            }
            return Data(bytes: uint8s)
        case .ASCII:
            //ASCII发送不需要分开转换的吧？
            return sendStr.data(using: .utf8)
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
        let visualEffect = UIBlurEffect(style: .dark)
        
        let blurView = UIVisualEffectView(effect: visualEffect)
        //        self.blurView = blurView
        blurView.frame = CGRect(x: self.view.bounds.width-120, y: self.view.bounds.height-175, width: 100, height: 100)
        blurView.alpha = 0.7
        blurView.layer.cornerRadius = 10
        blurView.clipsToBounds = true
        
        ConnectBtn = UIButton(type: .custom)
        ConnectBtn.addTarget(self, action: #selector(blueBtnMethod(_:)), for: .touchUpInside)
        ConnectBtn.frame = CGRect(x: 10, y: 10, width: 80, height: 80)
        //        blueBtn.tintColor = UIColor.white
        //        blueBtn.titleLabel?.text = "OK"
        ConnectBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        ConnectBtn.titleLabel?.textAlignment = .center
        ConnectBtn.isHidden = false
        ConnectBtn.setTitle("Not OK", for: .normal)
        ConnectBtn.setTitle("ScanPer", for: .highlighted)
        ConnectBtn.setTitleColor(UIColor.white, for: .normal)
        ConnectBtn.setTitleColor(UIColor.red, for: .highlighted)
        blurView.contentView.addSubview(ConnectBtn) //必须添加到contentView
        
        disConnectBtn = UIButton(type: .custom)
        disConnectBtn.addTarget(self, action: #selector(blueBtnMethod(_:)), for: .touchUpInside)
        disConnectBtn.frame = CGRect(x: 10, y: 10, width: 80, height: 80)
        //        blueBtn.tintColor = UIColor.white
        //        blueBtn.titleLabel?.text = "OK"
        disConnectBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        disConnectBtn.titleLabel?.textAlignment = .center
        disConnectBtn.isHidden = true
        disConnectBtn.setTitle("Conted", for: .normal)
        disConnectBtn.setTitle("Discont", for: .highlighted)
        disConnectBtn.setTitleColor(UIColor.red, for: .normal)
        disConnectBtn.setTitleColor(UIColor.red, for: .highlighted)
        blurView.contentView.addSubview(disConnectBtn) //必须添加到contentView
        
        activityView = UIActivityIndicatorView(style: .white)
        activityView.frame = CGRect(x: 10, y: 10, width: 80, height: 80)
        activityView.isHidden = true
        blurView.contentView.addSubview(activityView)
        
        self.view.addSubview(blurView)
    }
}
