//
//  PresentTransition.swift
//  capa
//
//  Created by 秦 道平 on 15/1/8.
//  Copyright (c) 2015年 秦 道平. All rights reserved.
//

import Foundation
import UIKit

/// MARK: - Perspective
func wk_make_perspective(center:CGPoint,disz:CGFloat)->CATransform3D{
    var transform = CATransform3DIdentity
    transform.m34=1.0 / -disz
    return transform
}
func wk_perspective(t:CATransform3D,center:CGPoint,disz:CGFloat)->CATransform3D{
    return CATransform3DConcat(t, wk_make_perspective(center, disz))
}
func wk_perspective_simple(t:CATransform3D)->CATransform3D{
    return wk_perspective(t, CGPointMake(0.0, 0.0 ), 1500.0)
}
func wk_perspactive_simple_with_rotate(degree:CGFloat)->CATransform3D{
    let rotate = CGFloat(M_PI) * degree / 180.0
    return wk_perspective_simple(CATransform3DMakeRotation(rotate, 1.0, 0.0, 0.0));
}
/// MARK: - Animation
/// 使用 Present 弹出层时的动画
class DismissTransition: NSObject,UIViewControllerAnimatedTransitioning {
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval  {
        return 0.3
    }
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let toVc = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        let fromVc = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
        toVc.view.layer.transform = wk_perspactive_simple_with_rotate(10.0)
        let containerView = transitionContext.containerView()
        containerView.addSubview(toVc.view)
        let duration = self.transitionDuration(transitionContext)
        UIView.animateWithDuration(duration, animations: { () -> Void in
            toVc.view.layer.transform = CATransform3DIdentity
            fromVc.view.transform = CGAffineTransformMakeTranslation(0.0, UIScreen.mainScreen().bounds.size.height)
            }) { (completed) -> Void in
                transitionContext.completeTransition(true)
        }
    }
}
/// 弹出层回来时的动画
class PresentTransition : NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval {
        return 0.3
    }
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let toVc = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        let fromVc = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
        toVc.view.transform = CGAffineTransformMakeTranslation(0.0, UIScreen.mainScreen().bounds.size.height)
        let containerView = transitionContext.containerView()
        containerView.addSubview(toVc.view)
        let duration = self.transitionDuration(transitionContext)
        UIView.animateWithDuration(duration, animations: { () -> Void in
            toVc.view.transform = CGAffineTransformIdentity
            fromVc.view.layer.transform = wk_perspactive_simple_with_rotate(10.0)
            }) { (completed) -> Void in
                fromVc.view.layer.transform = CATransform3DIdentity
                transitionContext.completeTransition(true)
        }
    }
}
