//
//  FocusControl.swift
//  capa
//
//  Created by 秦 道平 on 14/10/30.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class FocusControl:UIView {
    enum State:Int,Printable{
        case Unvisible = 0, Visible = 1 , Active = 2
        var description:String{
            switch self {
            case .Unvisible:
                return "Unvisible"
            case .Visible:
                return "Visible"
            case .Active:
                return "Active"
            }
        }
    }
    @IBOutlet var focusView:UIView!
    @IBOutlet var lensPositionLabel:UILabel!
    var device:AVCaptureDevice!
    @IBOutlet var constraintTop:NSLayoutConstraint!
    @IBOutlet var constraintLeft:NSLayoutConstraint!
    var limitsInFrame:CGRect? = nil ///限制拖动的区域范围，如果是正方形取景器的话不能到外面
    var _state:State!
    var state:State!{
        get{
            return _state
        }
        set{
            _state = newValue
            switch _state! {
            case .Unvisible:
                self.hidden = true
            case .Visible:
                self.hidden = false
                self.alpha = 0.3
            case .Active:
                self.hidden = false
                self.alpha = 0.9
                
            }
        }
    }
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.state = .Unvisible
        self.backgroundColor = UIColor.clearColor()
        let panGesture = UIPanGestureRecognizer(target: self, action: "onPanGesture:")
        self.addGestureRecognizer(panGesture)
        self.contentMode = UIViewContentMode.Redraw
    }
//    override func translatesAutoresizingMaskIntoConstraints() -> Bool {
//        return true
//    }
    // 更新位置
    func updateFocusPointOfInterest(center:CGPoint){
        if let superView_value = self.superview {
            let superFrame = superView_value.frame
            let x = superFrame.width * center.x
            let y = superFrame.height * center.y
            self.center = CGPointMake(x, y)
            self.updateConstraints()
            var error:NSError?
            self.device.lockForConfiguration(&error)
            self.device.focusMode = AVCaptureFocusMode.AutoFocus
            self.device.focusPointOfInterest = center
            self.device.unlockForConfiguration()
        }
    }
    func updateLensPosition(lensPosition:Float){
        self.lensPositionLabel.text = lensPosition.format(".1")
    }
    func onPanGesture(gesture:UIPanGestureRecognizer){
        if self.state == .Active {
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
                self.updateFocusPointOfInterest(center)
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
    }
    override func updateConstraints() {
        self.constraintLeft.constant = self.frame.origin.x
        self.constraintTop.constant = self.frame.origin.y        
        super.updateConstraints()
    }
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        let context = UIGraphicsGetCurrentContext()
        CGContextSaveGState(context)
        CGContextClearRect(context, rect)
        CGContextSetStrokeColorWithColor(context, UIColor.whiteColor().CGColor)
        CGContextSetLineWidth(context, 1.0)
        CGContextStrokeRect(context, self.focusView.frame)
        CGContextRestoreGState(context)
    
    }
}