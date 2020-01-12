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
import AudioToolbox

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
    
    mutating func changeReceive(type to: SendAndReceiveType) {
        self = to
    }
}

enum ShowType: String {
    case normal
    case bigger
    case rtthread
    
    mutating func changeShowType(type to: ShowType) {
        self = to
    }
    
    mutating func rtthreadToggle() {
        if self == .normal {
            self = .rtthread
        } else if self == .rtthread {
            self = .normal
        }
    }
    
    mutating func biggerToggle() {
        if self == .normal {
            self = .bigger
        } else if self == .bigger {
            self = .normal
        }
    }
}

class ViewController: UIViewController {
    var showType: ShowType = .normal
    
    @IBOutlet weak var rtthreadmsh: UILabel!
    @IBOutlet weak var rtthreadVisualBackground: UIVisualEffectView!
    @IBOutlet weak var rtthreadTextView: UITextView!
    //由于TextField没有tab键的代理方法，按下tab键直接焦点移动的，所以只能用回TextView了
//    @IBOutlet weak var rtthreadSendTextField: UITextField!
    @IBOutlet weak var rtthreadSendTextView: UITextView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBAction func chooseChartistic(_ sender: Any) {
        self.performSegue(withIdentifier: "goToChoose", sender: nil)
    }
    @IBAction func chooseCharBtnAct(_ sender: Any) {
        self.performSegue(withIdentifier: "goToChoose", sender: nil)
    }
    
    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    
    let blueToothCentral = BlueToothCentral()
    
    var shouldCheck = true
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

    //留了两个label本来做信号指示的，但是貌似label的background不能动画，先留一下吧。。。。
    @IBOutlet weak var receiveCleraBtn: UIButton!
    @IBAction func sendClearAct(_ sender: UIButton) {
        self.sendTextView.text = ""
        self.checkSendData()
    }
    @IBAction func receiceClearAct(_ sender: UIButton) {
        self.receiveStr = ""
    }
    
    
    var receiveType = SendAndReceiveType.ASCII
    @IBAction func receiveTypeAct(_ sender: UIButton) {
        receiveType.toggle()
        sender.setTitle(receiveType.rawValue, for: .normal)
    }
    @IBOutlet weak var receiveTypeBtn: UIButton!
    
