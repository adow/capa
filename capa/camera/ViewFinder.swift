//
//  ViewFinder.swift
//  capa
//
//  Created by 秦 道平 on 15/1/4.
//  Copyright (c) 2015年 秦 道平. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class ViewFinder:UIView {
    @IBOutlet var maskTopView:UIView!
    @IBOutlet var maskBottomView:UIView!
    let squareMargin:CGFloat = 60.0
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = UIColor.clearColor()
    }
    ///正方形剪裁的开始位置
    var squareMarginPercent:CGFloat{
        return squareMargin / self.frame.size.height
    }
    ///取景框大小
    var viewFrame:CGRect{
        return CGRect(x: 0.0,
            y: squareMargin,
            width: self.frame.size.width,
            height: self.frame.size.width)
    }
    ///修正取景框的大小
    func updateViewFinder(){
        self.maskTopView.frame = CGRectMake(0.0, 0.0, self.frame.size.width, squareMargin)
        let bottomHeight = self.frame.size.height - self.frame.size.width - squareMargin
        self.maskBottomView.frame = CGRectMake(0.0, self.frame.size.height - bottomHeight, self.frame.size.width, bottomHeight)
    }
    override func updateConstraints() {
        super.updateConstraints()
        self.updateViewFinder()
    }
}

