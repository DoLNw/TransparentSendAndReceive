//
//  ChooseCharViewController.swift
//  TransparentSend
//
//  Created by JiaCheng on 2019/6/22.
//  Copyright © 2019 JiaCheng. All rights reserved.
//

import UIKit

class ChooseCharViewController: UIViewController {
    @IBAction func dismiss(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func doneAct(_ sender: UIButton) {
        var debugMessage = ""
        
        if let writeServiceText = writeService.text, let writeCharText = writeChar.text, let writeServiceNum = Int(writeServiceText), let writeCharNum = Int(writeCharText) {
            if BlueToothCentral.services.count >= writeServiceNum - 1 && writeServiceNum >= 0 {
                let service = BlueToothCentral.services[writeServiceNum-1]
                if (BlueToothCentral.characteristics[service])!.count >= writeCharNum-1 && writeCharNum >= 0 {
                    BlueToothCentral.characteristic = BlueToothCentral.characteristics[service]![writeCharNum-1]
                    debugMessage += "writeCharacteristic Ok!"
                }
            }
        }
        if let readServiceText = readService.text, let readCharText = readChar.text, let readServiceNum = Int(readServiceText), let readCharNum = Int(readCharText) {
            if BlueToothCentral.services.count >= readServiceNum - 1 && readServiceNum >= 0 {
                let service = BlueToothCentral.services[readServiceNum-1]
                if (BlueToothCentral.characteristics[service])!.count >= readCharNum-1 && readCharNum >= 0 {
                    BlueToothCentral.readCharacteristic = BlueToothCentral.characteristics[service]![readCharNum-1]
                    debugMessage += "\nreadCharacteristic Ok!"
                }
            }
        }
        if let notifyServiceText = notifyService.text, let notifyCharText = notifyChar.text, let notifyServiceNum = Int(notifyServiceText), let notifyCharNum = Int(notifyCharText) {
            if BlueToothCentral.services.count >= notifyServiceNum - 1 && notifyServiceNum >= 0 {
                let service = BlueToothCentral.services[notifyServiceNum-1]
                if (BlueToothCentral.characteristics[service])!.count >= notifyCharNum-1 && notifyCharNum >= 0 {
                    BlueToothCentral.peripheral.setNotifyValue(false, for: BlueToothCentral.notifyCharacteristic)
                    BlueToothCentral.notifyCharacteristic = BlueToothCentral.characteristics[service]![notifyCharNum-1]
                    BlueToothCentral.peripheral.setNotifyValue(true, for: BlueToothCentral.notifyCharacteristic)
                    debugMessage += "\nnotifyCharacteristic Ok!"
                }
            }
        }
        
        showErrorAlertWithTitle("选择完成", message: debugMessage)
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
    }
    
    func showErrorAlertWithTitle(_ title: String?, message: String?) {
        DispatchQueue.main.async {
            let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(ac, animated: true)
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
