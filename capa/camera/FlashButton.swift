//
//  ValuedButton.swift
//  capa
//
//  Created by 秦 道平 on 14/10/27.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

import Foundation
import UIKit

func == (left:ValuedButton.StateItem,right:ValuedButton.StateItem) -> Bool{
    return left.value == right.value
}

class ValuedButton:UIButton {
    struct StateItem:Equatable {
        let value:Int!
        let title:String!
        let image:UIImage?
    }
    var contents:[StateItem]! = [StateItem]()
    var _currentItem:StateItem?
    var currentItem:StateItem?{
        get{
            return _currentItem
        }
        set{
            _currentItem = newValue
            if let state_value = _currentItem {
                if let image = state_value.image {
                    self.setImage(image, forState: UIControlState.Normal)
                    self.setImage(image, forState: UIControlState.Highlighted)
                }
                else{
                    self.setTitle(state_value.title, forState: UIControlState.Normal)
                    self.setTitle(state_value.title, forState: UIControlState.Highlighted)
                }
                self.sendActionsForControlEvents(UIControlEvents.ValueChanged)
            }
        }
    }
    override init(){
        super.init()
        self.addTarget(self, action: "gotoNextValue", forControlEvents: UIControlEvents.TouchUpInside)
    }
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.addTarget(self, action: "gotoNextValue", forControlEvents: UIControlEvents.TouchUpInside)
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addTarget(self, action: "gotoNextValue", forControlEvents: UIControlEvents.TouchUpInside)
    }    
    func setTitle(title: String!, forValue value:Int!) {
        let item = StateItem(value: value, title: title, image: nil)
        self.contents.append(item)
    }
    func setTitle(title: String!, withImage image:UIImage!, forValue value:Int!){
        let item = StateItem(value: value, title: title, image: image)
        self.contents.append(item)
    }
    ///指定状态
    func gotoValue(value:Int){
        for item in self.contents {
            if item.value == value {
                self.currentItem = item
            }
        }
    }
    ///下一个状态
    func gotoNextValue(){
        if let currentItem = self.currentItem {
            self.currentItem = self.contents.nextOf(currentItem)
        }
        if self.currentItem == nil && self.contents.count > 0 {
            self.currentItem = self.contents.first
        }
        
    }
    
}
///闪光灯按钮
@IBDesignable
class FlashButton:ValuedButton {
    override init(){
        super.init()
        self.setup()
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    func setup(){
        self.setTitle("关闭", withImage: UIImage(named: "flashlight2-off"), forValue: 0)
        self.setTitle("打开", withImage: UIImage(named: "flashlight2"), forValue: 1)
        self.setTitle("自动", withImage: UIImage(named: "flashlight2-auto"), forValue: 2)
        self.gotoValue(0)
    }
}