    var sendType = SendAndReceiveType.ASCII
    @IBAction func sendTypeAct(_ sender: UIButton) {
        sendType.toggle()
        sender.setTitle(sendType.rawValue, for: .normal)
        self.checkSendData()
    }
    @IBOutlet weak var sendTypeBtn: UITextView!
    
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
                    self.sendTextView.backgroundColor = self.view.backgroundColor
                    }, completion: nil)
        })
        
    }
    
    @IBOutlet weak var receiveBtn: UIButton!
    @IBOutlet weak var receiveTextView: UITextView!
    @IBOutlet weak var receiveBigTextView: UITextView!
    
    var scrollTimes = 0 {
        didSet {
            if self.scrollTimes == 3 {
                self.scrollTimes = 0
            }
        }
    }
    var receiveStr = "" {
        didSet {
            self.scrollTimes += 1
            DispatchQueue.main.async { [unowned self] in
                switch self.showType {
                case .normal:
//                    print("normal")
                    self.receiveTextView.text = self.receiveStr
//                    self.receiveBigTextView.text = ""
//                    self.rtthreadTextView.text = ""
                    self.receiveTextView.scrollRangeToVisible(NSRange(location: self.receiveTextView.text.lengthOfBytes(using: .utf8)-1, length: 1))
                case .bigger:
//                    print("bigger")
                    self.receiveBigTextView.text = self.receiveStr
//                    self.rtthreadTextView.text = ""
//                    self.receiveTextView.text = ""
                    self.receiveBigTextView.scrollRangeToVisible(NSRange(location:self.receiveStr.lengthOfBytes(using: .utf8), length: 0))
                case .rtthread:
//                    print("rtthread")
                    self.rtthreadTextView.text = self.receiveStr
//                    self.receiveTextView.text = ""
//                    self.receiveBigTextView.text = ""
//                    if self.scrollTimes == 0 {
//                        self.rtthreadTextView.scrollRangeToVisible(NSRange(location: self.rtthreadTextView.text.lengthOfBytes(using: .utf8)-1, length: 1))
//                        self.rtthreadSendTextView.isScrollEnabled = false
//                        self.rtthreadSendTextView.isScrollEnabled = true
//                    }
//                    self.rtthreadSendTextView.setContentOffset(self.rtthreadSendTextView.contentOffset, animated: false)
                    self.rtthreadTextView.scrollRangeToVisible(NSRange(location: self.rtthreadTextView.text.lengthOfBytes(using: .utf8), length: 0))
//                    self.rtthreadSendTextView.scrollToBottom()
                }
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
        if (BlueToothCentral.readCharacteristic.properties.rawValue & CBCharacteristicProperties.read.rawValue) != 0 {
            BlueToothCentral.peripheral.readValue(for: BlueToothCentral.readCharacteristic)
        } else {
            print("cannot read")
            receiveStr += "cannot read\n"
        }
    }
    
    

    @IBOutlet weak var disConnectBtn: UIButton!
    @IBOutlet weak var connectBtn: UIButton!
    
    //MARK: - Override Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "UnConnected"
        self.titleLabel.text = "UnConnected"
        
        NotificationCenter.default.addObserver(self, selector: #selector(willShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        
        BlueToothCentral.centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.global())
        self.blueDisplay()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
        tapGesture.delegate = self
        self.view.addGestureRecognizer(tapGesture)
        
        self.sendTextView.delegate = self
        self.rtthreadSendTextView.delegate = self
        self.rtthreadSendTextView.layoutManager.allowsNonContiguousLayout = false
        
        self.sendTextView.layer.cornerRadius = 3.5
        self.sendTextView.clipsToBounds = true
        
        self.receiveBigTextView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
        self.rtthreadVisualBackground.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
        
        let doubleTapGesture1 = UITapGestureRecognizer(target: self, action: #selector(doubleTapAct(_:)))
        doubleTapGesture1.numberOfTapsRequired = 2
        let doubleTapGesture2 = UITapGestureRecognizer(target: self, action: #selector(doubleTapAct(_:)))
        doubleTapGesture2.numberOfTapsRequired = 2
        
        self.receiveTextView.addGestureRecognizer(doubleTapGesture1)
        self.receiveBigTextView.addGestureRecognizer(doubleTapGesture2)
        
        let doubleTapGesture3 = UITapGestureRecognizer(target: self, action: #selector(doubleDoubleTapAct(_:)))
        doubleTapGesture3.numberOfTapsRequired = 2
        doubleTapGesture3.numberOfTouchesRequired = 2
        self.receiveTextView.addGestureRecognizer(doubleTapGesture3)
        let doubleTapGesture4 = UITapGestureRecognizer(target: self, action: #selector(doubleDoubleTapAct(_:)))
        doubleTapGesture4.numberOfTapsRequired = 2
        self.rtthreadTextView.addGestureRecognizer(doubleTapGesture4)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //就是如果加了这句的话，如果本来连接上了之后还没有拿到character的时候就到这一步了，那么就有问题了呀！但是转场取消直接没按扭了，所以使用再下面一句
//        if BlueToothCentral.characteristic == nil {
//            self.connectBtn.isHidden = false
//        }
//        if BlueToothCentral.peripheral == nil {
//            self.connectBtn.isHidden = false
//        }
//
//        if showType != .normal {
//            self.navigationController?.navigationBar.alpha = 0
//            self.tabBarController?.tabBar.alpha = 0
//
//            self.rtthreadTextView.resignFirstResponder()
//        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if BlueToothCentral.peripheral == nil {
            self.connectBtn.isHidden = false
        }
        
//        if showType != .normal {
//            self.navigationController?.navigationBar.alpha = 0
//            self.tabBarController?.tabBar.alpha = 0
//
//            self.rtthreadTextView.resignFirstResponder()
//
//        }
    }
}

//MARK: - BlueToothDelegate
extension ViewController: CBCentralManagerDelegate, CBPeripheralDelegate {
    
    func startBlueTooth() {
        guard BlueToothCentral.isBlueOn else { return }

        
        let scanTableController = storyboard?.instantiateViewController(withIdentifier: "ScanTableController") as! ScanTableViewController
        self.navigationController?.pushViewController(scanTableController, animated: true)
        
        connectBtn.isHidden = true

    }
    @objc func blueBtnMethod(_ sender: UIButton) {
        if sender.currentTitle == "ScanPer" {
            startBlueTooth()
            AudioServicesPlaySystemSound(1519)
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
                self.titleLabel.text = "UnConnected"
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
                self.titleLabel.text = ""
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

    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        //如果连接之前已经有一个连接着了，那么需要把它先disconnect？不然虽然可能可以两个连着，但也只有一个的引用呀现在。
        if BlueToothCentral.peripheral != nil {
            
        }
        
//        self.rtthreadSendTextField.text = ""
        print("didConnect: ")
        BlueToothCentral.peripheral = peripheral
        BlueToothCentral.centralManager.stopScan()
        BlueToothCentral.peripheral.delegate = self
        BlueToothCentral.peripheral.discoverServices(nil)
        
        //注意self.title这个也需要在主线程
        DispatchQueue.main.sync { [unowned self] in
            self.title = peripheral.name
            self.titleLabel.text = peripheral.name
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
        AudioServicesPlaySystemSound(1521)
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
                self.titleLabel.text = "UnConnected"
            } else {
                self.disConnectBtn.isHidden = true
                self.connectBtn.isHidden = true
                self.title = ""
                self.titleLabel.text = ""
            }
        }
        
        BlueToothCentral.services.removeAll()
        BlueToothCentral.characteristics.removeAll()
        BlueToothCentral.characteristic = nil
        BlueToothCentral.readCharacteristic = nil
        BlueToothCentral.notifyCharacteristic = nil
        
        BlueToothCentral.writeServiceNum = 0
        BlueToothCentral.writeCharNum = 0
        BlueToothCentral.readServiceNum = 0
        BlueToothCentral.readCharNum = 0
        BlueToothCentral.notifyServiceNum = 0
        BlueToothCentral.notifyCharNum = 0
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard BlueToothCentral.peripheral == peripheral else { return }
        DispatchQueue.main.sync { [unowned self] in
            if let text = self.serviceNumSelectLabel.text, let num = Int(text), ((peripheral.services?.count)!>=num) {
                BlueToothCentral.writeServiceNum = num
            } else {
                BlueToothCentral.writeServiceNum = 1
                if self.serviceNumSelectLabel.text != "" {
                    self.serviceNumSelectLabel.text = "1"
                }
            }
        }
        
        for service in peripheral.services! {
            if let _ = BlueToothCentral.characteristics[service] {
                continue
            } else {
                BlueToothCentral.characteristics[service] = [CBCharacteristic]()
                BlueToothCentral.services.append(service)
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard BlueToothCentral.peripheral == peripheral else { return }
        if let _ = BlueToothCentral.characteristics[service] {
            for charactistic in service.characteristics! {
                BlueToothCentral.characteristics[service]?.append(charactistic)
            }
        }
        
        //此处last还是first有讲究吗？我记得之前一直设置订阅订阅不上去的，怎么解决的?这里要sync而不是async
        DispatchQueue.main.sync { [unowned self] in
            if let text = self.charNumSelectTextLabel.text, let num = Int(text) {
                if BlueToothCentral.services.count == BlueToothCentral.writeServiceNum {
                    if (service.characteristics?.count)! >= num {
                        BlueToothCentral.writeCharNum = num
                    } else {
                        BlueToothCentral.writeCharNum = 1
                        if self.charNumSelectTextLabel.text != "" {
                            self.charNumSelectTextLabel.text = "1"
                        }
                    }
                }
            } else {
                BlueToothCentral.writeCharNum = 1
                if self.charNumSelectTextLabel.text != "" {
                    self.charNumSelectTextLabel.text = "1"
                }
            }
        }
        
        if BlueToothCentral.writeServiceNum != 0 && BlueToothCentral.writeCharNum != 0 && BlueToothCentral.characteristic == nil {
            BlueToothCentral.characteristic = BlueToothCentral.characteristics[BlueToothCentral.services[BlueToothCentral.writeServiceNum-1]]![BlueToothCentral.writeCharNum-1]
            BlueToothCentral.readCharacteristic = BlueToothCentral.characteristics[BlueToothCentral.services[BlueToothCentral.writeServiceNum-1]]![BlueToothCentral.writeCharNum-1]
            BlueToothCentral.notifyCharacteristic = BlueToothCentral.characteristics[BlueToothCentral.services[BlueToothCentral.writeServiceNum-1]]![BlueToothCentral.writeCharNum-1]
            
            BlueToothCentral.readServiceNum = BlueToothCentral.writeServiceNum
            BlueToothCentral.readCharNum = BlueToothCentral.writeCharNum
            BlueToothCentral.notifyServiceNum = BlueToothCentral.writeServiceNum
            BlueToothCentral.notifyCharNum = BlueToothCentral.writeCharNum
            
            DispatchQueue.main.async {
                self.correctBtn()
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
//        print("Updated")
        if let error = error {
            print(error.localizedDescription)
        } else {
            
            let valueData = characteristic.value!
//            let data = NSData(data: valueData)
//            var valueStr = data.description
            
            //https://www.jianshu.com/p/37daef564e14
            //厉害了，以前我一直上面的两句话的，现在swift高级函数一句话搞定了诶，👍
            var valueStr = valueData.reduce("", {$0 + String(format: "%02x", $1)})
            print(valueStr)
            
            
            //由于接收到的数据是四个字节即八个16进制它自动会给出一个空格，所以不是一字节一个空格,要做一些处理
            valueStr = valueStr.replacingOccurrences(of: "<", with: "").replacingOccurrences(of: ">", with: "").replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "{", with: "").replacingOccurrences(of: "}", with: "")
//            receiveStr += "Updated\n"
            
            guard valueStr.count > 0 else { return }
            
            //NB101返回的数据会有前缀length=18,bytes=0x，然后0x后面是18位，36个数字（或字母）,不过我也很疑惑，不应该length=18,bytes=0x直接也是十六进制显示的嘛？它到好，从Data转到String直接是字符了。
            //
            if valueStr.hasPrefix("length=") {
                while valueStr.count > 0 && valueStr.first != "x" {
                    valueStr.removeFirst()
                }
                if valueStr.count > 0 && valueStr.first == "x" {
                    valueStr.removeFirst()
                }
            }
            
            
            //一下为了把收到的数据两个两个的分开，即一个字节一个字节分开处理
            var firstIndex = valueStr.startIndex
            var secondindex = valueStr.index(firstIndex, offsetBy: 1)
            //啊啊啊啊啊，以前我这里从valueStr到valueStrs一直是少一个16进制的
            var valueStrs = [String]()

            for _ in 0..<valueStr.count/2-1 {
                valueStrs.append(String(valueStr[firstIndex...secondindex]))
                firstIndex = valueStr.index(secondindex, offsetBy: 1)
                secondindex = valueStr.index(firstIndex, offsetBy: 1)
            }
            //所以这里最后要加一句这个呀，本来没加
            valueStrs.append(String(valueStr[firstIndex...secondindex]))
            
            print("update: \(valueStrs)")
            
            var values = ""
            //收到的是16进制的String表示
            switch receiveType {
            case .Hexadecimal:
//                String(str, radix: 16, uppercase: true)
                values = valueStrs.joined(separator: " ").uppercased() + "\n"
            case .Decimal:
                var dataInt = [String]()
                for uint8str in valueStrs {
                    if let uint8 = UInt8(uint8str, radix: 16) {
                        dataInt.append("\(uint8)")
                    }
                }
                values = dataInt.joined(separator: " ") + "\n"
            case .ASCII:
//                print("Hexadecimal receive: " + valueStr)
                var dataInt = [String]()
                for uint8str in valueStrs {
                    //本来16进制的00，也即\0是C语言字符串结束标志位，但是显示又显示不出来的篓，我这边也还是变为16进制00算了
                    if let uint8 = UInt8(uint8str, radix: 16) {
                        //如果我发送tab按键，它会自动补全代码，所以它会先发送回退键\b，tab键前面有几个单词就几个t回退键，我要处理好这个
                        if self.showType == .rtthread {
                            if uint8 == 8 {
//                                if self.rtthreadStr.count >= 1 {
//                                    self.rtthreadStr.removeLast()
                                if dataInt.count > 0 {
                                    dataInt.removeLast()
                                } else if self.receiveStr.count > 0 {
                                    self.receiveStr.removeLast()
                                }
                                 continue
//                                }
                            }
                        }
                        
                        if (uint8 >= 0 && uint8 <= 8) || (uint8 >= 11 && uint8 <= 12) || (uint8 >= 14 && uint8 <= 31) || (uint8 == 127 ) {
                            dataInt.append("\\u{\(uint8)}") //让其显示十进制的
                        } else {
                            let char = Character(UnicodeScalar(uint8))
                            dataInt.append("\(char)")
                        }
                    }
                }

                
                values = dataInt.joined(separator: "")
//                print(values.debugDescription)
                
                //q去掉转义的颜色等等
                if self.showType == .rtthread {
                    while values.contains(#"\u{27}["#) {
                        if let index = values.firstIndex(of: "\\") {
                            for _ in 0..<9 {
                                values.remove(at: index)
                            }
                            
                            //这两种方法不是太好，纯粹是根据我我得到的字符串所以能这么写，否则会有漏网之鱼的。
                            //上面只能写0～8，去除9个，因为最后的那个消除c转义只有9个，写10会溢出
                            if let firstIndex = values.firstIndex(of: "m"), firstIndex == index {
                                values.remove(at: index)
                            }
                            if let firstIndex = values.lastIndex(of: "m"), firstIndex == index {
                                values.remove(at: index)
                            }
                        }
                    }
                }
            }
            self.receiveStr += "\(values)"
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("Notidied")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
//        print("write to peripheral withresponse")
    }
    
}


//MARK: - TextView and Gesture Delegate
extension ViewController: UITextFieldDelegate, UIGestureRecognizerDelegate, UITextViewDelegate {
    
    
    @objc func willShow(notification: NSNotification) {
        if self.rtthreadSendTextView.isFirstResponder {
            let textMaxY = self.rtthreadSendTextView.frame.maxY // 取到输入框的最大的y坐标值
            
            let userinfo: NSDictionary = notification.userInfo! as NSDictionary
            
            let nsValue:AnyObject? = userinfo.object(forKey: UIResponder.keyboardFrameEndUserInfoKey) as AnyObject?
            
            let keyboardY = nsValue?.cgRectValue.origin.y  //取到键盘的y坐标
            
            //设置动画
            
            let duration = 2.0
            
            UIView.animate(withDuration: duration) { () -> Void in
                if (textMaxY > keyboardY!) {
//                    self.view.transform = CGAffineTransform(translationX: 0, y: keyboardY! - textMaxY - 10)
                    self.rtthreadSendTextView.transform = CGAffineTransform(translationX: 0, y: keyboardY! - textMaxY)
                    self.rtthreadTextView.transform = CGAffineTransform(translationX: 0, y: keyboardY! - textMaxY)
                    self.rtthreadmsh.transform = CGAffineTransform(translationX: 0, y: keyboardY! - textMaxY)
                } else {
                    //view.transform = CGAffineTransformIdentity;线性代数里面讲的矩阵变换，这个是恒等变换当 你改变过一个view.transform属性或者view.layer.transform的时候需要恢复默认状态的话，记得先把他们重置可以使用view.transform = CGAffineTransformIdentity，或者view.layer.transform = CATransform3DIdentity，
                    self.rtthreadSendTextView.transform = .identity
                    self.rtthreadTextView.transform = .identity
                    self.rtthreadmsh.transform = .identity
                }
            }
        }
    }
    
    @objc func willHide(notification: NSNotification) {
        UIView.animate(withDuration: 2.0) { () -> Void in
            self.rtthreadSendTextView.transform = .identity
            self.rtthreadTextView.transform = .identity
            self.rtthreadmsh.transform = .identity
        }
    }
    
    //MARK: - UITextViewDelegate
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.tag == 111 {
            self.checkSendData()
        } else if textView.tag == 321 {
            self.view.endEditing(true)
        }
    }
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.tag == 321 {
            
        }
    }
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if textView.tag == 111 {
            self.shouldCheck = true
        }
        
        return true
    }
    //下面是实时监测输入的数字来实现return按键，因为它不像UITextField有shouldreturn代理。
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if textView.tag == 111 {
            if text == "\n" {
                textView.resignFirstResponder()
                
                if textView.text == "ConEmu Here" || textView.text == "CONEMU HERE" || textView.text == "conemu here" || textView.text == "shell" || textView.text == "SHELL" {
                    self.shouldCheck = false
                    
                    self.showType.changeShowType(type: .rtthread)
                    self.receiveStr += ""
                    
                    UIView.animate(withDuration: 0.3, animations: { [unowned self] in
                        self.receiveTextView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
                        self.receiveTextView.alpha = 0
//                        self.navigationController?.navigationBar.alpha = 0
                        self.tabBarController?.tabBar.alpha = 0
                    })
                    
                    UIView.animate(withDuration: 0.7, delay: 0.27, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: .curveEaseIn, animations: { [unowned self] in
                        self.rtthreadVisualBackground.transform = .identity
                        self.rtthreadVisualBackground.alpha = 1
                    })  { (_) in
                        self.rtthreadSendTextView.becomeFirstResponder()
//                        self.receiveStr += ""
                    }
                } else if textView.text == "edit" || textView.text == "EDIT" || textView.text == "choose" || textView.text == "CHOOSE"{
                    self.shouldCheck = false
                    self.performSegue(withIdentifier: "goToChoose", sender: nil)
                } else if textView.text == "connect" || textView.text == "CONNECT" {
                    self.shouldCheck = false
                    guard BlueToothCentral.isBlueOn && BlueToothCentral.peripheral == nil else { return false }

                    let scanTableController = storyboard?.instantiateViewController(withIdentifier: "ScanTableController") as! ScanTableViewController
                    self.navigationController?.pushViewController(scanTableController, animated: true)
                    connectBtn.isHidden = true
                } else if textView.text == "disconnect" || textView.text == "DISCONNECT" {
                    self.shouldCheck = false
                    guard BlueToothCentral.peripheral != nil else { return false }
                    BlueToothCentral.centralManager.cancelPeripheralConnection(BlueToothCentral.peripheral)
                } else if textView.text == "ascii" || textView.text == "ASCII" {
                    self.shouldCheck = false
                    receiveType.changeReceive(type: .ASCII)
                } else if textView.text == "hexadecimal" || textView.text == "HEXADECIMAL" {
                    self.shouldCheck = false
                    receiveType.changeReceive(type: .Hexadecimal)
                } else if textView.text == "decimal" || textView.text == "DECIMAL" {
                    self.shouldCheck = false
                    receiveType.changeReceive(type: .Decimal)
                } else if textView.text == "clear" || textView.text == "CLEAR" {
                    self.shouldCheck = false
                    self.receiveStr = ""
                }
                
                return false
            }
        } else if textView.tag == 321 {
            var sendChar = text
            if text == "" {
                sendChar = "\u{8}"
            }
            if BlueToothCentral.peripheral != nil, let writeType = self.writeType {
                print(text.debugDescription)
                BlueToothCentral.peripheral.writeValue(sendChar.data(using: .utf8)!, for: BlueToothCentral.characteristic, type: writeType)
            }
            
            return false
        }
        
        return true
        //true if the old text should be replaced by the new text; false if the replacement operation should be aborted.这个return还是蛮重要的，如果我这个是truem，那么这个方法执行完后，text的h值还是要在textview显示的。
        //return false就是我这个函数执行完后，这个text这个字符不会显示了。
    }
//
//    func dropFirstTabStr(sendText: String, tabTempStr: String) -> String {
//        var mutatingSendStr = sendText
//        for _ in 0..<tabTempStr.count {
//            let _ = mutatingSendStr.removeFirst()
//        }
//
//        return mutatingSendStr
//    }

    
    //MARK: - UIGesture delegate
    @objc func tapAction(_ gestureRecognizer: UITapGestureRecognizer) {
        self.sendTextView.resignFirstResponder()
        self.receiveTextView.resignFirstResponder()
        self.receiveBigTextView.resignFirstResponder()
        self.charNumSelectTextLabel.resignFirstResponder()
        self.serviceNumSelectLabel.resignFirstResponder()
    }
    
    //点击两下放大或者接收屏幕
    @objc func doubleTapAct(_ gestureRecognizer: UITapGestureRecognizer) {
        sendTextView.resignFirstResponder()
        
        showType.biggerToggle()
        self.receiveStr += ""
        
        if (showType == .bigger) {
            AudioServicesPlaySystemSound(1519)
            UIView.animate(withDuration: 0.25, animations: { [unowned self] in
                self.receiveTextView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
                self.receiveTextView.alpha = 0
                self.navigationController?.navigationBar.alpha = 0
                self.tabBarController?.tabBar.alpha = 0
            }) { (_) in
//                AudioServicesPlaySystemSound(1519)
            }
            
            UIView.animate(withDuration: 0.7, delay: 0.27, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: .curveEaseIn, animations: { [unowned self] in
                self.receiveBigTextView.transform = .identity
                self.receiveBigTextView.alpha = 1
            })  { (_) in
//                self.receiveStr += ""
            }
        } else {
            UIView.animate(withDuration: 0.25, animations: { [unowned self] in
                self.receiveBigTextView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
                self.receiveBigTextView.alpha = 0
            })
            
            UIView.animate(withDuration: 0.7, delay: 0.27, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: .curveEaseIn, animations: { [unowned self] in
                self.receiveTextView.transform = .identity
                self.receiveTextView.alpha = 1
                self.navigationController?.navigationBar.alpha = 1
                self.tabBarController?.tabBar.alpha = 1
            }) { (_) in
//                self.receiveStr += ""
            }
        }
    }
    
    @objc func doubleDoubleTapAct(_ gestureRecognizer: UITapGestureRecognizer) {
        sendTextView.resignFirstResponder()
        
        showType.rtthreadToggle()
        self.receiveStr += ""
    
        if showType == .rtthread {
            AudioServicesPlaySystemSound(1519)
            UIView.animate(withDuration: 0.25, animations: { [unowned self] in
                self.receiveTextView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
                self.receiveTextView.alpha = 0
//                self.navigationController?.navigationBar.alpha = 0
                self.tabBarController?.tabBar.alpha = 0
            }) { (_) in
//                AudioServicesPlaySystemSound(1519)
            }
            
            UIView.animate(withDuration: 0.45, delay: 0.27, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: .curveEaseIn, animations: { [unowned self] in
                self.rtthreadVisualBackground.transform = .identity
                self.rtthreadVisualBackground.alpha = 1
            }) { (_) in
                self.rtthreadSendTextView.becomeFirstResponder()
//                self.receiveStr += ""
            }
   
        } else {
            if self.rtthreadSendTextView.isFirstResponder {
                self.view.endEditing(true)
            }
//            rtthreadSendTextField.resignFirstResponder()
            
            UIView.animate(withDuration: 0.25, animations: { [unowned self] in
                self.rtthreadVisualBackground.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
                self.rtthreadVisualBackground.alpha = 0
            })
            
            UIView.animate(withDuration: 0.45, delay: 0.27, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: .curveEaseIn, animations: { [unowned self] in
                self.receiveTextView.transform = .identity
                self.receiveTextView.alpha = 1
//                self.navigationController?.navigationBar.alpha = 1
                self.tabBarController?.tabBar.alpha = 1
            }) { (_) in
//                self.receiveStr += ""
            }
        }
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
            
            while sendStrCopy.contains(#"\"#) && isRight {
                let index = sendStrCopy.firstIndex(of: "\\")!
                let secondIndex = sendStrCopy.index(after: index)
                
                switch sendStrCopy[secondIndex] {
                case "u":
                    var number = 0
                    //u后面起码还要有三个"{" "number" "}"
                    //请注意：endindex是一个sequence的结尾，但不是最后一个元素，就像C语言的字符串结尾EOF，是不能访问的
                    var indexcc = sendStrCopy.index(after: secondIndex)
                    if indexcc == sendStrCopy.endIndex { isRight = false; break }
                    if sendStrCopy[indexcc] != "{" {
                        isRight = false
                        break
                    }
                    
                    let indexstart = sendStrCopy.index(after: indexcc)
                    indexcc = sendStrCopy.index(after: indexcc)
                    if indexcc == sendStrCopy.endIndex { isRight = false; break }
                    
                    while(sendStrCopy[indexcc] != "}" ) {
                        number += 1
                        
                        indexcc = sendStrCopy.index(after: indexcc)
                        if indexcc == sendStrCopy.endIndex {
                            isRight = false
                            break
                        }
                    }
                    
                    //while里面出来后要判断一下是否是搜索到了}
                    if indexcc == sendStrCopy.endIndex {
                        isRight = false
                        break
                    }
                    
                    if number == 0 {
                        isRight = false
                        break
                    }
                    
                    var valueString = sendStrCopy[indexstart..<indexcc]
//                    print(valueString)
                    //uint8<128的时候好一点，但是大于127之后删除后这个字符串会出问题，目前不知道原因
                    if valueString.hasPrefix("0x") && number>=2 {
                        valueString.removeFirst()
                        valueString.removeFirst()
                        
                        if let uint8 = UInt8(valueString, radix: 16) {
                            sendStrCopy.insert(Character(UnicodeScalar(uint8)), at: index)
                            
                            for _ in 0...3+number {
                                sendStrCopy.remove(at: secondIndex)
                            }
                        } else {
                            isRight = false
                            break
                        }
                    } else if let uint8 = UInt8(valueString), uint8<128 {
//                        print(Character(UnicodeScalar(uint8)))
                        sendStrCopy.insert(Character(UnicodeScalar(uint8)), at: index)
                        
                        for _ in 0...3+number {
                            sendStrCopy.remove(at: secondIndex)
                        }
//                        print(sendStrCopy)
                    } else {
                        isRight = false
                    }
                    
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
                case "u":
                    var number = 0
                    var indexcc = sendStrCopy.index(after: secondIndex)
                    
                    let indexstart = sendStrCopy.index(after: indexcc)
                    indexcc = sendStrCopy.index(after: indexcc)
                    
                    while(sendStrCopy[indexcc] != "}") {
                        number += 1
                        indexcc = sendStrCopy.index(after: indexcc)
                    }
                    
                    var valueString = sendStrCopy[indexstart..<indexcc]
                    if valueString.hasPrefix("0x") && number>=2 {
                        valueString.removeFirst()
                        valueString.removeFirst()
                        
                        if let uint8 = UInt8(valueString, radix: 16) {
                            sendStrCopy.insert(Character(UnicodeScalar(uint8)), at: index)
                            
                            for _ in 0...3+number {
                                sendStrCopy.remove(at: secondIndex)
                            }
                        }
                    } else if let uint8 = UInt8(valueString) {
                        sendStrCopy.insert(Character(UnicodeScalar(uint8)), at: index)
                        
                        for _ in 0...3+number {
                            sendStrCopy.remove(at: secondIndex)
                        }
                    }
                default:
                    break
                }
            }
            for index in slashIndexs.reversed() {
                sendStrCopy.insert(#"\"#, at: index)
            }
            
//            print(sendStrCopy)
//            print(sendStrCopy.debugDescription)
            
            return sendStrCopy.data(using: .utf8)
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
    
    
    func correctBtn() {
        propertyStr = ""
        if (BlueToothCentral.readCharacteristic.properties.rawValue & CBCharacteristicProperties.read.rawValue) != 0 {
            if propertyStr != "" {
                self.propertyStr += "\n(\(BlueToothCentral.readServiceNum), \(BlueToothCentral.readCharNum)) Read"
            } else {
                self.propertyStr += "(\(BlueToothCentral.readServiceNum), \(BlueToothCentral.readCharNum)) Read"
            }
            self.receiveBtn.isEnabled = true
            self.receiveBtn.backgroundColor = UIColor(red: 0.196, green: 0.604, blue: 0.357, alpha: 0.67)
            
        } else {
            print("cannot read")
            self.receiveBtn.isEnabled = false
            self.receiveBtn.backgroundColor = UIColor.black.withAlphaComponent(0.37)
        }
        
        
        if (BlueToothCentral.notifyCharacteristic.properties.rawValue & CBCharacteristicProperties.notify.rawValue) != 0 {
            BlueToothCentral.peripheral.setNotifyValue(true, for: BlueToothCentral.notifyCharacteristic)
            if propertyStr != "" {
                self.propertyStr += "\n(\(BlueToothCentral.notifyServiceNum), \(BlueToothCentral.notifyCharNum)) Notify"
            } else {
                self.propertyStr += "(\(BlueToothCentral.notifyServiceNum), \(BlueToothCentral.notifyCharNum)) Notify"
            }
        } else {
            print("cannot notify")
        }
        
        
        self.writeType = nil
        if (BlueToothCentral.characteristic.properties.rawValue & CBCharacteristicProperties.writeWithoutResponse.rawValue) != 0 {
            self.writeType = CBCharacteristicWriteType.withoutResponse
            if propertyStr != "" {
                self.propertyStr += "\n(\(BlueToothCentral.writeServiceNum), \(BlueToothCentral.writeCharNum)) WriteWithoutResponse"
            } else {
                self.propertyStr += "(\(BlueToothCentral.writeServiceNum), \(BlueToothCentral.writeCharNum)) WriteWithoutResponse"
            }
        } else {
            print("cannot writeWithoutResponse")
        }
        if (BlueToothCentral.characteristic.properties.rawValue & CBCharacteristicProperties.write.rawValue) != 0 {
            self.writeType = CBCharacteristicWriteType.withResponse
            if propertyStr != "" {
                self.propertyStr += "\n(\(BlueToothCentral.writeServiceNum), \(BlueToothCentral.writeCharNum)) WriteWithResponse"
            } else {
                self.propertyStr += "(\(BlueToothCentral.writeServiceNum), \(BlueToothCentral.writeCharNum)) WriteWithResponse"
            }
        } else {
            print("cannot writeWithResponse")
        }
        
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


//MARK: - Extral Displays
extension ViewController {
    func blueDisplay() {
        connectBtn.addTarget(self, action: #selector(blueBtnMethod(_:)), for: .touchUpInside)

        connectBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        connectBtn.titleLabel?.textAlignment = .center
        connectBtn.isHidden = false
        connectBtn.setTitle("Not OK", for: .normal)
        connectBtn.setTitle("ScanPer", for: .highlighted)
        connectBtn.setTitleColor(UIColor.white, for: .normal)
        connectBtn.setTitleColor(UIColor.red, for: .highlighted)
        visualEffectView.contentView.addSubview(connectBtn) //必须添加到contentView
        
        disConnectBtn.addTarget(self, action: #selector(blueBtnMethod(_:)), for: .touchUpInside)
        disConnectBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        disConnectBtn.titleLabel?.textAlignment = .center
        disConnectBtn.isHidden = true
        disConnectBtn.setTitle("Conted", for: .normal)
        disConnectBtn.setTitle("Discont", for: .highlighted)
        disConnectBtn.setTitleColor(UIColor.red, for: .normal)
        disConnectBtn.setTitleColor(UIColor.red, for: .highlighted)
        visualEffectView.contentView.addSubview(disConnectBtn) //必须添加到contentView
        
    }
}


extension ViewController {
    //segue回调方法，获取返回参数
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToChoose" {
            let desVC = segue.destination as! ChooseCharViewController
            desVC.writeType = self.writeType
        }
    }
    
    @IBAction func close(segue: UIStoryboardSegue) {
        if segue.identifier == "closeChoose" {
            let sourceVC = segue.source as! ChooseCharViewController
            //这个赋值可能没什么用🤦‍♂️，因为下面的correctBtn()还会检查一遍的
            
            self.writeType = sourceVC.writeType
            
            guard BlueToothCentral.peripheral != nil else { return }
            self.correctBtn()
        }
        
        
    }

}

extension ViewController {
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override var keyCommands: [UIKeyCommand]? {
        var keyCommands = [UIKeyCommand]()
        if BlueToothCentral.peripheral == nil && BlueToothCentral.isBlueOn {
            keyCommands.append(UIKeyCommand(input: "c", modifierFlags: .command, action: #selector(shortcuts(sender:)), discoverabilityTitle: "connect"))
        } else {
            keyCommands.append(UIKeyCommand(input: "d", modifierFlags: .command, action: #selector(shortcuts(sender:)), discoverabilityTitle: "disConnect"))
        }
        
        if self.showType != .rtthread {
            keyCommands.append(UIKeyCommand(input: "s", modifierFlags: .command, action: #selector(shortcuts(sender:)), discoverabilityTitle: "showShell"))
        }
        if self.showType != .normal {
            keyCommands.append(UIKeyCommand(input: "w", modifierFlags: .command, action: #selector(shortcuts(sender:)), discoverabilityTitle: "shownormal"))
        }
        if self.showType != .bigger {
            keyCommands.append(UIKeyCommand(input: "b", modifierFlags: .command, action: #selector(shortcuts(sender:)), discoverabilityTitle: "showBigger"))
        }
        keyCommands.append(UIKeyCommand(input: "e", modifierFlags: .command, action: #selector(shortcuts(sender:)), discoverabilityTitle: "edit"))
        
        return [UIKeyCommand(input: "c", modifierFlags: .command, action: #selector(shortcuts(sender:)), discoverabilityTitle: "connect"), UIKeyCommand(input: "d", modifierFlags: .command, action: #selector(shortcuts(sender:)), discoverabilityTitle: "disConnect"), UIKeyCommand(input: "s", modifierFlags: .command, action: #selector(shortcuts(sender:)), discoverabilityTitle: "showShell"), UIKeyCommand(input: "w", modifierFlags: .command, action: #selector(shortcuts(sender:)), discoverabilityTitle: "shownormal"), UIKeyCommand(input: "b", modifierFlags: .command, action: #selector(shortcuts(sender:)), discoverabilityTitle: "showBigger"), UIKeyCommand(input: "e", modifierFlags: .command, action: #selector(shortcuts(sender:)), discoverabilityTitle: "edit"), UIKeyCommand(input: "a", modifierFlags: .alternate, action: #selector(shortcuts(sender:)), discoverabilityTitle: "ASCII"), UIKeyCommand(input: "d", modifierFlags: .alternate, action: #selector(shortcuts(sender:)), discoverabilityTitle: "Decimal"), UIKeyCommand(input: "h", modifierFlags: .alternate, action: #selector(shortcuts(sender:)), discoverabilityTitle: "Hexadecimal"),UIKeyCommand(input: "c", modifierFlags: [.command, .alternate], action: #selector(shortcuts(sender:)), discoverabilityTitle: "clear") ]
    }
    
    @objc func shortcuts(sender: UIKeyCommand) {
        switch sender.input {
        case "c":
            if sender.modifierFlags.contains(.alternate) {
                self.receiveStr = ""
                return
            }
            if BlueToothCentral.peripheral == nil && BlueToothCentral.isBlueOn {
                AudioServicesPlaySystemSound(1519)
                let scanTableController = storyboard?.instantiateViewController(withIdentifier: "ScanTableController") as! ScanTableViewController
                self.navigationController?.pushViewController(scanTableController, animated: true)
                connectBtn.isHidden = true
            }
        case "d":
            if sender.modifierFlags == .alternate {
                receiveType.changeReceive(type: .Decimal)
                receiveTypeBtn.setTitle(receiveType.rawValue, for: .normal)
                return
            }
            
            if BlueToothCentral.peripheral != nil {
                BlueToothCentral.centralManager.cancelPeripheralConnection(BlueToothCentral.peripheral)
            }

        case "s":
            if self.showType != .rtthread {
                if self.sendTextView.isFirstResponder {
                    self.sendTextView.resignFirstResponder()
                }
                
                self.showType.changeShowType(type: .rtthread)
                self.receiveStr += ""
                
                AudioServicesPlaySystemSound(1519)
                UIView.animate(withDuration: 0.25, animations: { [unowned self] in
                    self.receiveTextView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
                    self.receiveTextView.alpha = 0
                    self.tabBarController?.tabBar.alpha = 0
                    
                    self.receiveBigTextView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
                    self.receiveBigTextView.alpha = 0
                }) { (_) in
//                    AudioServicesPlaySystemSound(1519)
                }
                
                UIView.animate(withDuration: 0.45, delay: 0.2, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: .curveEaseIn, animations: { [unowned self] in
                    self.rtthreadVisualBackground.transform = .identity
                    self.rtthreadVisualBackground.alpha = 1
                })  { (_) in
                    self.rtthreadSendTextView.becomeFirstResponder()
                }
            }

        case "w":
            if self.showType != .normal {
                if self.rtthreadSendTextView.isFirstResponder {
                    self.rtthreadSendTextView.resignFirstResponder()
                }
                
                self.showType.changeShowType(type: .normal)
                self.receiveStr += ""
                
                UIView.animate(withDuration: 0.25, animations: { [unowned self] in
                    self.receiveBigTextView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
                    self.receiveBigTextView.alpha = 0
                    
                    self.rtthreadVisualBackground.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
                    self.rtthreadVisualBackground.alpha = 0
                })
                
                UIView.animate(withDuration: 0.45, delay: 0.2, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: .curveEaseIn, animations: { [unowned self] in
                    self.receiveTextView.transform = .identity
                    self.receiveTextView.alpha = 1
                    self.tabBarController?.tabBar.alpha = 1
                }) { (_) in
                }
            }
            
        case "b":
            if self.showType != .bigger {
                if self.sendTextView.isFirstResponder {
                    self.sendTextView.resignFirstResponder()
                }
                if self.rtthreadSendTextView.isFirstResponder {
                    self.rtthreadSendTextView.resignFirstResponder()
                }
                
                self.showType.changeShowType(type: .bigger)
                self.receiveStr += ""
                
                AudioServicesPlaySystemSound(1519)
                UIView.animate(withDuration: 0.25, animations: { [unowned self] in
                    self.receiveTextView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
                    self.receiveTextView.alpha = 0
                    self.tabBarController?.tabBar.alpha = 0
                    
                    self.rtthreadVisualBackground.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
                    self.rtthreadVisualBackground.alpha = 0
                }) { (_) in
//                    AudioServicesPlaySystemSound(1519)
                }
                
                UIView.animate(withDuration: 0.45, delay: 0.2, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: .curveEaseIn, animations: { [unowned self] in
                    self.receiveBigTextView.transform = .identity
                    self.receiveBigTextView.alpha = 1
                })
            }
            
        case "e":
            self.performSegue(withIdentifier: "goToChoose", sender: nil)
            
        case "a":
            receiveType.changeReceive(type: .ASCII)
            receiveTypeBtn.setTitle(receiveType.rawValue, for: .normal)
            
        case "h":
            receiveType.changeReceive(type: .Hexadecimal)
            receiveTypeBtn.setTitle(receiveType.rawValue, for: .normal)
            
        default:
            break
        }
    }
}



