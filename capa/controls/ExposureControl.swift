//
//  ExposureControl.swift
//  capa
//
//  Created by 秦 道平 on 14/10/31.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

import Foundation
import UIKit

class ExposureControl:UIView {
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
    @IBOutlet var exposureView:UIView!
    @IBOutlet var biasLabel:UILabel!
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
    }
    // 更新位置
    func updateExposurePointOfInterest(center:CGPoint){
        if let superView_value = self.superview {
            let superFrame = superView_value.frame
            let x = superFrame.width * center.x
            let y = superFrame.height * center.y
            self.center = CGPointMake(x, y)
        }
    }
    func updateTargetBias(bias:Float){
        self.biasLabel.text = bias.format(".1")
    }
}