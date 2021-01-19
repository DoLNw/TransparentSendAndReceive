//
//  ChooseCharViewController.swift
//  TransparentSend
//
//  Created by JiaCheng on 2019/6/22.
//  Copyright © 2019 JiaCheng. All rights reserved.
//

import UIKit
import CoreBluetooth

class ChooseCharViewController: UIViewController {
    @IBOutlet weak var writeBackView: UIView!
    @IBOutlet weak var readBackView: UIView!
    @IBOutlet weak var notifyBackView: UIView!
    
    @IBOutlet weak var writePIckerView: UIPickerView!
    @IBOutlet weak var readPickerView: UIPickerView!
    @IBOutlet weak var notifyPickerView: UIPickerView!
    
    var writeData = PickerData()
    var readData = PickerData()
    var notifyData = PickerData()
    
    // 找到我现在已经选择的char是在上面的data哪一个，因为不是按照顺序来了，是筛选过的
    var formerWriteInPicker = (0, 0)
    var formerReadInPicker = (0, 0)
    var formerNotifyInPicker = (0, 0)
    
    var writeType: CBCharacteristicWriteType?
    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//
//
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
//        self.writeService.delegate = self
//        self.writeChar.delegate = self
//        self.readService.delegate = self
//        self.readChar.delegate = self
//        self.notifyService.delegate = self
//        self.notifyChar.delegate = self
        
//        self.writeService.becomeFirstResponder()
        
        classifyChars()
        
        self.writePIckerView.delegate = self
        self.writePIckerView.dataSource = self
        self.readPickerView.delegate = self
        self.readPickerView.dataSource = self
        self.notifyPickerView.delegate = self
        self.notifyPickerView.dataSource = self
        
        self.writePIckerView.showsSelectionIndicator = true
        self.readPickerView.showsSelectionIndicator = true
        self.notifyPickerView.showsSelectionIndicator = true
        
//        showCurrentChars()
        
        // 不需要？好像需要的。。但是一上来，马上拉下去，会出错，引用不见了
//        //一上来，动画还没结束呢[Doge], 不能直接有动作的
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [unowned self] in
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(selectDone))
        self.view.addGestureRecognizer(tapGesture)
//        }
        
        // 一个手势只能添加给一个view
//        let backViewTapGesture = UITapGestureRecognizer(target: self, action: #selector(selectView(ges:)))
//        self.writeBackView.addGestureRecognizer(backViewTapGesture)
//        self.readBackView.addGestureRecognizer(backViewTapGesture)
//        self.notifyBackView.addGestureRecognizer(backViewTapGesture)
        
        self.writeBackView.layer.borderWidth = 2.5
        self.writeBackView.layer.cornerRadius = 12
        self.writeBackView.layer.borderColor = UIColor.clear.cgColor
        self.readBackView.layer.borderWidth = 2.5
        self.readBackView.layer.cornerRadius = 12
        self.readBackView.layer.borderColor = UIColor.clear.cgColor
        self.notifyBackView.layer.borderWidth = 2.5
        self.notifyBackView.layer.cornerRadius = 12
        self.notifyBackView.layer.borderColor = UIColor.clear.cgColor
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        showCurrentChars()
    }
    
    @objc func selectView(ges: UITapGestureRecognizer) {
        switch ges.view {
        case writeBackView:
            self.writeBackView.layer.borderColor = UIColor.systemPink.cgColor
            self.readBackView.layer.borderColor = UIColor.clear.cgColor
            self.notifyBackView.layer.borderColor = UIColor.clear.cgColor
        case readBackView:
            self.readBackView.layer.borderColor = UIColor.systemPink.cgColor
            self.writeBackView.layer.borderColor = UIColor.clear.cgColor
            self.notifyBackView.layer.borderColor = UIColor.clear.cgColor
        case notifyBackView:
            self.notifyBackView.layer.borderColor = UIColor.systemPink.cgColor
            self.writeBackView.layer.borderColor = UIColor.clear.cgColor
            self.readBackView.layer.borderColor = UIColor.clear.cgColor
        default:
            break
        }
    }
    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        print(touches.first?.view)
