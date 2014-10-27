//
//  CameraViewController.swift
//  capa
//
//  Created by 秦 道平 on 14/10/22.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

import Foundation
import UIKit

class CameraViewController : UIViewController, UIPickerViewDataSource,UIPickerViewDelegate {
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            return 3
    }
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
            return 1
    }
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
            return "selection \(row)"
    }
    @IBOutlet var flashButton:FlashButton!
    override func viewDidLoad() {
//        let flash_button = FlashButton(frame: CGRect(x: 100, y: 100.0, width: 100.0, height: 100.0))
//        flash_button.addTarget(self, action: "onFlashButton:", forControlEvents: UIControlEvents.ValueChanged)
//        self.view.addSubview(flash_button)
    }
    @IBAction func onFlashButton(sender:FlashButton!){
        NSLog("flashButton:%d", sender.stateItem!.value)
    }
}