//
//  WorkPreviewCollectionViewCell.swift
//  capa
//
//  Created by 秦 道平 on 14/12/14.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

import UIKit

class WorkPreviewCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var scrollView:UIScrollView!
    @IBOutlet weak var imageViewConstraintTop:NSLayoutConstraint!
    @IBOutlet weak var imageViewConstraintRight:NSLayoutConstraint!
    @IBOutlet weak var imageViewConstraintBottom:NSLayoutConstraint!
    @IBOutlet weak var imageViewConstraintLeft:NSLayoutConstraint!
    @IBOutlet weak var imageViewConstraintWidth:NSLayoutConstraint!
    @IBOutlet weak var imageViewConstraintHeight:NSLayoutConstraint!
    @IBOutlet weak var imageView:UIImageView!
    weak var collectionViewOnwer:UICollectionView!
    override func awakeFromNib() {
        super.awakeFromNib()
        let tapGesture = UITapGestureRecognizer(target: self, action: Selector("onTapGesture:"))
        tapGesture.numberOfTapsRequired = 2
        self.addGestureRecognizer(tapGesture)
    }
    func setupConstraints() {
        NSLog("viewSize:%@,scrollSize:%@", NSStringFromCGSize(self.frame.size),NSStringFromCGSize(self.scrollView.frame.size))
        let image = imageView.image!
        let imageSize = image.size
        let scrollViewSize = self.scrollView.frame.size
        var target_image_width : CGFloat = 0.0
        var target_image_height : CGFloat = 0.0
        if imageSize.width >= imageSize.height {
            target_image_width = scrollViewSize.width
            target_image_width = fmin(target_image_width,imageSize.width)
            target_image_height = imageSize.height / imageSize.width * target_image_width
        }
        else{
            target_image_height = scrollViewSize.height
            target_image_height = fmin(target_image_height, imageSize.height)
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
        NSLog("top_margin:%@,right_margin:%@,bottom_margin:%@,left_margin:%@,width:%@,height:%@",
            top_margin,right_margin,bottom_margin,left_margin,target_image_width,target_image_height)
        
        ///maxZoom，放到最大就是图片的大小
        let maxWidthRatio = imageSize.width / target_image_width
        let maxHeightRatio = imageSize.height / target_image_height
        var maxRatio = (maxWidthRatio > maxHeightRatio) ? maxHeightRatio : maxWidthRatio
        maxRatio = fmax(maxRatio, 1.0)
        self.scrollView.maximumZoomScale = maxRatio
        //        super.updateConstraints()
        //        self.layoutIfNeeded()
        //        self.updateConstraints()
        //        self.scrollView.zoomScale = 1.0
    }
    override func updateConstraints() {
        let imageViewSize = self.imageView.frame.size
        let scrollViewSize = self.scrollView.frame.size
        let imageSize = self.imageView.image != nil ? self.imageView.image!.size : self.imageView.frame.size
        
        //        NSLog("imageViewSize:%@,scrollViewSize:%@",
        //            NSStringFromCGSize(imageViewSize),NSStringFromCGSize(scrollViewSize))
        
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
        
        //        NSLog("top_margin:%@,right_margin:%@,bottom_margin:%@,left_margin:%@",
        //            top_margin,right_margin,bottom_margin,left_margin)
        
        self.imageViewConstraintTop.constant = top_margin
        self.imageViewConstraintRight.constant = right_margin
        self.imageViewConstraintBottom.constant = bottom_margin
        self.imageViewConstraintLeft.constant = left_margin
        
        self.layoutIfNeeded()
        //按道理设置约束条件就可以了，但是不解的是，如果现在的大小还是比scrollView小的话，就会看到contentSize是一个错误的值（实际的尺寸乘以缩放倍数），所以当图片还是很小的时候，还是把contentSize缩小倍数，如果 top_margin,left_margin 这些都是 0.0 的时候，contentSize 是正确的。现在还无法理解为什么。
        if top_margin > 0.0 && left_margin > 0.0 {
            let scale_contentsize = CGSizeMake(self.scrollView.contentSize.width / scrollView.zoomScale,
                self.scrollView.contentSize.height / scrollView.zoomScale)
            self.scrollView.contentSize = scale_contentsize
        }
        NSLog("imageViewConstraintWidth:%@,imageViewConstraintHeight:%@,imageViewConstraintTop:%@,imageViewConstraintRight:%@,imageViewConstraintBottom:%@,imageViewConstraintLeft:%@",
            self.imageViewConstraintWidth.constant,self.imageViewConstraintHeight.constant,
            self.imageViewConstraintTop.constant,self.imageViewConstraintRight.constant,
            self.imageViewConstraintBottom.constant,self.imageViewConstraintLeft.constant)
        //        NSLog("scrollViewContentSize:%@", NSStringFromCGSize(self.scrollView.contentSize))
        
        
        self.scrollView.contentOffset = CGPoint(x: scroll_x, y: scroll_y)
        super.updateConstraints()
    }
    ///触摸控制，放大缩小
    @IBAction func onTapGesture(gesture:UITapGestureRecognizer){
        //        self.scrollView.zoomScale = 3.0
        //        self.layoutIfNeeded()
        UIView.animateWithDuration(0.1, animations: { [unowned self]() -> Void in
            if self.scrollView.zoomScale != self.scrollView.maximumZoomScale {
                NSLog("zoom:%@", self.scrollView.maximumZoomScale)
                self.scrollView.scrollEnabled = true
                self.collectionViewOnwer.scrollEnabled = false
                self.scrollView.zoomScale = self.scrollView.maximumZoomScale
            }
            else{
                NSLog("zoom : 1")
                self.scrollView.scrollEnabled = false
                self.collectionViewOnwer.scrollEnabled = true
                self.scrollView.zoomScale = 1.0
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
}