//    }
    
    @objc func selectDone() {
        // 因为我所有选择的数据都是筛选过了合理的，所以done之后直接覆盖即可
        self.writeBackView.layer.borderColor = UIColor.clear.cgColor
        self.readBackView.layer.borderColor = UIColor.clear.cgColor
        self.notifyBackView.layer.borderColor = UIColor.clear.cgColor
        
        var writecolor = UIColor.clear
        var readcolor = UIColor.clear
        var notifycolor = UIColor.clear
        
        //有至少一个变化，那么才震动加更新
        var flag = false
        
//        UISelectionFeedbackGenerator
//        let generate = UIImpactFeedbackGenerator(style: .rigid)
//        generate.prepare()
//        generate.impactOccurred()
        
        // 如果现在选择了与之前不一样的
        let writeServiceNum = self.writeData.services[self.writePIckerView.selectedRow(inComponent: 0)]
        let writeCharNum = self.writeData.chars[self.writePIckerView.selectedRow(inComponent: 0)][self.writePIckerView.selectedRow(inComponent: 1)]
        
        if (BlueToothCentral.writeServiceNum != writeServiceNum || BlueToothCentral.writeCharNum != writeCharNum) {
            
            flag = true
            writecolor = UIColor.systemGreen
            
            if writeServiceNum == 0 { // 代表不选择该写特征，那我怎么取消呢？
                BlueToothCentral.characteristic = nil
                
                BlueToothCentral.writeServiceNum = 0
                BlueToothCentral.writeCharNum = 0
                
                self.writeType = nil
            } else {
                // BlueToothCentral里面存储的是无0的，但是下标索引的时候，是从0开始的
                let writeService = BlueToothCentral.services[writeServiceNum-1]
                
                BlueToothCentral.characteristic = BlueToothCentral.characteristics[writeService]![writeCharNum-1]
                
                BlueToothCentral.writeServiceNum = writeServiceNum
                BlueToothCentral.writeCharNum = writeCharNum
                
                self.writeType = .withoutResponse
                
                if (BlueToothCentral.characteristic.properties.rawValue & CBCharacteristicProperties.write.rawValue != 0) {
                    self.writeType = .withResponse  // 要是两个都有，将.withoutResponse覆盖，使用有回调的
                }
            }
        }
        
        let readServiceNum = self.readData.services[self.readPickerView.selectedRow(inComponent: 0)]
        let readCharNum = self.readData.chars[self.readPickerView.selectedRow(inComponent: 0)][self.readPickerView.selectedRow(inComponent: 1)]
        
        if (BlueToothCentral.readServiceNum != readServiceNum || BlueToothCentral.readCharNum != readCharNum) {
            
            flag = true
            readcolor = UIColor.systemGreen
            
            if readServiceNum == 0 { // 此时char肯定也是0的
                BlueToothCentral.readCharacteristic = nil
                
                BlueToothCentral.readServiceNum = 0
                BlueToothCentral.readCharNum = 0
            } else {
                let readService = BlueToothCentral.services[readServiceNum-1]
                
                BlueToothCentral.readCharacteristic = BlueToothCentral.characteristics[readService]![readCharNum-1]
                
                BlueToothCentral.readServiceNum = readServiceNum
                BlueToothCentral.readCharNum = readCharNum
            }
        }
        
        
        
        let notifyServiceNum = self.notifyData.services[self.notifyPickerView.selectedRow(inComponent: 0)]
        let notifyCharNum = self.notifyData.chars[self.notifyPickerView.selectedRow(inComponent: 0)][self.notifyPickerView.selectedRow(inComponent: 1)]
        
        if (BlueToothCentral.notifyServiceNum != notifyServiceNum || BlueToothCentral.notifyCharNum != notifyCharNum) {
            
            flag = true
            notifycolor = UIColor.systemGreen
            
            if notifyServiceNum == 0 {
                BlueToothCentral.notifyCharacteristic = nil
                
                BlueToothCentral.notifyServiceNum = 0
                BlueToothCentral.notifyCharNum = 0
            } else {
                let notifyService = BlueToothCentral.services[notifyServiceNum-1]
                
                BlueToothCentral.notifyCharacteristic = BlueToothCentral.characteristics[notifyService]![notifyCharNum-1]
                
                BlueToothCentral.notifyServiceNum = notifyServiceNum
                BlueToothCentral.notifyCharNum = notifyCharNum
            }
        }
        
        // 上面至少有一个变化，那么才更新
        if (flag) {
    //        let viewController = UIApplication.shared.keyWindow?.rootViewController!.storyboard?.instantiateViewController(withIdentifier: "MyViewController") as! ViewController
    //        viewController.correctBtn()
            
            //上面这个不行，上面这个实例化出来的是一个新的viewcontroller，而下面这个才是找到的
            let tabBarController = UIApplication.shared.keyWindow?.rootViewController as! UITabBarController
            
            ((tabBarController.selectedViewController as! UINavigationController).viewControllers[0] as! ViewController).correctBtn()
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            DispatchQueue.main.async {self.writeBackView.layer.borderColor = writecolor.cgColor
                self.readBackView.layer.borderColor = readcolor.cgColor
                self.notifyBackView.layer.borderColor = notifycolor.cgColor
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [unowned self] in
                UIView.animate(withDuration: 0.45) { [unowned self] in
                    self.writeBackView.layer.borderColor = UIColor.clear.cgColor
                    self.readBackView.layer.borderColor = UIColor.clear.cgColor
                    self.notifyBackView.layer.borderColor = UIColor.clear.cgColor
                }
            }
        }
    }
    
    func showErrorAlertWithTitle(_ title: String?, message: String?) {
        DispatchQueue.main.async {
            let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(ac, animated: true)
        }
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//         Get the new view controller using segue.destination.
//         Pass the selected object to the new view controller.
        
//        if segue.identifier == "closeChoose" {
//            writeService.resignFirstResponder()
//            writeChar.resignFirstResponder()
//            readService.resignFirstResponder()
//            readChar.resignFirstResponder()
//            notifyService.resignFirstResponder()
//            notifyChar.resignFirstResponder()
//        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        //当我执行返回的转场的时候（我是本controller指到上一个controller的exit按钮，然后选择上一个controller的返回方法，再写好这个segue的identifier，然后再本controller的返回按钮perform这个segue）。（也可以我这里的返回按钮直接指到上一个controller的exit）
        //当转场返回时，先执行这个，然后是上面的perpare，然后就是上一个controller的@IBAction func close(segue: UIStoryboardSegue) 。方法
        return true
    }
}

