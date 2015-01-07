//
//  CameraTransition.swift
//  capa
//
//  Created by 秦 道平 on 14/12/6.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
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
class WorkspaceToPreviewPushTransition:NSObject,UIViewControllerAnimatedTransitioning {
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval {
        return 0.3
    }
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let toVc = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)! as WorkPreviewViewController
        let fromVc = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)! as WorkspaceViewController
        let containerView = transitionContext.containerView()
        let toVcFrame = transitionContext.finalFrameForViewController(toVc)
        let duration = self.transitionDuration(transitionContext)
        
        containerView.addSubview(toVc.view)
        toVc.view.alpha = 0.0
        
        let image = fromVc.editing_photo!.originalImage!
        let start_frame = fromVc.editing_cell_frame!
        let snap_image_view = UIImageView(image: image)
        snap_image_view.frame = start_frame
        snap_image_view.contentMode = UIViewContentMode.ScaleAspectFill
        containerView.addSubview(snap_image_view)
        ///计算图片在 preview 中的开始位置
        let image_width = image.size.width
        let image_height = image.size.height
        var target_image_width:CGFloat = 0.0
        var target_image_height:CGFloat = 0.0
        if image_width >= image_height {
            target_image_width = toVcFrame.size.width
            target_image_height = target_image_width * image_height / image_width
        }
        else{
            target_image_height = toVcFrame.size.height
            target_image_width = target_image_height * image_width / image_height
        }
        var target_x = (toVcFrame.size.width - target_image_width) / 2.0
        var target_y = (toVcFrame.size.height - target_image_height) / 2.0 + 64.0
        
        UIView.animateWithDuration(duration, animations: { () -> Void in
            snap_image_view.frame = CGRectMake(target_x, target_y, target_image_width, target_image_height)
            toVc.view.alpha = 1.0
        }) { (completed) -> Void in
            snap_image_view.removeFromSuperview()
            toVc.view.alpha = 1.0
            transitionContext.completeTransition(true)
        }
    }
}
