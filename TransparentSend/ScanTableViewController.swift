//
//  ScanTableViewController.swift
//  CameraCapture7
//
//  Created by JiaCheng on 2018/10/28.
//  Copyright © 2018 JiaCheng. All rights reserved.
//
//做到现在最心累的一点，就是在我手势退出此界面的时候，如果完成度不大于0.08，它自己是会取消的，取消之后，会先到viewdidappear此时view的frame是正常的，然后在马上要调用转场动画结束，此时view的frame也是正常的，然后估计i一秒不到view的frame自己变大了，难受，监听么我又搞不好，所以只能用timerSolve去检查是不是变了，变了的话马上改过来。i诶，无力之举，希望以后能过来改进。
//还有home退出在回来的时候height立马又变回全屏了。
import UIKit
import CoreBluetooth

class ScanTableViewController: UITableViewController {
    var timer: Timer?
    var timerSolve: Timer?
    var peripherales = [String]()
    var peripheralIDes = [CBPeripheral]()
    var temp = [CBPeripheral]()
    var tempStr = [String]()
    var isFirst = false
    
//    override var prefersStatusBarHidden: Bool {
//        return true
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //注意在手势转场没有成功的时候他会返回回来，这时候又出发一个willappear导致出错（又会创建一个timer，且界面消失是不会释放的要手动释放），所以加条件限制
        guard self.timer == nil else { return }
        isFirst = true
        if BlueToothCentral.isBlueOn {
            BlueToothCentral.centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
        BlueToothCentral.isFirstPer = true
//        DispatchQueue.main.asyncAfter(deadline: .now()+0.35) { [unowned self] in
//            //注意如果我手势出来此界面但是cancel掉了，那么过0.75秒此界面是不存在的，会有Attempted to read an unowned reference but the object was already deallocated导致出错,所以我要放在wiewdidappear里面
//            guard self.isViewLoaded else { return }
//            self.peripherales = ViewController.peripherals
//            self.peripheralIDes = ViewController.peripheralIDs
//            self.tableView.reloadData()
//        }
        
        //做到现在最心累的一点，就是在我手势退出此界面的时候，如果完成度不大于0.08，它自己是会取消的，取消之后，会先到viewdidappear此时view的frame是正常的，然后在马上要调用转场动画结束，此时view的frame也是正常的，然后估计i一秒不到view的frame自己变大了，难受，监听么我又搞不好，所以只能用timerSolve去检查是不是变了，变了的话马上改过来。i诶，无力之举，希望以后能过来改进。
        if self.timer == nil {
            self.timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
        }
    }
    @objc func solveSegue() {
        if self.view.frame.height == SCREEN_HEIGHT {
            self.view.frame = CGRect(x: 0, y: SCREEN_HEIGHT-SEGUED_HEIGHT, width: SCREEN_WIDTH, height: SEGUED_HEIGHT+100)
            timerSolve?.invalidate()
            //注意：timerSolve?.invalidate()之后，timerSolve并不会变为nil，所以要手动。还有如果不写这一句直接写timerSolve = nil，这个tiner是不会因为ARC消失的我目前也不知道为什么，这个是要注意的。
            timerSolve = nil
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        print("1")
//        print(self.view.frame)
//        guard self.timer != nil else { return }
//        DispatchQueue.main.asyncAfter(deadline: .now()+0.35) { [unowned self] in
            //注意如果我手势出来此界面但是cancel掉了，那么过0.75秒此界面是不存在的，会有Attempted to read an unowned reference but the object was already deallocated导致出错,所以我要放在wiewdidappear里面
            //而且由于didappear是要道动画全部放完还有有一点时间的，所以我不需要延时来做下面的事情了
//        self.view.frame = CGRect(x: 0, y: 367, width: 375, height: 400)
        guard isFirst else {
            if timerSolve == nil {
                self.timerSolve = Timer.scheduledTimer(timeInterval: -1, target: self, selector: #selector(solveSegue), userInfo: nil, repeats: true)
            }
            return
        }
        isFirst = false
        self.temp = BlueToothCentral.peripheralIDs
        self.tempStr = BlueToothCentral.peripherals
        // 因为第一次load，所以本身没有任何东西，下面第一个for可以去掉
//        for per in self.peripheralIDes {
//            if !self.temp.contains(per) {
//                let index = self.peripheralIDes.index(of: per)!
//                //                tableView.setEditing(, animated: )
//                self.peripheralIDes.remove(at: index)
//                self.peripherales.remove(at: index)
//                tableView.deleteRows(at: [IndexPath(item: index, section: 0)], with: .automatic)
//            }
//        }
        for per in self.temp {
            if !self.peripheralIDes.contains(per) {
                let index = self.temp.firstIndex(of: per)!
                self.peripheralIDes.insert(per, at: 0)
                self.peripherales.insert(self.tempStr[index], at: 0)
                tableView.insertRows(at: [IndexPath(item: 0, section: 0)], with: .automatic)
            }
        }
//        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        BlueToothCentral.centralManager.stopScan()
        BlueToothCentral.peripherals = []
        BlueToothCentral.peripheralIDs = []
        self.peripherales = []
        self.peripheralIDes = []
        self.temp = []
        guard let timer = self.timer else { return }
        timer.invalidate()
    }
    
    @objc func timerFired () {
//        self.view.frame = CGRect(x: 0, y: 367, width: 375, height: 400)
//        print("2")
//        print(self.view.frame)
        self.temp = BlueToothCentral.peripheralIDs
        self.tempStr = BlueToothCentral.peripherals
        for per in self.peripheralIDes {
            if !self.temp.contains(per) {
                let index = self.peripheralIDes.firstIndex(of: per)!
//                tableView.setEditing(, animated: )
                self.peripheralIDes.remove(at: index)
                self.peripherales.remove(at: index)
                tableView.deleteRows(at: [IndexPath(item: index, section: 0)], with: .automatic)
            }
        }
        for per in self.temp {
            if !self.peripheralIDes.contains(per) {
                let index = self.temp.firstIndex(of: per)!
                self.peripheralIDes.insert(per, at: 0)
                self.peripherales.insert(self.tempStr[index], at: 0)
                tableView.insertRows(at: [IndexPath(item: 0, section: 0)], with: .automatic)
            }
        }
//        print(ViewController.peripherals.count)
//        self.tableView.reloadData()
        DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
            BlueToothCentral.isFirstPer = true
            if BlueToothCentral.isBlueOn {
                BlueToothCentral.centralManager.scanForPeripherals(withServices: nil, options: nil)
            }
        }
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    //注意，下面两个都是不会随着上移消失的，我估计类似于d通讯录里的样子，所以我直接在那些前面加一个view算了
//    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        let activity = UIActivityIndicatorView(style: .gray)
//        activity.frame = CGRect(x: 10, y: 10, width: 10, height: 10)
//        activity.startAnimating()
//        return activity
//    }
//    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        return "ewqeq"
//    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.peripherales.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScanCell", for: indexPath)
        
//        cell.backgroundColor = UIColor.darkGray
        cell.textLabel?.text = self.peripherales[indexPath.row]
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: true)
        guard self.peripherales[indexPath.row] != "Unknown" else { return }
        BlueToothCentral.centralManager.connect(self.peripheralIDes[indexPath.row], options: nil)
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}


extension ScanTableViewController {
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override var keyCommands: [UIKeyCommand]? {
        return [UIKeyCommand(input: "w", modifierFlags: .command, action: #selector(keyCommands(sender:)), discoverabilityTitle: "close"), UIKeyCommand(input: "1", modifierFlags: .command, action: #selector(keyCommands(sender:)), discoverabilityTitle: "connect 1"), UIKeyCommand(input: "!", modifierFlags: .command, action: #selector(keyCommands(sender:)), discoverabilityTitle: "connect 2"), UIKeyCommand(input: "!", modifierFlags: .command, action: #selector(keyCommands(sender:)), discoverabilityTitle: "connect 2"), UIKeyCommand(input: "3", modifierFlags: .command, action: #selector(keyCommands(sender:)), discoverabilityTitle: "connect 3"), UIKeyCommand(input: "4", modifierFlags: .command, action: #selector(keyCommands(sender:)), discoverabilityTitle: "connect 4"), UIKeyCommand(input: "5", modifierFlags: .command, action: #selector(keyCommands(sender:)), discoverabilityTitle: "connect 5")]
    }
    
    @objc func keyCommands(sender: UIKeyCommand) {
        switch sender.input {
        case "w":
            self.navigationController?.popViewController(animated: true)
        case "1":
            if self.peripheralIDes.count >= 1 {
                self.tableView.selectRow(at: IndexPath(row:0, section: 0), animated: true, scrollPosition: .none)
                BlueToothCentral.centralManager.connect(self.peripheralIDes[0], options: nil)
            }
        case "2":
            if self.peripheralIDes.count >= 2 {
                self.tableView.selectRow(at: IndexPath(row: 1, section: 0), animated: true, scrollPosition: .none)
                BlueToothCentral.centralManager.connect(self.peripheralIDes[1], options: nil)
            }
        case "3":
            if self.peripheralIDes.count >= 3 {
                self.tableView.selectRow(at: IndexPath(row: 2, section: 0), animated: true, scrollPosition: .none)
                BlueToothCentral.centralManager.connect(self.peripheralIDes[2], options: nil)
            }
        case "4":
            if self.peripheralIDes.count >= 4 {
                self.tableView.selectRow(at: IndexPath(row: 3, section: 0), animated: true, scrollPosition: .none)
                BlueToothCentral.centralManager.connect(self.peripheralIDes[3], options: nil)
            }
        case "5":
            if self.peripheralIDes.count >= 5 {
                self.tableView.selectRow(at: IndexPath(row: 4, section: 0), animated: true, scrollPosition: .none)
                BlueToothCentral.centralManager.connect(self.peripheralIDes[4], options: nil)
            }
        default:
            break
        }
    }
}
