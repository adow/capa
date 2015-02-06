//
//  CPPreviewView.swift
//  capa
//
//  Created by 秦 道平 on 14-10-9.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class CPPreviewView:UIView{
    
    class override func layerClass()->(AnyClass){
            return AVCaptureVideoPreviewLayer.self
    }
    
    var session:AVCaptureSession!{
        get{
            let layer=self.layer as AVCaptureVideoPreviewLayer
            return layer.session
        }
        set{
            let layer=self.layer as AVCaptureVideoPreviewLayer
            layer.session=newValue
//            layer.videoGravity=AVLayerVideoGravityResizeAspectFill
        }
    }
}