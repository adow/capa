//
//  SettingViewController.swift
//  capa
//
//  Created by 秦 道平 on 14/12/16.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

import UIKit
import MessageUI

class SettingsViewController: UITableViewController,MFMailComposeViewControllerDelegate{
    var showDebugItem:Bool = false
    let command_path = "http://codingnext.com/capa/debug.json"
    var redirect_path:String?
    let mail_title = "Capa Camera 反馈"
    let mail_body = ""
    let mail_to = "xiaobenapp@gmail.com"
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
         self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        ///从服务器上检查是否要开启一下调试菜单
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
        NSUserDefaults.standardUserDefaults().setBool(!sender.on, forKey: kHIDEGUIDEWORKSPACE)
        NSUserDefaults.standardUserDefaults().setBool(!sender.on, forKey: kHIDESHUTTLEGUIDE)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    @IBAction func onSegmentWorkflow(sender:UISegmentedControl){
        NSUserDefaults.standardUserDefaults().setInteger(sender.selectedSegmentIndex, forKey: kWORKFLOW)
        NSUserDefaults.standardUserDefaults().synchronize()
        self.tableView.reloadData()
    }

    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return showDebugItem ? 3 : 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 4
        }
        else if section == 1{
            return 4
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
        if indexPath.section == 0 && indexPath.row == 3 {
            return 60.0
        }
        else {
            return 44.0
        }
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCellWithIdentifier("setting-square", forIndexPath: indexPath) as! UITableViewCell
                let switch_square = cell.viewWithTag(100) as! UISwitch
                switch_square.on = NSUserDefaults.standardUserDefaults().boolForKey(kSQUARE)
                return cell
            }
            else if indexPath.row == 1 {
                let cell = tableView.dequeueReusableCellWithIdentifier("setting-location", forIndexPath: indexPath) as! UITableViewCell
                let switch_location = cell.viewWithTag(100) as! UISwitch
                switch_location.on = NSUserDefaults.standardUserDefaults().boolForKey(kGPS)
                return cell
            }
            else if indexPath.row == 2 {
                let cell = tableView.dequeueReusableCellWithIdentifier("setting-workflow") as! UITableViewCell
                let segment_workflow = cell.viewWithTag(100) as! UISegmentedControl
                segment_workflow.selectedSegmentIndex = NSUserDefaults.standardUserDefaults().integerForKey(kWORKFLOW)
                return cell
            }
            else if indexPath.row == 3 {
                let cell = tableView.dequeueReusableCellWithIdentifier("setting-workflow-info") as! UITableViewCell
                let label = cell.viewWithTag(100) as! UILabel
                let workflow = NSUserDefaults.standardUserDefaults().integerForKey(kWORKFLOW)
                if workflow == 0 {
                    label.text = "使用 Capa 工作流，拍摄的照片将先进入 Capa 的工作目录，经过筛选后再进入系统相册"
                }
                else if workflow == 1 {
                    label.text = "使用传统工作流，拍摄的照片将直接进入系统相册"
                }
                return cell
            }
            else{
                let cell = tableView.dequeueReusableCellWithIdentifier("setting-cell", forIndexPath: indexPath) as! UITableViewCell
                return cell
            }
        }
        else if indexPath.section == 1 {
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCellWithIdentifier("setting-web") as! UITableViewCell
                return cell
            }
            else if indexPath.row == 1 {
                let cell = tableView.dequeueReusableCellWithIdentifier("setting-help") as! UITableViewCell
                return cell
            }
            else if indexPath.row == 2 {
                let cell = tableView.dequeueReusableCellWithIdentifier("setting-feedback") as! UITableViewCell
                return cell
            }
            else{
                let cell = tableView.dequeueReusableCellWithIdentifier("setting-about", forIndexPath: indexPath) as! UITableViewCell
                let versionLabel = cell.viewWithTag(100) as! UILabel
                let info = NSBundle.mainBundle().infoDictionary! as! [NSString:NSString]
                let version_short = info["CFBundleShortVersionString"]!
    //            let version = info["CFBundleVersion"]!
                //versionLabel.text = "v \(version_short) (\(version))"
                versionLabel.text = "\(version_short)"
                return cell
            }
        }
        else if indexPath.section == 2 {
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCellWithIdentifier("setting-debug") as! UITableViewCell
                let switch_debug = cell.viewWithTag(100) as! UISwitch
                switch_debug.on = NSUserDefaults.standardUserDefaults().boolForKey(kDEBUG)
                return cell
            }
            else{
                let cell = tableView.dequeueReusableCellWithIdentifier("setting-guide") as! UITableViewCell
                let switch_guide = cell.viewWithTag(100) as! UISwitch
                switch_guide.on = !NSUserDefaults.standardUserDefaults().boolForKey(kHIDEGUIDE)
                return cell
            }
        }
        else{
            let cell = tableView.dequeueReusableCellWithIdentifier("setting-cell", forIndexPath: indexPath) as! UITableViewCell
            return cell
        }

    }
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 1 {
            if indexPath.row == 0 {
                redirect_path = "http://codingnext.com/capa/"
                self.performSegueWithIdentifier("segue_setting_web", sender: nil)
            }
            else if indexPath.row == 1 {
                redirect_path = "http://codingnext.com/capa/help.html"
                self.performSegueWithIdentifier("segue_setting_web", sender: nil)
            }
            else if indexPath.row == 2 {
                sendMail()
            }
            else if indexPath.row == 3 {
                redirect_path = "http://codingnext.com/capa/about.html"
                self.performSegueWithIdentifier("segue_setting_web", sender: nil)
            }
        }
    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        let webViewController = segue.destinationViewController as! WebViewController
        webViewController.path = redirect_path
    }

    // MARK: - Mail
    ///调用发送反馈邮件
    private func sendMail(){
        if (MFMailComposeViewController.canSendMail()){
           _showMailComposer()
        }
        else{
           _showMailApp()
        }
    }
    private func _showMailComposer(){
        let mail = MFMailComposeViewController()
        mail.mailComposeDelegate = self
        mail.setSubject(mail_title)
        mail.setToRecipients([NSString(string: mail_to)])
        self.presentViewController(mail, animated: true) { () -> Void in
            
        }
    }
    private func _showMailApp(){
        let mail = "mailto:\(mail_to)&subject=\(mail_title)&body=\(mail_body)"
        let mail_encode = mail.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        UIApplication.sharedApplication().openURL(NSURL(string: mail_encode!)!)
    }
    func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
        var message = ""
        switch result.value {
        case MFMailComposeResultSent.value:
            message = "邮件发送成功"
        case MFMailComposeResultSaved.value:
            message = "邮件已经保存"
        case MFMailComposeResultFailed.value:
            message = "邮件发送失败"
        case MFMailComposeResultCancelled.value:
            message = "邮件取消发送"
        default:
            break
        }
        NSLog("%@",message)
        controller.dismissViewControllerAnimated(true, completion: { () -> Void in
            
        })
    }
}
