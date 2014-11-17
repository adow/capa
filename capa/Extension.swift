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
}