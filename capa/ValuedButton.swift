//
//  ValuedButton.swift
//  capa
//
//  Created by 秦 道平 on 14/10/27.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

import Foundation
import UIKit

class ValuedButton:UIButton {
    struct StateItem {
        let value:Int!
        let title:String!
        let image:UIImage?
    }
    var contents:[StateItem]! = [StateItem]()
    var _stateItem:StateItem?
    var stateItem:StateItem?{
        get{
            return _stateItem
        }
        set{
            _stateItem = newValue
            if let state_value = _stateItem {
                if let image = state_value.image {
                    self.setImage(image, forState: UIControlState.Normal)
                    self.setImage(image, forState: UIControlState.Highlighted)
                }
                else{
                    self.setTitle(state_value.title, forState: UIControlState.Normal)
                    self.setTitle(state_value.title, forState: UIControlState.Highlighted)
                }
            }
            self.sendActionsForControlEvents(UIControlEvents.ValueChanged)
        }
    }
    override init(){
        super.init()
        self.addTarget(self, action: "gotoNextState", forControlEvents: UIControlEvents.TouchUpInside)
    }
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.addTarget(self, action: "gotoNextState", forControlEvents: UIControlEvents.TouchUpInside)
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addTarget(self, action: "gotoNextState", forControlEvents: UIControlEvents.TouchUpInside)
    }    
    func setTitle(title: String!, forValue value:Int!) {
        let item = StateItem(value: value, title: title, image: nil)
        self.contents.append(item)
    }
    func setTitle(title: String!, withImage image:UIImage!, forValue value:Int!){
        let item = StateItem(value: value, title: title, image: image)
        self.contents.append(item)
    }
    private func stateItemForValue(value:Int)->StateItem?{
        for item in self.contents {
            if item.value == value  {
                return item
            }
        }
        return nil
    }
    internal func gotoNextState(){
        func _gotoFirstState(){
            if self.contents.count > 0 {
                self.stateItem = self.contents[0]
            }
        }
        if let stateItem_value = self.stateItem {
            for (index,item) in enumerate(self.contents){
                if (item.value == stateItem_value.value) {
                    if index < self.contents.count-1 {
                        self.stateItem = self.contents[index+1]
                        return
                    }
                }
            }
            _gotoFirstState()
        }
        else{
            _gotoFirstState()
        }
        
    }
    private func makeStateValue(value:Int){
        let stateItem = self.stateItemForValue(value)
        if let state_value = stateItem {
            self.stateItem = state_value
        }
    }
}
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
//        self.setTitle("关闭", forValue: 0)
//        self.setTitle("打开", forValue: 1)
//        self.setTitle("自动", forValue: 2)
        self.setTitle("关闭", withImage: UIImage(named: "flash_off"), forValue: 0)
        self.setTitle("打开", withImage: UIImage(named: "flash_on"), forValue: 1)
        self.setTitle("自动", withImage: UIImage(named: "flash_auto"), forValue: 2)
        self.makeStateValue(0)
    }
}