//
//  TransitionAnimator.swift
//  CameraCapture7
//
//  Created by JiaCheng on 2018/10/28.
//  Copyright © 2018 JiaCheng. All rights reserved.
//

import UIKit

class TransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    weak var transitionContext: UIViewControllerContextTransitioning?
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
        
        let containerView = transitionContext.containerView
        let fromVC = transitionContext.viewController(forKey: .from) as! ViewController
        let toVC = transitionContext.viewController(forKey: .to) as! ScanTableViewController
//        containerView.addSubview(fromVC.view)
        let tempView = fromVC.view.snapshotView(afterScreenUpdates: false)!//如果此处为true，那么在动画没有完成前，两个controller都是活动的，此时下面一句hidden后我的tempView就变黑了，在fromvc活动时是会实时更新的
        tempView.clipsToBounds = true
        fromVC.view.isHidden = true
//        print(containerView.subviews)
//        print(containerView.subviews.count)
        containerView.addSubview(tempView)
        containerView.addSubview(toVC.view)
//        print(containerView.subviews)
        //本来四周都是圆角，所以给它长度高一点不显示底部圆角
        toVC.view.frame = CGRect(x: 0, y: SCREEN_HEIGHT, width: SCREEN_WIDTH, height: SEGUED_HEIGHT+100)
        UIView.animate(withDuration: self.transitionDuration(using: transitionContext), delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.1, options: .curveEaseIn, animations: {
            //圆角h也是可以动画的。
            //UIReplicantView的backgroundcolor不能修改的吗？为什么没用只有修改alpha才可以稍稍变灰
//            tempView.backgroundColor = UIColor.gray
//            tempView.layer.backgroundColor = UIColor.gray.cgColor
            tempView.alpha = 0.5
//            tempView.layer.cornerRadius = 15
//            toVC.view.frame = CGRect(x: 0, y: 367, width: 375, height: 400)
            toVC.view.transform = CGAffineTransform(translationX: 0, y: -SEGUED_HEIGHT)
//            tempView.transform = CGAffineTransform(scaleX: 0.95, y: 0.93)
            tempView.transform = CGAffineTransform(translationX: 0, y: 0)
        }) { (_) in
            if !(self.transitionContext?.transitionWasCancelled)! {
                self.transitionContext?.completeTransition(true)
            } else {
                self.transitionContext?.completeTransition(false)
                fromVC.view.isHidden = false
                tempView.removeFromSuperview()
            }
        }
    }
    func animationEnded(_ transitionCompleted: Bool) {
//        print("Transition ended.")
    }
    
}
