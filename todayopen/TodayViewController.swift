//
//  TodayViewController.swift
//  todayopen
//
//  Created by 秦 道平 on 15/1/6.
//  Copyright (c) 2015年 秦 道平. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
        
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
        self.preferredContentSize = CGSizeMake(self.view.frame.size.width, 44.0)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsetsMake(0.0, 44.0, 0.0, 0.0)
    }
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)!) {
        // Perform any setup necessary in order to update the view.

        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData

        completionHandler(NCUpdateResult.NewData)
    }
    @IBAction func onButton(sender:UIButton!){
        self.extensionContext?.openURL(NSURL(string: "capa://")!, completionHandler: { (completed) -> Void in
            
        })
    }
    @IBAction func onControl(sender:UIControl!){
        self.extensionContext?.openURL(NSURL(string: "capa://")!, completionHandler: { (completed) -> Void in
            
        })
    }
}
