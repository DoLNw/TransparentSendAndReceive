//
//  TransitionAnimator.swift
//  CameraCapture7
//
//  Created by JiaCheng on 2018/10/28.
//  Copyright © 2018 JiaCheng. All rights reserved.
//

import UIKit

class TransitionAnimatorBack: NSObject, UIViewControllerAnimatedTransitioning {
    weak var transitionContext: UIViewControllerContextTransitioning?
    weak var view: ScanTableViewController!
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
        
        let containerView = transitionContext.containerView
        let fromVC = transitionContext.viewController(forKey: .from) as! ScanTableViewController
        let toVC = transitionContext.viewController(forKey: .to) as! ViewController
        view = fromVC
        let subViews = containerView.subviews
//        print(subViews.count)
//        print("containerView.subviews.count: \(subViews.count)")
//        print(containerView.subviews)
        let tempView = subViews[min(subViews.count, max(0, subViews.count-2))]
        containerView.addSubview(toVC.view)
//注意添加同一个view个数不会增加的但是view的上下层会是最会改变的这是关键的地方。
        containerView.addSubview(tempView)
//        toVC.view.alpha = 0
        //不加下面这句的话这个view小时的时候会alpha渐渐变没有
        containerView.addSubview(fromVC.view)
//        print(containerView.subviews.count)
//        print(containerView.subviews)
        UIView.animate(withDuration: self.transitionDuration(using: transitionContext), delay: 0, options: .curveEaseOut, animations: {
            tempView.alpha = 1
            tempView.transform = .identity
//            toVC.view.alpha = 1
            fromVC.view.transform = .identity
        }){ (_) in
//            print(fromVC.view.frame)
            if !(self.transitionContext?.transitionWasCancelled)! {
                toVC.view.isHidden = false
                tempView.removeFromSuperview()
                self.transitionContext?.completeTransition(true)
            } else {
//                print("cancel")
                toVC.view.isHidden = true
//                toVC.view.alpha = 1
//                fromVC.view.frame  = CGRect(x: 0, y: 667, width: 375, height: 400)
//                fromVC.view.transform = CGAffineTransform(translationX: 0, y: -300)
                self.transitionContext?.completeTransition(false)
            }
        }
    }
    func animationEnded(_ transitionCompleted: Bool) {
//        print(self.view.view.frame)
//        print("Transition ended.")
    }
    
}
