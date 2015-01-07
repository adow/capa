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
/// 从 WorkspaceViewController 导航到 WorkPreviewViewController
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
        
        ///从 collectionView 中找到当前查看那个图片，然后为这个cell创建一个快照的view,当然他不是对直接对这个cell做takeSnap,
        ///因为那样的图形在缩放时会糊掉，直接在 containerView 中创建一个 UIImageView，放在和这个cell 一样的位置，
        ///里面的图片就是cell里对应的原图，动画时，将这个 UIImageView 放大到最终 WorkPreviewViewController 中这个图片显示的一样的位置
        let image = fromVc.editing_photo!.originalImage!
        let start_frame = fromVc.editing_cell_frame! ///开始的位置就是cell在整个view中的位置
        let snap_image_view = UIImageView(image: image)
        snap_image_view.frame = start_frame
        snap_image_view.contentMode = UIViewContentMode.ScaleAspectFill
        containerView.addSubview(snap_image_view)
        ///计算图片在 preview 中的开始位置
        ///当进入 WorkPreviewViewController 时，这个图片会显示在中间，所以我们的过渡动画图层就缩放到这个位置
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
        var target_y = (toVcFrame.size.height - target_image_height) / 2.0 + 64.0 ///由于进入vc后有导航的位置，所以要往下面
        
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
/// 从 WorkPreviewViewController 回到 WorkspaceViewController 的动画
class PreviewToWorkspacePopTransition:NSObject,UIViewControllerAnimatedTransitioning {
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval {
        return 0.3
    }
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let toVc = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)! as WorkspaceViewController
        let fromVc = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)! as WorkPreviewViewController
        let containerView = transitionContext.containerView()
        let toVcFrame = transitionContext.finalFrameForViewController(toVc)
        let duration = self.transitionDuration(transitionContext)
        
        containerView.addSubview(toVc.view)
        toVc.view.alpha = 0.0
        
        /// 从 WorkPreviewViewController 到 WorkspaceViewController 的动画中，过渡层动画 UIImageView 的图片来自 WorkPreViewViewController 中 的正在编辑(显示)图片的原图，他现在在 view 中的位置就是开始的位置;
        /// 我们要知道回到 WorkspaceViewController 时，对应的这个 cell 的位置, 由于 WorkPreViewController 和 WorkspaceViewController 的正在编辑(查看) 的照片索引是一样的，所以我们能知道这个 cell的 indexPath;
        /// 但是 WorkPreviewViewController 中可以滚动查看其他图片，所以我们正在查看的正在图片可能已经不在 WorksapceViewController 的 collectionView 的当前可见范围内了，这就要求我们在滚动 WorkPreviewViewController 中图片的时候，同步更新 WorkspaceViewController 中正在编辑(查看) 的图片
        let image = fromVc.editing_photo!.originalImage!
        let snap_image_view = UIImageView(image: image)
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
        var target_y = (toVcFrame.size.height - target_image_height) / 2.0
        snap_image_view.frame = CGRectMake(target_x, target_y, target_image_width, target_image_height)
        
        UIView.animateWithDuration(duration, animations: { () -> Void in
            toVc.view.alpha = 1.0
            let snap_image_view_frame_target = toVc.editing_cell_frame! /// 由于 WorkPreviewViewController 中操作图片滚动时会让 WorkspaceViewController 同步正在编辑(查看)的位置，所以可以知道 WorkspaceViewController 中对应的 cell 现在的位置
            snap_image_view.frame = snap_image_view_frame_target
        }) { (completed) -> Void in
            snap_image_view.removeFromSuperview()
            transitionContext.completeTransition(true)
        }
    }
}
