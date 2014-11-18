//
//  Extension.swift
//  capa
//
//  Created by 秦 道平 on 14-10-10.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

extension AVCaptureVideoOrientation:Printable {
    init (ui:UIInterfaceOrientation){
        switch ui {
        case .LandscapeLeft:
            self = AVCaptureVideoOrientation.LandscapeLeft
        case .LandscapeRight:
            self = AVCaptureVideoOrientation.LandscapeRight
        case .Portrait:
            self = AVCaptureVideoOrientation.Portrait
        case .PortraitUpsideDown:
            self = AVCaptureVideoOrientation.PortraitUpsideDown
        default:
            self = AVCaptureVideoOrientation.Portrait
        }
    }
    public var description:String{
        switch self{
        case .LandscapeLeft:
            return "LandscapeLeft"
        case .LandscapeRight:
            return "LandscapeRight"
        case .Portrait:
            return "Portrait"
        case .PortraitUpsideDown:
            return "PortraitUpsideDown"
        }
    }
}
extension Float {
    func format(f:String)->String{
        return String(format: "%\(f)f",self)
    }
}
extension Float64 {
    func format(f:String)->String{
        return String(format:"%\(f)f",self)
    }
}
extension AVCaptureExposureMode : Printable {
    public var description:String{
        switch self {
        case .AutoExpose:
            return "AutoExpose"
        case .ContinuousAutoExposure:
            return "Continusous"
        case .Custom:
            return "Custom"
        case .Locked:
            return "Locked"
        default:
            return "unknown"
            }
    }
}
extension AVCaptureFocusMode : Printable {
    public var description:String{
        switch self {
        case .AutoFocus:
            return "AutoFocus"
        case .ContinuousAutoFocus:
            return "ContinuousAutoFocus"
        case .Locked:
            return "Locked"
        }
    }
}
extension AVCaptureFlashMode : Printable {
    public var description : String{
        switch self {
        case .Auto:
            return "Auto"
        case .Off:
            return "Off"
        case .On:
            return "On"
        }
    }
}
extension UIImage {
    /// 创建一张按宽度缩小的照片
    public func resizeImageWithWidth(width:CGFloat) -> UIImage! {
        let old_width = self.size.width
        let old_height = self.size.height
        let height = width * old_height / old_width
        UIGraphicsBeginImageContext(CGSize(width: width, height: height))
        let context = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(context, UIColor.whiteColor().CGColor)
        UIRectFill(CGRect(x: 0.0, y: 0.0, width: width, height: height))
        self.drawInRect(CGRect(x: 0.0, y: 0.0, width: width, height: height))
        let new_image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return new_image
    }
    private func radius(degree:Double)->Double{
        return degree * M_PI / 180.0
    }
    ///旋转一张图片
    public func rotate(orientation:UIImageOrientation)->UIImage!{
        UIGraphicsBeginImageContext(self.size)
        let context = UIGraphicsGetCurrentContext()
        if orientation == UIImageOrientation.Right {
            CGContextRotateCTM(context, CGFloat(self.radius(90.0)))
        }
        else if orientation == UIImageOrientation.Left {
            CGContextRotateCTM(context, CGFloat(self.radius(-90.0)))
        }
        else if orientation == UIImageOrientation.Up {
            CGContextRotateCTM(context, CGFloat(self.radius(90.0)))
        }
        self.drawAtPoint(CGPoint(x: 0, y: 0))
        let new_image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return new_image
    }
}
extension UIImageOrientation:Printable{
    public var description : String{
        switch self {
        case .Down:
            return "Down"
        case .DownMirrored:
            return "DownMirrored"
        case .Left:
            return "Left"
        case .LeftMirrored:
            return "LeftMirrored"
        case .Right:
            return "Right"
        case .RightMirrored:
            return "RightMirrored"
        case .Up:
            return "Up"
        case .UpMirrored:
            return "UpMirrored"
        }
    }
}