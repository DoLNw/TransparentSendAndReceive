//
//  IntentHandler.swift
//  SiriIntent
//
//  Created by JiaCheng on 2018/12/15.
//  Copyright © 2018 JiaCheng. All rights reserved.
//

import Intents
import CoreBluetooth

// As an example, this class is set up to handle Message intents.
// You will want to replace this or add other intents as appropriate.
// The intents you wish to handle must be declared in the extension's Info.plist.

// You can test your example integration by saying things to Siri like:
// "Send a message using <myApp>"
// "<myApp> John saying hello"
// "Search for messages in <myApp>"

class IntentHandler: INExtension, INSendMessageIntentHandling, INSearchForMessagesIntentHandling, INSetMessageAttributeIntentHandling, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral!
    var isSent = false
    
    override func handler(for intent: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.
        
        return self
    }
    
    // MARK: - INSendMessageIntentHandling
    
    // Implement resolution methods to provide additional information about your intent (optional).
    func resolveRecipients(for intent: INSendMessageIntent, with completion: @escaping ([INSendMessageRecipientResolutionResult]) -> Void) {
        if let recipients = intent.recipients {
            
            // If no recipients were provided we'll need to prompt for a value.
            if recipients.count == 0 {
                completion([INSendMessageRecipientResolutionResult.needsValue()])
                return
            }
            
            var resolutionResults = [INSendMessageRecipientResolutionResult]()
            for recipient in recipients {
                let matchingContacts = [recipient] // Implement your contact matching logic here to create an array of matching contacts
                switch matchingContacts.count {
                case 2  ... Int.max:
                    // We need Siri's help to ask user to pick one from the matches.
                    resolutionResults += [INSendMessageRecipientResolutionResult.disambiguation(with: matchingContacts)]
                    
                case 1:
                    // We have exactly one matching contact
                    resolutionResults += [INSendMessageRecipientResolutionResult.success(with: recipient)]
                    
                case 0:
                    // We have no contacts matching the description provided
                    resolutionResults += [INSendMessageRecipientResolutionResult.unsupported()]
                    
                default:
                    break
                    
                }
            }
            completion(resolutionResults)
        }
    }
    
    func resolveContent(for intent: INSendMessageIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        if let text = intent.content, !text.isEmpty {
            self.centralManager = CBCentralManager(delegate: self, queue: nil)
            //注意给peripheral也要设置代理不要忘记。
//            print(self.centralManager)
            print(self.centralManager.state)
            completion(INStringResolutionResult.success(with: text))
        } else {
            completion(INStringResolutionResult.needsValue())
        }
    }
    
    // Once resolution is completed, perform validation on the intent and provide confirmation (optional).
    
    func confirm(intent: INSendMessageIntent, completion: @escaping (INSendMessageIntentResponse) -> Void) {
        // Verify user is authenticated and your app is ready to send a message.
        
        let userActivity = NSUserActivity(activityType: NSStringFromClass(INSendMessageIntent.self))
        let response = INSendMessageIntentResponse(code: .ready, userActivity: userActivity)
        completion(response)
    }
    
    // Handle the completed intent (required).
    
    func handle(intent: INSendMessageIntent, completion: @escaping (INSendMessageIntentResponse) -> Void) {
        // Implement your application logic to send a message here.
        
        let userActivity = NSUserActivity(activityType: NSStringFromClass(INSendMessageIntent.self))
        
//        if BlueToothCentral.characteristic != nil {
//        BlueToothCentral.peripheral.writeValue("1".data(using: .utf8)!, for: BlueToothCentral.characteristic, type: .withoutResponse)

//        if self.centralManager.state == .poweredOn {
//            self.centralManager.scanForPeripherals(withServices: nil, options: nil)
//            print("AS")
//        } else {
//            print("qwe")
//        }
//        } else {
//            response = INSendMessageIntentResponse(code: .failure, userActivity: userActivity)
//        }
//
        var response = INSendMessageIntentResponse(code: .failure, userActivity: userActivity)
//        response.sentMessage = INMessage(identifier: "1", conversationIdentifier: nil, content: nil, dateSent: nil, sender: nil, recipients: nil, groupName: nil, messageType: .activitySnippet)
        if isSent {
            response = INSendMessageIntentResponse(code: .success, userActivity: userActivity)
        }
        completion(response)
    }
    
    // Implement handlers for each intent you wish to handle.  As an example for messages, you may wish to also handle searchForMessages and setMessageAttributes.
    
    // MARK: - INSearchForMessagesIntentHandling
    
    func handle(intent: INSearchForMessagesIntent, completion: @escaping (INSearchForMessagesIntentResponse) -> Void) {
        // Implement your application logic to find a message that matches the information in the intent.
        
        let userActivity = NSUserActivity(activityType: NSStringFromClass(INSearchForMessagesIntent.self))
        let response = INSearchForMessagesIntentResponse(code: .success, userActivity: userActivity)
        // Initialize with found message's attributes
        response.messages = [INMessage(
            identifier: "identifier",
            content: "I am so excited about SiriKit!",
            dateSent: Date(),
            sender: INPerson(personHandle: INPersonHandle(value: "sarah@example.com", type: .emailAddress), nameComponents: nil, displayName: "Sarah", image: nil,  contactIdentifier: nil, customIdentifier: nil),
            recipients: [INPerson(personHandle: INPersonHandle(value: "+1-415-555-5555", type: .phoneNumber), nameComponents: nil, displayName: "John", image: nil,  contactIdentifier: nil, customIdentifier: nil)]
            )]
        completion(response)
    }
    
    // MARK: - INSetMessageAttributeIntentHandling
    
    func handle(intent: INSetMessageAttributeIntent, completion: @escaping (INSetMessageAttributeIntentResponse) -> Void) {
        // Implement your application logic to set the message attribute here.
        
        let userActivity = NSUserActivity(activityType: NSStringFromClass(INSetMessageAttributeIntent.self))
        let response = INSetMessageAttributeIntentResponse(code: .success, userActivity: userActivity)

        completion(response)
        //注意：运行到这个completion，Siri程序全部结束，所以你这个程序变量什么的全部释放了。相反从Siri识别到你这个app的领域、intent之后，你这个程序已经开始执行了，所以centralmanager的创建扫描等等其实可以直接从resolve（对传递来的信息处理确认的时候就可以开始了）
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            print("On")
        default:
            print("no")
        }
    }
//    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
//        print("Scan")
//        print(peripheral.name)
//    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print(String(describing: peripheral.name))
        if peripheral.name ==  "DoLNw" {
            self.peripheral = peripheral
            centralManager.connect(peripheral, options: nil)
            central.stopScan()
            //很奇怪的是为什么下面的代理都会被触发两遍呢？？？然后第二天貌似又都是触发一遍了？
        }
    }
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("connected")
        //注意给peripheral也要设置代理不要忘记。
        self.peripheral.delegate = self
        self.peripheral.discoverServices(nil)
    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("ser")
        self.peripheral.discoverCharacteristics(nil, for: (peripheral.services?.first)!)
    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("char")
        self.peripheral.writeValue("1".data(using: .utf8)!, for: (service.characteristics?.first)!, type: .withoutResponse)
        self.isSent = true
        print("send")
    }
}
