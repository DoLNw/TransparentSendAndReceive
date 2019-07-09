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
    @IBAction func dismiss(_ sender: UIButton) {
        print("Asdasd")
        self.performSegue(withIdentifier: "closeChoose", sender: nil)
//        self.dismiss(animated: true, completion: nil)
        
        print("qqqqqq")
    }
    
    var writeType: CBCharacteristicWriteType?
    
    @IBOutlet weak var doneBtn: UIButton!
    @IBAction func doneAct(_ sender: UIButton) {
        guard BlueToothCentral.peripheral != nil else {
            showErrorAlertWithTitle("Error", message: "请先连接")
            return
        }
        
        var debugMessage = ""
        var newChange = 0
        if writeService.text != "" || writeChar.text != "" {
            newChange += 1
        }
        if readService.text != "" || readChar.text != "" {
            newChange += 1
        }
        if notifyService.text != "" || notifyChar.text != "" {
            newChange += 1
        }
        var allConfirmed = 0
        
        if let writeServiceText = writeService.text, let writeCharText = writeChar.text, let writeServiceNum = Int(writeServiceText), let writeCharNum = Int(writeCharText) {
            if BlueToothCentral.services.count >= writeServiceNum && writeServiceNum >= 0 {
                let service = BlueToothCentral.services[writeServiceNum-1]
                if (BlueToothCentral.characteristics[service])!.count >= writeCharNum && writeCharNum >= 0 {
                    
                    if (BlueToothCentral.characteristics[service]![writeCharNum-1].properties.rawValue & CBCharacteristicProperties.write.rawValue) != 0 {
                        self.writeType = .withResponse
                        BlueToothCentral.characteristic = BlueToothCentral.characteristics[service]![writeCharNum-1]
                        debugMessage += "writeCharacteristic Ok!"
                        
                        BlueToothCentral.writeServiceNum = writeServiceNum
                        BlueToothCentral.writeCharNum = writeCharNum
                        
                        allConfirmed += 1
                    } else if (BlueToothCentral.characteristics[service]![writeCharNum-1].properties.rawValue & CBCharacteristicProperties.writeWithoutResponse.rawValue) != 0 {
                        self.writeType = .withoutResponse
                        BlueToothCentral.characteristic = BlueToothCentral.characteristics[service]![writeCharNum-1]
                        debugMessage += "writeCharacteristic Ok!"
                        
                        BlueToothCentral.writeServiceNum = writeServiceNum
                        BlueToothCentral.writeCharNum = writeCharNum
                        
                        allConfirmed += 1
                    }
                }
            }
        }
        
        if let readServiceText = readService.text, let readCharText = readChar.text, let readServiceNum = Int(readServiceText), let readCharNum = Int(readCharText) {
            if BlueToothCentral.services.count >= readServiceNum && readServiceNum >= 0 {
                let service = BlueToothCentral.services[readServiceNum-1]
                if (BlueToothCentral.characteristics[service])!.count >= readCharNum && readCharNum >= 0 && ((BlueToothCentral.characteristics[service]![readCharNum-1].properties.rawValue & CBCharacteristicProperties.read.rawValue) != 0) {
                    
                    BlueToothCentral.readCharacteristic = BlueToothCentral.characteristics[service]![readCharNum-1]
                    debugMessage += "\nreadCharacteristic Ok!"
                    
                    BlueToothCentral.readServiceNum = readServiceNum
                    BlueToothCentral.readCharNum = readCharNum
                    
                    allConfirmed += 1
                }
            }
        }
        
        if let notifyServiceText = notifyService.text, let notifyCharText = notifyChar.text, let notifyServiceNum = Int(notifyServiceText), let notifyCharNum = Int(notifyCharText) {
            if BlueToothCentral.services.count >= notifyServiceNum && notifyServiceNum >= 0 {
                let service = BlueToothCentral.services[notifyServiceNum-1]
                if (BlueToothCentral.characteristics[service])!.count >= notifyCharNum && notifyCharNum >= 0 && ((BlueToothCentral.characteristics[service]![notifyCharNum-1].properties.rawValue & CBCharacteristicProperties.notify.rawValue) != 0) {
                    
                    BlueToothCentral.peripheral.setNotifyValue(false, for: BlueToothCentral.notifyCharacteristic)
                    BlueToothCentral.notifyCharacteristic = BlueToothCentral.characteristics[service]![notifyCharNum-1]
                    BlueToothCentral.peripheral.setNotifyValue(true, for: BlueToothCentral.notifyCharacteristic)
                    debugMessage += "\nnotifyCharacteristic Ok!"
                    
                    BlueToothCentral.notifyServiceNum = notifyServiceNum
                    BlueToothCentral.notifyCharNum = notifyCharNum
                    
                    allConfirmed += 1
                }
            }
        }
        
        writeService.resignFirstResponder()
        writeChar.resignFirstResponder()
        readService.resignFirstResponder()
        readChar.resignFirstResponder()
        notifyService.resignFirstResponder()
        notifyChar.resignFirstResponder()
        
        if allConfirmed == newChange {
            self.performSegue(withIdentifier: "closeChoose", sender: nil)
        } else {
            showErrorAlertWithTitle("选择通知", message: debugMessage)
        }

    }
    
    @IBOutlet weak var writeService: UITextField!
    @IBOutlet weak var writeChar: UITextField!
    
    @IBOutlet weak var readService: UITextField!
    @IBOutlet weak var readChar: UITextField!
    
    @IBOutlet weak var notifyService: UITextField!
    @IBOutlet weak var notifyChar: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.writeService.delegate = self
        self.writeChar.delegate = self
        self.readService.delegate = self
        self.readChar.delegate = self
        self.notifyService.delegate = self
        self.notifyChar.delegate = self
        
        self.writeService.becomeFirstResponder()
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
        
        if segue.identifier == "closeChoose" {
            writeService.resignFirstResponder()
            writeChar.resignFirstResponder()
            readService.resignFirstResponder()
            readChar.resignFirstResponder()
            notifyService.resignFirstResponder()
            notifyChar.resignFirstResponder()
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        //当我执行返回的转场的时候（我是本controller指到上一个controller的exit按钮，然后选择上一个controller的返回方法，再写好这个segue的identifier，然后再本controller的返回按钮perform这个segue）。（也可以我这里的返回按钮直接指到上一个controller的exit）
        //当转场返回时，先执行这个，然后是上面的perpare，然后就是上一个controller的@IBAction func close(segue: UIStoryboardSegue) 。方法
        return true
    }
}

extension ChooseCharViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.text == "back" || textField.text == "BACK" {
            self.performSegue(withIdentifier: "closeChoose", sender: nil)
            return false
        }
        if textField == writeService {
            writeChar.becomeFirstResponder()
        } else if textField == writeChar {
            readService.becomeFirstResponder()
        } else if textField == readService {
            readChar.becomeFirstResponder()
        } else if textField == readChar {
            notifyService.becomeFirstResponder()
        } else if textField == notifyService {
            notifyChar.becomeFirstResponder()
        } else if textField == notifyChar {
            doneAct(doneBtn)
        }
        
        return true
    }
}

extension ChooseCharViewController {
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override var keyCommands: [UIKeyCommand]? {
        return [UIKeyCommand(input: "w", modifierFlags: .command, action: #selector(keyCommands(sender:)), discoverabilityTitle: "close")]
    }
    
    @objc func keyCommands(sender: UIKeyCommand) {
        switch sender.input {
        case "w":
            self.performSegue(withIdentifier: "closeChoose", sender: nil)
        default:
            break
        }
    }
}

