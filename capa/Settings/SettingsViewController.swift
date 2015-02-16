//
//  SettingViewController.swift
//  capa
//
//  Created by 秦 道平 on 14/12/16.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {
    var showDebugItem:Bool = false
    let command_path = "http://codingnext.com/capa/debug.json"
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
         self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        http_get_json(NSURL(string: command_path)!, { [weak self](json) -> () in
            if let dict = json as? [String:String] {
                let debug = dict["debug"]!.toInt()!
                self?.showDebugItem = Bool(debug)
                self?.tableView.reloadData()
            
            }
            
        }, onError: { (error) -> () in
            
        })
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onButtonCancel(){
        self.navigationController?.dismissViewControllerAnimated(true, completion: { () -> Void in
            
        })
    }
    @IBAction func onSwitchSquare(sender:UISwitch){
        NSUserDefaults.standardUserDefaults().setBool(sender.on, forKey:kSQUARE)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    @IBAction func onSwitchLocation(sender:UISwitch){
        NSUserDefaults.standardUserDefaults().setBool(sender.on, forKey: kGPS)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    @IBAction func onSwitchDebug(sender:UISwitch){
        NSUserDefaults.standardUserDefaults().setBool(sender.on, forKey: kDEBUG)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    @IBAction func onSwitchGuide(sender:UISwitch){
        NSUserDefaults.standardUserDefaults().setBool(!sender.on, forKey: kHIDEGUIDE)
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return showDebugItem ? 3 : 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        }
        else if section == 1{
            return 1
        }
        else{
            return 2
        }
    }
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "操作"
        }
        else if section == 1{
            return "关于"
        }
        else if section == 2 {
            return "调试"
        }
        else{
            return ""
        }
    }
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44.0
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCellWithIdentifier("setting-square", forIndexPath: indexPath) as UITableViewCell
                let switch_square = cell.viewWithTag(100) as UISwitch
                switch_square.on = NSUserDefaults.standardUserDefaults().boolForKey(kSQUARE)
                return cell
            }
            else if indexPath.row == 1 {
                let cell = tableView.dequeueReusableCellWithIdentifier("setting-location", forIndexPath: indexPath) as UITableViewCell
                let switch_location = cell.viewWithTag(100) as UISwitch
                switch_location.on = NSUserDefaults.standardUserDefaults().boolForKey(kGPS)
                return cell
            }
            else{
                let cell = tableView.dequeueReusableCellWithIdentifier("setting-cell", forIndexPath: indexPath) as UITableViewCell
                return cell
            }
        }
        else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCellWithIdentifier("setting-about", forIndexPath: indexPath) as UITableViewCell
            let versionLabel = cell.viewWithTag(100) as UILabel
            let info = NSBundle.mainBundle().infoDictionary! as [NSString:NSString]
            let version_short = info["CFBundleShortVersionString"]!
//            let version = info["CFBundleVersion"]!
            //versionLabel.text = "v \(version_short) (\(version))"
            versionLabel.text = "\(version_short)"
            return cell
        }
        else if indexPath.section == 2 {
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCellWithIdentifier("setting-debug") as UITableViewCell
                let switch_debug = cell.viewWithTag(100) as UISwitch
                switch_debug.on = NSUserDefaults.standardUserDefaults().boolForKey(kDEBUG)
                return cell
            }
            else{
                let cell = tableView.dequeueReusableCellWithIdentifier("setting-guide") as UITableViewCell
                let switch_guide = cell.viewWithTag(100) as UISwitch
                switch_guide.on = !NSUserDefaults.standardUserDefaults().boolForKey(kHIDEGUIDE)
                return cell
            }
        }
        else{
            let cell = tableView.dequeueReusableCellWithIdentifier("setting-cell", forIndexPath: indexPath) as UITableViewCell
            return cell
        }

    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
