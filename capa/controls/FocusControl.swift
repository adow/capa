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
    @IBOutlet var activeLabel:UILabel!
    var device:AVCaptureDevice!
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
                self.activeLabel.hidden=true
            case .Active:
                self.activeLabel.hidden=false
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
    }
    // 更新位置
    func updateFocusPointOfInterest(center:CGPoint){
        if let superView_value = self.superview {
            let superFrame = superView_value.frame
            let x = superFrame.width * center.x
            let y = superFrame.height * center.y
            self.center = CGPointMake(x, y)
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
                
            }
            else if gesture.state == UIGestureRecognizerState.Ended || gesture.state == UIGestureRecognizerState.Cancelled {
                var error:NSError?
                let point = gesture.locationInView(self.superview!)
                let center = CGPoint(x: point.x / self.superview!.frame.size.width,
                    y: point.y / self.superview!.frame.size.height)
                self.updateFocusPointOfInterest(center)
            }
            else if gesture.state == UIGestureRecognizerState.Changed {
                let point = gesture.locationInView(self.superview!)
                self.center = point
            }
        }
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