//
//  Transition.swift
//  CameraCapture7
//
//  Created by JiaCheng on 2018/10/28.
//  Copyright © 2018 JiaCheng. All rights reserved.
//

import UIKit

let SCREEN_WIDTH = UIScreen.main.bounds.size.width
let SCREEN_HEIGHT = UIScreen.main.bounds.size.height
//scanTableViewController的长度只要给下面的改值就好
let SEGUED_HEIGHT = UIScreen.main.bounds.size.height/2+100


class Transition: NSObject, UINavigationControllerDelegate, UIViewControllerTransitioningDelegate, UIGestureRecognizerDelegate {
    @IBOutlet weak var navigationController: UINavigationController!
    var interactionController: UIPercentDrivenInteractiveTransition?
    var isPanGestureInteration = false
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if operation == .push && toVC is ScanTableViewController {
            return TransitionAnimator()
        } else if operation == .pop && fromVC is ScanTableViewController {
            return TransitionAnimatorBack()
        } else {
            return nil
        }
    }
    
    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return self.interactionController
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panned(gestureRecognizer:)))
        self.navigationController.view.addGestureRecognizer(panGesture)
        //        let panEdgeGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(panned(gestureRecognizer:)))
        //       panEdgeGesture.edges = .left
        //        self.navigationController.view.addGestureRecognizer(panEdgeGesture)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        tapGesture.delegate = self
        self.navigationController.view.addGestureRecognizer(tapGesture)
        //        self.navigationController.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    //解决tableView点击事件跟手势冲突解决.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        //可选链的缘故，导致输出的是Bool？
        //        let translation = (gestureRecognizer as! UITapGestureRecognizer).location(in: self.navigationController!.view)
        //        print(self.navigationController!.view.frame)
        //        print(translation)
        //        if translation.y <= self.navigationController!.view.frame.height-300 {
        //            print("True")
        //            return true
        //        }
        //        print("false")
        //        return false
        //        if (touch.view?.isKind(of: UITableView.self))! {
        //下面就是还有一个装了uiactivityIndicator的不能点击，其它的都差不多了。
        if NSStringFromClass((touch.view?.classForCoder)!) == "UITableViewCellContentView" || touch.view is UITableView || touch.view is UILabel{
            //            print("true")
            return false
        } else {
            //            print("false")
            return true
        }
    }
    //    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    //        return true
    //    }
    @objc func tapped(_ gestureRecognizer: UITapGestureRecognizer) {
        if (self.navigationController?.viewControllers.count)! > 1 {
//            let translation = gestureRecognizer.location(in: self.navigationController!.view)
            //            print(self.navigationController!.view.frame)
            //            print(translation)
//            if translation.y <= SCREEN_HEIGHT/2-(SEGUED_HEIGHT-SCREEN_HEIGHT/2) {
            self.navigationController?.popViewController(animated: true)
//            }
        }
    }
    
    var recordPopOrPush = true
    @objc func panned(gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            self.interactionController = UIPercentDrivenInteractiveTransition()
            
            if (self.navigationController?.viewControllers.count)! > 1 {
                recordPopOrPush = false
                isPanGestureInteration = true
                self.navigationController?.popViewController(animated: true)
            } else {
                //                self.navigationController.topViewController?.performSegue(withIdentifier: "pushid", sender: nil)
                //确保在没有连接的情况下可以打开连接界面进行连接，如果已有连接了，这个界面就不出来了。这样就确保一次连接一个了。
//                let location = gestureRecognizer.location(in: self.navigationController.view)
                if BlueToothCentral.peripheral == nil && BlueToothCentral.isBlueOn {
                    //加下面这个横屏划不上来了，因为一来没有viewcontroller的view读取height， 二来没有实现监听横竖屏代理
//                     && (location.y > SCREEN_HEIGHT * 0.75)
                    isPanGestureInteration = true
                    recordPopOrPush = true
                    let scanTableController = self.navigationController.storyboard?.instantiateViewController(withIdentifier: "ScanTableController") as! ScanTableViewController
                    self.navigationController?.pushViewController(scanTableController, animated: true)
                }
            }
            
        case .changed:
            guard self.isPanGestureInteration else { return }
            
            let translation = gestureRecognizer.translation(in: self.navigationController!.view)
            let completionProgress = (recordPopOrPush ? -translation.y : translation.y) / (SCREEN_HEIGHT-50)
            //            print(completionProgress)
            self.interactionController?.update(completionProgress)
            if completionProgress == 1.0 {
                self.interactionController?.finish()
            }
            //            self.interactionController?.completionSpeed = 1-completionProgress
            //            print(self.interactionController?.percentComplete)
            //            print(self.interactionController?.completionSpeed)
        //            self.interactionController?.update(0.5)
        case .ended:
            isPanGestureInteration = false
            //这是判断速度为0才取消其它都完成
            //            if (gestureRecognizer.velocity(in: self.navigationController!.view).x > 0) {
            //                self.interactionController?.finish()
            //
            ////                print(self.interactionController?.percentComplete)
            //            } else {
            //                self.interactionController?.cancel()
            //            }
            
            if (self.interactionController?.percentComplete)! > CGFloat(0.08) {
                self.interactionController?.finish()
            } else {
                self.interactionController?.cancel()
            }
            
            self.interactionController = nil
            
        default:
            print(4)
            self.interactionController?.cancel()
            self.interactionController = nil
        }
    }}
