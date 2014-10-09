//
//  ViewController.swift
//  capa
//
//  Created by 秦 道平 on 14-10-9.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    var session:AVCaptureSession!
    @IBOutlet var previewView:CPPreviewView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        session = AVCaptureSession()
        self.previewView.session=session
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