extension ChooseCharViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
//        let currentSelectedServicesNum =
        switch (pickerView.tag, component) {
        case (0, 0):   // 第一个0代表这个picker是给找write特征用的(即3个picker中的哪一个)，后一个0代表找服务，后一个若为1代表找特征。
            return writeData.services.count        // //需要加一，因为可以不选择写、读、通知特征
        case (0, 1):                               // 就是服务和特征各多加一行0
            return writeData.chars[self.writePIckerView.selectedRow(inComponent: 0)].count
        case (1, 0):   // 读
            return readData.services.count
        case (1, 1):
            return readData.chars[self.readPickerView.selectedRow(inComponent: 0)].count
        case (2, 0):   // 通知
            return notifyData.services.count
        case (2, 1):
            return notifyData.chars[self.notifyPickerView.selectedRow(inComponent: 0)].count
        default:
            break
        }
        
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch (pickerView.tag, component) {
        case (0, 0):   // 第一个0代表这个picker是给找write特征用的(即3个picker中的哪一个)，后一个0代表找服务，后一个若为1代表找特征。
            return "\(writeData.services[row])"
        case (0, 1):
            return "\(writeData.chars[self.writePIckerView.selectedRow(inComponent: 0)][row])"
        case (1, 0):   // 读
            return "\(readData.services[row])"
        case (1, 1):
            return "\(readData.chars[self.readPickerView.selectedRow(inComponent: 0)][row])"
        case (2, 0): // 通知
            return "\(notifyData.services[row])"
        case (2, 1):
            return "\(notifyData.chars[self.notifyPickerView.selectedRow(inComponent: 0)][row])"
        default:
            break
        }
        
        return ""
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch (pickerView.tag, component) {
        case (0, 0):    // 写
            self.writePIckerView.reloadComponent(1)
            fallthrough
        case (0, 1):
            self.writeBackView.layer.borderColor = UIColor.orange.cgColor
            self.readBackView.layer.borderColor = UIColor.clear.cgColor
            self.notifyBackView.layer.borderColor = UIColor.clear.cgColor
        case (1, 0):    // 读
            self.readPickerView.reloadComponent(1)
            fallthrough
        case (1, 1):
            self.readBackView.layer.borderColor = UIColor.orange.cgColor
            self.writeBackView.layer.borderColor = UIColor.clear.cgColor
            self.notifyBackView.layer.borderColor = UIColor.clear.cgColor
        case (2, 0):    // 通知
            self.notifyPickerView.reloadComponent(1)
            fallthrough
        case (2, 1):
            self.notifyBackView.layer.borderColor = UIColor.orange.cgColor
            self.writeBackView.layer.borderColor = UIColor.clear.cgColor
            self.readBackView.layer.borderColor = UIColor.clear.cgColor
        default:
            break
        }
    }
    
    func classifyChars() {
        for (serviceIndex, service) in BlueToothCentral.services.enumerated() {
            // 直接用添加元素前的索引，就不用-1了
            let writeSerNum = writeData.services.count
            let readSerNum = readData.services.count
            let notifySerNum = notifyData.services.count
            
            writeData.services.append(serviceIndex + 1)
            readData.services.append(serviceIndex + 1)
            notifyData.services.append(serviceIndex + 1)
            writeData.chars.append([Int]())
            readData.chars.append([Int]())
            notifyData.chars.append([Int]())
            
            if BlueToothCentral.writeServiceNum == serviceIndex + 1 {
                // 此处相当于减好1了，后面不需要再减
                self.formerWriteInPicker.0 = writeSerNum //此处不减1是因为是添加前的个数，添加后的个数是要减1的
            }
            if BlueToothCentral.readServiceNum == serviceIndex + 1 {
                self.formerReadInPicker.0 = readSerNum
            }
            if BlueToothCentral.notifyServiceNum == serviceIndex + 1 {
                self.formerNotifyInPicker.0 = notifySerNum
            }
            
            for (charIndex, char) in BlueToothCentral.characteristics[service]!.enumerated() {
                if (char.properties.rawValue & CBCharacteristicProperties.write.rawValue != 0) || (char.properties.rawValue & CBCharacteristicProperties.writeWithoutResponse.rawValue != 0) {
                    writeData.chars[writeSerNum].append(charIndex + 1)
                    
                    if self.formerWriteInPicker.0 != 0 {
                        if BlueToothCentral.writeCharNum == charIndex + 1 {
                            self.formerWriteInPicker.1 = self.writeData.chars[writeSerNum].count - 1
                        }
                    }
                }
                if char.properties.rawValue & CBCharacteristicProperties.read.rawValue != 0 {
                    readData.chars[readSerNum].append(charIndex + 1)
                    
                    if self.formerReadInPicker.0 != 0 {
                        if BlueToothCentral.readCharNum == charIndex + 1 {
                            self.formerReadInPicker.1 = self.readData.chars[readSerNum].count - 1
                        }
                    }
                }
                if char.properties.rawValue & CBCharacteristicProperties.notify.rawValue != 0 {
                    notifyData.chars[notifySerNum].append(charIndex + 1)
                    
                    if self.formerNotifyInPicker.0 != 0 {
                        if BlueToothCentral.notifyCharNum == charIndex + 1 {
                            self.formerNotifyInPicker.1 = self.notifyData.chars[notifySerNum].count - 1
                        }
                    }
                }
            }
            
            // 前面先把service都加上，但是如果这个services没有特定的特征，最后将其删掉
            if writeData.chars[writeSerNum].count == 0 {
                writeData.services.removeLast()
                writeData.chars.removeLast()
            }
            if readData.chars[readSerNum].count == 0 {
                readData.services.removeLast()
                readData.chars.removeLast()
            }
            if notifyData.chars[notifySerNum].count == 0 {
                notifyData.services.removeLast()
                notifyData.chars.removeLast()
            }
        }
    }
    
    
    
    func showCurrentChars() {
        // 暂时先这样，将这个函数放在viewdidload中的话，component为1的那个只能有一row，然后无法选择下面的row，所以我现在放在viewdidload中了，中间加个延时执行函数，里面刷新和选择component为1的值
//        self.writePIckerView.reloadAllComponents()
//        self.readPickerView.reloadAllComponents()
//        self.notifyPickerView.reloadAllComponents()
        
//        print("\(self.formerWriteInPicker.0) \(self.formerWriteInPicker.1)")
//        print("\(self.formerReadInPicker.0) \(self.formerReadInPicker.1)")
//        print("\(self.formerNotifyInPicker.0) \(self.formerNotifyInPicker.1)")
        self.writePIckerView.selectRow(self.formerWriteInPicker.0, inComponent: 0, animated: true)
        self.readPickerView.selectRow(self.formerReadInPicker.0, inComponent: 0, animated: true)
        self.notifyPickerView.selectRow(self.formerNotifyInPicker.0, inComponent: 0, animated: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [unowned self] in
            self.writePIckerView.reloadComponent(1)
            self.readPickerView.reloadComponent(1)
            self.notifyPickerView.reloadComponent(1)
            
            self.writePIckerView.selectRow(self.formerWriteInPicker.1, inComponent: 1, animated: true)
            self.readPickerView.selectRow(self.formerReadInPicker.1, inComponent: 1, animated: true)
            self.notifyPickerView.selectRow(self.formerNotifyInPicker.1, inComponent: 1, animated: true)
        }
    }
}

