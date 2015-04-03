//
//  WorkspaceToolbar.swift
//  capa
//
//  Created by 秦 道平 on 14/11/25.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

import Foundation
import UIKit
protocol WorkspaceToolbarDelegate:class,NSObjectProtocol {
    func onToolbarItem(photo:PhotoModal?,itemButton:UIButton)
}
class WorkspaceToolbar : UIView {
    var photo : PhotoModal?{
        didSet{
            if let photo = photo {
                if photo.state == .use {
                    self.buttonMarkUse.selected = true
                    self.buttonMarkRemove.selected = false
                }
                else if photo.state == .remove{
                    self.buttonMarkUse.selected = false
                    self.buttonMarkRemove.selected = true
                }
                else{
                    self.buttonMarkUse.selected = false
                    self.buttonMarkRemove.selected = false
                }
            }
        }
    }
    weak var delegate : WorkspaceToolbarDelegate? = nil
    @IBOutlet weak var buttonMarkUse:UIButton!
    @IBOutlet weak var buttonMarkRemove:UIButton!
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
    @IBAction func onButtonItem(sender:UIButton){
        if sender === self.buttonMarkUse {
            self.buttonMarkUse.selected = true
            self.buttonMarkRemove.selected = false
        }
        else if sender == self.buttonMarkRemove {
            self.buttonMarkUse.selected = false
            self.buttonMarkRemove.selected = true
        }
        self.delegate?.onToolbarItem(self.photo, itemButton: sender)
    }
}