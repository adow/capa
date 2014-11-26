//
//  WorkspaceToolbar.swift
//  capa
//
//  Created by 秦 道平 on 14/11/25.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

import Foundation
import UIKit
class WorkspaceToolbar : UIView {
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.layer.cornerRadius = 3.0
        self.layer.shadowColor = UIColor.blackColor().CGColor
        self.layer.shadowOffset = CGSizeMake(1.0, 1.0)
        self.layer.shadowOpacity = 0.5
    }
    class func toolbar()->UIView{
        return NSBundle.mainBundle().loadNibNamed("WorkspaceToolbar", owner: self, options: nil)[0] as UIView
    }
    @IBAction func onSaveToCameraRoll(sender:UIButton){
        NSLog("save to camera rool")
    }
}