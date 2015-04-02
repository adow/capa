//
//  ExposureControl.swift
//  capa
//
//  Created by 秦 道平 on 14/10/31.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class ExposureControl:UIView {
    @IBOutlet weak var exposureView:UIView!
    @IBOutlet weak var biasLabel:UILabel!
    @IBOutlet weak var sunImageView:UIImageView!
    @IBOutlet weak var unlockButton:UIButton!
    @IBOutlet weak var constraintTop:NSLayoutConstraint!
    @IBOutlet weak var constraintLeft:NSLayoutConstraint!
    var limitsInFrame:CGRect? = nil ///限制拖动的区域范围，如果是正方形取景器的话不能到外面
    var device:AVCaptureDevice!
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.hidden = true
        self.backgroundColor = UIColor.clearColor()
        let panGesture = UIPanGestureRecognizer(target: self, action: "onPanGesture:")
        self.addGestureRecognizer(panGesture)
        self.contentMode = UIViewContentMode.Redraw
    }
//    override func translatesAutoresizingMaskIntoConstraints() -> Bool {
//        return true
//    }
    // 更新测光点，会改成自动测光并把曝光补偿恢复为0
    func updateExposurePointOfInterest(center:CGPoint){
        if let superView_value = self.superview {
            let superFrame = superView_value.frame
            let x = superFrame.width * center.x
            let y = superFrame.height * center.y
            self.center = CGPointMake(x, y)
            self.updateConstraints()
            var error:NSError?
            self.device.lockForConfiguration(&error)
            self.device.exposureMode = AVCaptureExposureMode.ContinuousAutoExposure
            self.device.exposurePointOfInterest = center
            self.device.setExposureTargetBias(0, completionHandler: { (time) -> Void in
                
            })
            self.device.unlockForConfiguration()
        }
    }
    func updateTargetBias(bias:Float){
        if bias >= 0.0 {
            self.biasLabel.text = "+" + bias.format(".1")
        }
        else{
            self.biasLabel.text = bias.format(".1")
        }
        let sunImageViewCenterX = CGFloat(93.0)
        let sunImageViewCenterY = CGFloat(self.frame.size.height / 2.0)
        let percent = bias / 8.0
        let moveCenterY = sunImageViewCenterY - self.frame.size.height / 2 * CGFloat(percent)
        self.sunImageView.center = CGPoint(x: sunImageViewCenterX, y: moveCenterY)
    }
    ///修改测光点，停下的时候才会确定最后的测光点并开始用自动测光
    func onPanGesture(gesture:UIPanGestureRecognizer){
            if gesture.state == UIGestureRecognizerState.Began {
                self.superview!.bringSubviewToFront(self)
            }
            else if gesture.state == UIGestureRecognizerState.Ended || gesture.state == UIGestureRecognizerState.Cancelled {
                var error:NSError?
                var point = gesture.locationInView(self.superview!)
                if let limitsInFrame_value = limitsInFrame {
                    point.y = fmax(point.y, limitsInFrame_value.origin.y)
                    point.y = fmin(point.y, CGRectGetMaxY(limitsInFrame_value))
                }
                let center = CGPoint(x: point.x / self.superview!.frame.size.width,
                    y: point.y / self.superview!.frame.size.height)
                self.updateExposurePointOfInterest(center)
            }
            else if gesture.state == UIGestureRecognizerState.Changed {
                var point = gesture.locationInView(self.superview!)
                if let limitsInFrame_value = limitsInFrame {
                    point.y = fmax(point.y, limitsInFrame_value.origin.y)
                    point.y = fmin(point.y, CGRectGetMaxY(limitsInFrame_value))
                }
                self.center = point
                self.updateConstraints()
            }
    }
    override func updateConstraints() {
        self.constraintLeft.constant = self.frame.origin.x
        self.constraintTop.constant = self.frame.origin.y
        super.updateConstraints()
    }
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        ///绘制边框
        let context = UIGraphicsGetCurrentContext()
        CGContextSaveGState(context)
        CGContextClearRect(context, rect)
        let strokeColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.3)
        CGContextSetStrokeColorWithColor(context, strokeColor.CGColor)
        CGContextSetLineWidth(context, 1.0)
        CGContextStrokeEllipseInRect(context, self.exposureView.frame)
        let innerRect = CGRectInset(self.exposureView.frame, 30.0, 30.0)
        CGContextSetLineWidth(context, 3.0)
        CGContextStrokeEllipseInRect(context, innerRect)
        let fillColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.1)
        CGContextSetFillColorWithColor(context, fillColor.CGColor)
        CGContextFillEllipseInRect(context, innerRect)
        CGContextRestoreGState(context)
    }
    func updateState(){
        if device == nil {
            return
        }
        switch device.exposureMode {
        case AVCaptureExposureMode.AutoExpose,AVCaptureExposureMode.ContinuousAutoExposure:
            unlockButton.hidden = true
        case AVCaptureExposureMode.Custom,AVCaptureExposureMode.Locked:
            unlockButton.hidden = false
        }
    }
    @IBAction func onButtonUnlock(sender:UIButton!){
        var error:NSError?
        self.device.lockForConfiguration(&error)
        self.device.exposureMode = AVCaptureExposureMode.ContinuousAutoExposure
        self.device.setExposureTargetBias(0, completionHandler: { (time) -> Void in
            
        })
        self.device.unlockForConfiguration()
    }
}