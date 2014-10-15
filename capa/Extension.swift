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

extension AVCaptureVideoOrientation {
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
