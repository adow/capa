//
//  WorkspaceMarkerView.swift
//  capa
//
//  Created by 秦 道平 on 14/11/26.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

import Foundation
import UIKit

class WorkspaceMarkerView:UIView{
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = UIColor.clearColor()
    }
    @IBAction func onButton(sender:UIButton){
        NSLog("test button")
    }
    @IBAction func onMarkUse(sender:UIButton){
        NSLog("mark useful")
    }
    @IBAction func onMarkOnuse(sender:UIButton){
        NSLog("mark nouse")
    }
    class func markerView()->UIView{
        return NSBundle.mainBundle().loadNibNamed("WorkspaceMarkerView", owner: self, options: nil)[0] as UIView
    }
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        let context = UIGraphicsGetCurrentContext()
        CGContextSaveGState(context)
        CGContextClearRect(context, rect)
        CGContextSetStrokeColorWithColor(context, UIColor.darkGrayColor().CGColor)
        CGContextSetLineWidth(context, 3.0)
        CGContextStrokeRect(context, CGRectInset(rect, 10.0, 10.0))
        CGContextRestoreGState(context)
        
    }
}