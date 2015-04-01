//
//  ShuttleGuideView.swift
//  capa
//
//  Created by 秦 道平 on 15/4/1.
//  Copyright (c) 2015年 秦 道平. All rights reserved.
//

import UIKit

class ShuttleGuideView: UILabel {
    var pageIndex:Int = 1
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    private func setup(){
        let tapGesture = UITapGestureRecognizer(target: self, action: "onTapGesture:")
        self.addGestureRecognizer(tapGesture)
    }
    func onTapGesture(tapGesture:UITapGestureRecognizer){
        if ++pageIndex == 2 {
            pageIndex = 1
            self.text = "往上 拖动 快门按钮进入设置"
        }
        else{
            self.text = "往下 拖动 快门按钮进入相册"
        }
    }
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
