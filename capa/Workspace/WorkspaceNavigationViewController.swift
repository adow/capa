//
//  WorkspaceNavigationViewController.swift
//  capa
//
//  Created by 秦 道平 on 14/12/6.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

import UIKit

class WorkspaceNavigationViewController: UINavigationController,UIViewControllerTransitioningDelegate,UINavigationControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.transitioningDelegate = self
        self.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    ///MARK: - UIViewControllerTransitioningDelegate
    /// Dismiss 时候的动画
    func animationControllerForDismissedController(dismissed: UIViewController) ->  UIViewControllerAnimatedTransitioning? {
        return DismissTransition()
    }
    /// Present 时候的动画
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PresentTransition()
    }
    /// 导航跳转时候的动画
    func navigationController(navigationController: UINavigationController,
        animationControllerForOperation operation: UINavigationControllerOperation,
        fromViewController fromVC: UIViewController,
        toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
            if fromVC is WorkspaceViewController && toVC is WorkPreviewViewController {
                return WorkspaceToPreviewPushTransition()
            }
            else if fromVC is WorkPreviewViewController && toVC is WorkspaceViewController {
                return PreviewToWorkspacePopTransition()
            }
            else{
                return nil
            }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
