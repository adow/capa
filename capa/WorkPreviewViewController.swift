//
//  WorkPreviewViewController.swift
//  capa
//
//  Created by 秦 道平 on 14/11/15.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

import UIKit

class WorkPreviewViewController: UIViewController {

    var photo:PhotoModal?
    @IBOutlet var imageView:UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        if let photo_value = photo {
            self.imageView.image = photo_value.originalImage
        }
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
    @IBAction func onButtonCancel(sender:UIButton!){
        self.dismissViewControllerAnimated(true, completion: { () -> Void in
            
        })
    }
}
