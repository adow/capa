//
//  WebViewController.swift
//  capa
//
//  Created by 秦 道平 on 15/2/17.
//  Copyright (c) 2015年 秦 道平. All rights reserved.
//

import UIKit

class WebViewController: UIViewController {
    @IBOutlet weak var webView:UIWebView!
    var path:String!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        NSLog("url:%@", path)
        let url = NSURL(string: path)!
        let request = NSURLRequest(URL: url)
        webView.loadRequest(request)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
