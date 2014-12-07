//
//  WorkPreviewViewController.swift
//  capa
//
//  Created by 秦 道平 on 14/11/15.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

import UIKit

class WorkPreviewViewController: UIViewController,UIScrollViewDelegate {

    var photo:PhotoModal?
    @IBOutlet weak var imageView:UIImageView!
    @IBOutlet weak var scrollView:UIScrollView!
    @IBOutlet weak var imageViewConstraintTop:NSLayoutConstraint!
    @IBOutlet weak var imageViewConstraintRight:NSLayoutConstraint!
    @IBOutlet weak var imageViewConstraintBottom:NSLayoutConstraint!
    @IBOutlet weak var imageViewConstraintLeft:NSLayoutConstraint!
    @IBOutlet weak var imageViewConstraintWidth:NSLayoutConstraint!
    @IBOutlet weak var imageViewConstraintHeight:NSLayoutConstraint!
    var initRatio : CGFloat!=1.0
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        if let photo_value = photo {
            self.imageView.image = photo_value.originalImage
        }
        self.imageView.hidden = true
        NSLog("viewDidLoad view frame:%@,scrollview frame:%@",
            NSStringFromCGRect(self.view.frame),
            NSStringFromCGRect(self.scrollView.frame))
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSLog("viewWillAppear view frame:%@,scrollview frame:%@",
            NSStringFromCGRect(self.view.frame),
            NSStringFromCGRect(self.scrollView.frame))
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        NSLog("viewDidAppear view frame:%@,scrollview frame:%@",
            NSStringFromCGRect(self.view.frame),
            NSStringFromCGRect(self.scrollView.frame))
        self.setupImageConstraint()
        

    }
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        NSLog("viewWillTransitionToSize:%@", NSStringFromCGSize(size))
    }
    func setupImageConstraint(){
        ///初始化约束条件设置，让图片的一边撑满，另一边缩放
        let image = imageView.image!
        let imageSize = image.size
        let scrollViewSize = self.scrollView.frame.size
        var target_image_width : CGFloat = 0.0
        var target_image_height : CGFloat = 0.0
        if imageSize.width < imageSize.height {
            target_image_width = 100.0
            target_image_height = imageSize.height / imageSize.width * target_image_width
        }
        else{
            target_image_height = 178.0
            target_image_width = imageSize.width * target_image_height / imageSize.height
        }
        ///不但要修改约束条件，还要修改 imageView 的尺寸
        var imageViewFrame = self.imageView.frame
        imageViewFrame.size.width = target_image_width
        imageViewFrame.size.height = target_image_height
        self.imageView.frame = imageViewFrame
        let left_margin : CGFloat = (scrollViewSize.width - target_image_width ) / 2.0
        let right_margin = left_margin
        let top_margin : CGFloat = (scrollViewSize.height - target_image_height) / 2.0
        let bottom_margin = top_margin
        self.imageViewConstraintTop.constant = top_margin
        self.imageViewConstraintRight.constant = right_margin
        self.imageViewConstraintBottom.constant = bottom_margin
        self.imageViewConstraintLeft.constant = left_margin
        self.imageViewConstraintWidth.constant = target_image_width
        self.imageViewConstraintHeight.constant = target_image_height
        
        ///maxZoom，放到最大就是图片的大小
        let maxWidthRatio = imageSize.width / target_image_width
        let maxHeightRatio = imageSize.height / target_image_height
        var maxRatio = (maxWidthRatio > maxHeightRatio) ? maxHeightRatio : maxWidthRatio
        maxRatio = fmax(maxRatio, 1.0)
        self.scrollView.maximumZoomScale = maxRatio
        
        ///initZoom,初始大小，依照一边撑满
        let initWidthRatio = scrollViewSize.width / target_image_width
        let initHeightRatio = scrollViewSize.height / target_image_height
        initRatio = (initWidthRatio > initHeightRatio) ? initHeightRatio : initWidthRatio
        initRatio = fmax(initRatio, 1.0)
        self.scrollView.zoomScale = initRatio

        self.updateConstraints()
        self.imageView.hidden = false
        
    }
    ///更新约束
    func updateConstraints(){
        let imageViewSize = self.imageView.frame.size
        let scrollViewSize = self.scrollView.frame.size
        let imageSize = self.imageView.image!.size
        
        NSLog("imageViewSize:%@,scrollViewSize:%@",
            NSStringFromCGSize(imageViewSize),NSStringFromCGSize(scrollViewSize))
        
        var left_margin : CGFloat = (scrollViewSize.width - imageViewSize.width) / 2.0
        var top_margin : CGFloat = (scrollViewSize.height - imageViewSize.height) / 2.0
        
        var scroll_x : CGFloat = 0.0
        if left_margin < 0 {
            scroll_x = -left_margin
            left_margin = 0.0
            
        }
        var scroll_y : CGFloat = 0.0
        if top_margin < 0.0 {
            scroll_y = -top_margin
            top_margin = 0.0
            
        }
        
        let right_margin : CGFloat = left_margin
        let bottom_margin : CGFloat = top_margin
        
        NSLog("top_margin:%@,right_margin:%@,bottom_margin:%@,left_margin:%@",
            top_margin,right_margin,bottom_margin,left_margin)
        
        self.imageViewConstraintTop.constant = top_margin
        self.imageViewConstraintRight.constant = right_margin
        self.imageViewConstraintBottom.constant = bottom_margin
        self.imageViewConstraintLeft.constant = left_margin
        
        self.view.layoutIfNeeded()
        //按道理设置约束条件就可以了，但是不解的是，如果现在的大小还是比scrollView小的话，就会看到contentSize是一个错误的值（实际的尺寸乘以缩放倍数），所以当图片还是很小的时候，还是把contentSize缩小倍数，如果 top_margin,left_margin 这些都是 0.0 的时候，contentSize 是正确的。现在还无法理解为什么。
        if top_margin > 0.0 && left_margin > 0.0 {
            let scale_contentsize = CGSizeMake(self.scrollView.contentSize.width / scrollView.zoomScale,
                self.scrollView.contentSize.height / scrollView.zoomScale)
            self.scrollView.contentSize = scale_contentsize
        }
//        NSLog("imageViewConstraintWidth:%@,imageViewConstraintHeight:%@,imageViewConstraintTop:%@,imageViewConstraintRight:%@,imageViewConstraintBottom:%@,imageViewConstraintLeft:%@",
//            self.imageViewConstraintWidth.constant,self.imageViewConstraintHeight.constant,
//            self.imageViewConstraintTop.constant,self.imageViewConstraintRight.constant,
//            self.imageViewConstraintBottom.constant,self.imageViewConstraintLeft.constant)
        NSLog("scrollViewContentSize:%@", NSStringFromCGSize(self.scrollView.contentSize))
        
        
        self.scrollView.contentOffset = CGPoint(x: scroll_x, y: scroll_y)
        
    }
    ///触摸控制，放大缩小
    @IBAction func onTapGesture(gesture:UITapGestureRecognizer){
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            if self.scrollView.zoomScale != self.scrollView.maximumZoomScale {
                self.scrollView.zoomScale = self.scrollView.maximumZoomScale
            }
            else{
                self.scrollView.zoomScale = self.initRatio
            }
        })
        
    }
    ///MARK: - UIScrollViewDelegate
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    func scrollViewDidZoom(scrollView: UIScrollView) {
        self.updateConstraints()
        
    }
    ///MARK: - Action
    @IBAction func onButtonAction(sender:UIBarButtonItem){
        let actionController = UIAlertController(title: "操作", message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        actionController.addAction(UIAlertAction(title: "保存到交卷", style: UIAlertActionStyle.Default, handler: { [unowned self](action) -> Void in
            if let photo_value = self.photo {
                //photo_value.saveToCameraRoll()
                //photo_value.remove()
                let workspaceViewController = self.navigationController?.childViewControllers[0] as WorkspaceViewController?
                self.navigationController?.popViewControllerAnimated(true)
                workspaceViewController?.savePhotos([photo_value,])
            }
        }))
        actionController.addAction(UIAlertAction(title: "删除照片", style: UIAlertActionStyle.Destructive, handler: { (action) -> Void in
            if let photo_value = self.photo {
//                photo_value.remove()
                let workspaceViewController = self.navigationController?.childViewControllers[0] as WorkspaceViewController?
                self.navigationController?.popViewControllerAnimated(true)
                workspaceViewController?.removePhotos([photo_value,])
                
            }
        }))
        actionController.addAction(UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
            
        }))
        self.presentViewController(actionController, animated: true) { () -> Void in
            
        }
    }
    @IBAction func onButtonMarkUse(sender:UIButton!){
        self.photo?.updateState(.use)
    }
    @IBAction func onButtonMarkRemove(sender:UIButton!){
        self.photo?.updateState(.remove)
    }
}