//extension ChooseCharViewController: UITextFieldDelegate {
//    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        if textField.text == "back" || textField.text == "BACK" {
//            self.performSegue(withIdentifier: "closeChoose", sender: nil)
//            return false
//        }
//        if textField == writeService {
//            writeChar.becomeFirstResponder()
//        } else if textField == writeChar {
//            readService.becomeFirstResponder()
//        } else if textField == readService {
//            readChar.becomeFirstResponder()
//        } else if textField == readChar {
//            notifyService.becomeFirstResponder()
//        } else if textField == notifyService {
//            notifyChar.becomeFirstResponder()
//        } else if textField == notifyChar {
//            doneAct(doneBtn)
//        }
//
//        return true
//    }
//}

extension ChooseCharViewController {
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override var keyCommands: [UIKeyCommand]? {
//        return [UIKeyCommand(input: "w", modifierFlags: .command, action: #selector(keyCommands(sender:)), discoverabilityTitle: "close")]
        return [UIKeyCommand(input: "w", modifierFlags: .command, action: #selector(keyCommands(sender:))), UIKeyCommand(input: "n", modifierFlags: .command, action: #selector(keyCommands(sender:)))]
    }
    
    @objc func keyCommands(sender: UIKeyCommand) {
        switch sender.input {
        case "w":
            self.performSegue(withIdentifier: "closeChoose", sender: nil)
        case "n":
            self.performSegue(withIdentifier: "closeChoose", sender: nil)
        default:
            break
        }
    }
}

