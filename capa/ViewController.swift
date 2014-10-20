//
//  ViewController.swift
//  capa
//
//  Created by 秦 道平 on 14-10-9.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

import UIKit
import AVFoundation
import AssetsLibrary

class ViewController: UIViewController {
    var session:AVCaptureSession!
    var device:AVCaptureDevice!
    @IBOutlet var previewView:CPPreviewView!
    @IBOutlet var exposeView:UIView!
    @IBOutlet var lenseView:UIView!
    @IBOutlet var flashModeView:UIView!
    @IBOutlet var debugLabel:UILabel!
    @IBOutlet var segmentFunction:UISegmentedControl!
    @IBOutlet var segmentFocus:UISegmentedControl!
    @IBOutlet var segmentExposure:UISegmentedControl!
    @IBOutlet var segmentFlashMode:UISegmentedControl!
    @IBOutlet var slide_exposureDuration:UISlider!
    @IBOutlet var slide_lensPosition:UISlider!
    @IBOutlet var slide_iso:UISlider!
    @IBOutlet var slide_baise:UISlider!
    @IBOutlet var iso_label:UILabel!
    @IBOutlet var exposureDuration_label:UILabel!
    @IBOutlet var baise_label:UILabel!
    @IBOutlet var lense_label:UILabel!
    
    let EXPOSURE_DURATION_POWER = 5
    let EXPOSURE_MINIMUM_DURATION = 1/1000
    
    var captureOutput:AVCaptureStillImageOutput!
    var sessionQueue : dispatch_queue_t!
    var exposureDurationSeconds:Float64?{
        get{
            return Float64(1 / self.slide_exposureDuration.value)
        }
        set{
            if let value = newValue {
                self.slide_exposureDuration.value = Float(1 / value)
                self.slide_exposureDuration.enabled = true
                self.exposureDuration_label.text = String(format: "%.2f", value)
            }
            else{
                self.slide_exposureDuration.enabled=false
            }
        }
    }
    var lensPosition:Float?{
        get{
            return self.slide_lensPosition.value
        }
        set{
            if let value = newValue {
                self.slide_lensPosition.value=value
                self.slide_lensPosition.enabled=true
                self.lense_label.text=String(format: "%.1f",value)
            }
            else{
                self.slide_lensPosition.enabled=false
            }
        }
    }
//    var lensPosition:Float?
    var ISO:Float?{
        get{
            return self.slide_iso.value
        }
        set{
            if let value = newValue {
                self.slide_iso.value=value
                self.slide_iso.enabled=true
                self.iso_label.text="\(Int(value))"
            }
            else{
                self.slide_iso.enabled=false
            }
        }
    }
    var exposureTargetBias:Float?{
        get{
            return self.slide_baise.value
        }
        set{
            if let value = newValue {
                self.slide_baise.value=value
                self.slide_baise.enabled=true
                self.baise_label.text="\(value)"
            }
            else{
                self.slide_baise.enabled=false
            }
        }
    }
    var exposureTargetOffset:Float?
    var exposureMode:AVCaptureExposureMode!{
        get{
            return self.device.exposureMode
        }
        set{
            self.segmentExposure.selectedSegmentIndex = newValue.toRaw()
        }
    }
    var focusMode : AVCaptureFocusMode!{
        get{
            return self.device.focusMode
        }
        set{
            self.segmentFocus.selectedSegmentIndex = newValue.toRaw()
        }
    }
    var flashMode : AVCaptureFlashMode! {
        get{
            return self.device.flashMode
        }
        set{
            self.segmentFlashMode.selectedSegmentIndex = newValue.toRaw()
        }
    }
    
    // MARK: - viewcontroller
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        session = AVCaptureSession()
        self.previewView.session=session
        
//        let t_start=CFAbsoluteTimeGetCurrent()
        self.sessionQueue=dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL)
        dispatch_async(self.sessionQueue){
            [unowned self] () -> () in
            self.session.beginConfiguration()
            
            var error : NSError?
            self.device=AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
            if (self.device == nil){
                NSLog("could not use camera")
                return
            }
            
            let captureInput = AVCaptureDeviceInput.deviceInputWithDevice(self.device, error: &error) as AVCaptureDeviceInput
            if let error_value = error {
                NSLog("error:%@", error_value)
                return
            }
            self.session .addInput(captureInput)
            self.captureOutput=AVCaptureStillImageOutput()
            let outputSettings=[AVVideoCodecKey:AVVideoCodecJPEG]
            self.captureOutput.outputSettings=outputSettings
            self.session.addOutput(self.captureOutput)
            self.session.commitConfiguration()
            
//            self.session.startRunning()
//            let t_end=CFAbsoluteTimeGetCurrent()
//            NSLog("start duration:%.1f", t_end-t_start)
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.exposureMode = self.device.exposureMode
                self.focusMode = self.device.focusMode
                self.flashMode = self.device.flashMode
                self.exposureTargetBias = self.device.exposureTargetBias
                
                self.slide_baise.maximumValue=self.device.maxExposureTargetBias
                self.slide_baise.minimumValue=self.device.minExposureTargetBias
                self.slide_iso.maximumValue=self.device.activeFormat.maxISO
                self.slide_iso.minimumValue=self.device.activeFormat.minISO
                self.slide_exposureDuration.maximumValue = 1000
                self.slide_exposureDuration.minimumValue = 1
                NSLog("exposureDuration:%f,%f", self.slide_exposureDuration.minimumValue,self.slide_exposureDuration.maximumValue)
                self.slide_lensPosition.maximumValue=1.0
                self.slide_lensPosition.minimumValue=0.0
                
                println("baise:\(self.slide_baise.minimumValue),\(self.slide_baise.maximumValue);ISO:\(self.slide_iso.minimumValue),\(self.slide_iso.maximumValue);duration:\(self.slide_exposureDuration.minimumValue),\(self.slide_exposureDuration.maximumValue)")
                
                
            })
        }
        
        
        
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.setNeedsStatusBarAppearanceUpdate()
        dispatch_async(self.sessionQueue, { () -> Void in
            self.device.addObserver(self,forKeyPath: "exposureDuration",options: .New ,context: nil)
            self.device.addObserver(self, forKeyPath: "lensPosition", options: .New, context: nil)
            self.device.addObserver(self, forKeyPath: "exposureTargetBias", options: .New, context: nil)
            self.device.addObserver(self, forKeyPath: "exposureTargetOffset", options: .New, context: nil)
            self.device.addObserver(self, forKeyPath: "ISO", options: .New, context: nil)
            self.device.addObserver(self, forKeyPath: "exposureMode", options: .New, context: nil)
            self.device.addObserver(self, forKeyPath: "focusMode", options: .New, context: nil)
            self.device.addObserver(self, forKeyPath: "flashMode", options: .New, context: nil)
            self.session.startRunning()
        })
    }
    override func viewDidDisappear(animated:Bool){
        super.viewDidDisappear(animated)
        self.device.removeObserver(self, forKeyPath: "exposureDuration")
        self.device.removeObserver(self, forKeyPath: "lensPosition")
        self.device.removeObserver(self, forKeyPath: "exposureTargetBias")
        self.device.removeObserver(self, forKeyPath: "exposureTargetOffset")
        self.device.removeObserver(self, forKeyPath: "ISO")
        self.device.removeObserver(self, forKeyPath: "exposureMode")
        self.device.removeObserver(self, forKeyPath: "focusMode")
        self.device.removeObserver(self, forKeyPath: "flashMode")
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        let layer=self.previewView.layer as AVCaptureVideoPreviewLayer
        if (layer.connection != nil ){
            layer.connection.videoOrientation = AVCaptureVideoOrientation(ui: toInterfaceOrientation)
        }
    }
    override func observeValueForKeyPath(keyPath: String!, ofObject object: AnyObject!, change: [NSObject : AnyObject]!, context: UnsafeMutablePointer<Void>) {
        //println("\(keyPath):\(change[NSKeyValueChangeNewKey])")
        switch keyPath {
            case "exposureDuration":
                if let time = change[NSKeyValueChangeNewKey]?.CMTimeValue {
                    let seconds = CMTimeGetSeconds(time)
//                    NSLog("exposureDurationSeconds:%.2f", seconds)
                    self.exposureDurationSeconds = seconds
//                    let minDurationSeconds = max(CMTimeGetSeconds(self.device.activeFormat.minExposureDuration), Float64(EXPOSURE_MINIMUM_DURATION));
//                    let maxDurationSeconds = CMTimeGetSeconds(self.device.activeFormat.maxExposureDuration);
//                    let p = ( seconds - minDurationSeconds ) / ( maxDurationSeconds - minDurationSeconds ); // Scale to 0-1
//                    let durationSeconds = pow( p, 1 / Float64(EXPOSURE_DURATION_POWER));
//                    //self.exposureDurationSeconds=durationSeconds;
//                    self.exposureDurationSeconds = seconds
//                    println("seconds:\(seconds),duration:\(durationSeconds)")
//                    if ( seconds < 1){
//                        self.exposureDuration_label.text="1/\(Int((1 / seconds)))"
//                    }
//                    else{
//                        self.exposureDuration_label.text="\(seconds)"
//                    }
                }
                break
            case "ISO":
                self.ISO = change[NSKeyValueChangeNewKey]?.floatValue
                break
            case "lensPosition":
                self.lensPosition = change[NSKeyValueChangeNewKey]?.floatValue
                break
            case "exposureTargetBias":
                self.exposureTargetBias = change[NSKeyValueChangeNewKey]?.floatValue
                break
            case "exposureTargetOffset":
                self.exposureTargetOffset = change[NSKeyValueChangeNewKey]?.floatValue
                break
            case "exposureMode":
                if let mode_value = change[NSKeyValueChangeOldKey]?.integerValue {
                    let mode = AVCaptureExposureMode.fromRaw(mode_value)!
                    if (mode == AVCaptureExposureMode.Custom){
                        var error:NSError?
                        self.device.lockForConfiguration(&error)
                        self.device.activeVideoMaxFrameDuration=kCMTimeInvalid
                        self.device.activeVideoMinFrameDuration=kCMTimeInvalid
                        self.device.unlockForConfiguration()
                    }
                }
                if let mode_value = change[NSKeyValueChangeNewKey]?.integerValue {
                    let mode = AVCaptureExposureMode.fromRaw(mode_value)!
                    self.exposureMode = mode
                }
            case "focusMode":
                if let mode_value = change[NSKeyValueChangeNewKey]?.integerValue {
                    self.focusMode = AVCaptureFocusMode.fromRaw(mode_value)
                }
            case "flashMode":
                break
            default:
                break
        }
        self.updateDebugLabel()
    }
    
    // MARK: - Action
    @IBAction func onButtonShuttle(sender:UIButton){
        if (self.captureOutput != nil ){
            let connection=self.captureOutput.connections[0] as AVCaptureConnection
            self.captureOutput.captureStillImageAsynchronouslyFromConnection(connection, completionHandler: { (buffer, error) -> Void in
                let imageData=AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer)
                let image : UIImage=UIImage(data: imageData)
                ALAssetsLibrary().writeImageToSavedPhotosAlbum(image.CGImage, orientation: ALAssetOrientation.fromRaw(image.imageOrientation.toRaw())!, completionBlock: {
                        (url,error)-> () in
                    
                })
            })
        }
    }
    func updateDebugLabel(){
        var info = "mode: \(self.exposureMode)\n"
        if let iso_value = self.ISO {
            info = info + "ISO:"+iso_value.format(".1") + "\n"
        }
        if let exposureDurationSeconds_value = self.exposureDurationSeconds {
            info = info + "duration:"+exposureDurationSeconds_value.format(".2") + "\n"
        }
        if let lensPosition_value = self.lensPosition {
            info = info + "lens:"+lensPosition_value.format(".1") + "\n"
        }
        if let exposureTargetBias_value = self.exposureTargetBias {
            info = info + "bias:"+exposureTargetBias_value.format(".1") + "\n"
        }
        if let exposureTargetOffset_value = self.exposureTargetOffset {
            info = info + "offset:" + exposureTargetOffset_value.format(".1") + "\n"
        }
        self.debugLabel.text=info
        
    }
    @IBAction func onSegmentChanged(sender:UISegmentedControl){
        if (sender == self.segmentFunction){
            switch sender.selectedSegmentIndex{
            case 0:
                self.exposeView.hidden=false
                self.lenseView.hidden=true
                self.flashModeView.hidden = true
            case 1:
                self.exposeView.hidden = true
                self.lenseView.hidden = true
                self.flashModeView.hidden = true
            default:
                self.exposeView.hidden=true
                self.lenseView.hidden=true
                self.flashModeView.hidden = false
            }
        }
        else if sender == self.segmentExposure {
            var error : NSError?
            self.device.lockForConfiguration(&error)
            self.device.exposureMode = AVCaptureExposureMode.fromRaw(sender.selectedSegmentIndex)!
            self.device.unlockForConfiguration()
        }
        else if sender == self.segmentFocus {
            var error:NSError?
            self.device.lockForConfiguration(&error)
            self.device.focusMode = AVCaptureFocusMode.fromRaw(sender.selectedSegmentIndex)!
            self.device.unlockForConfiguration()
        }
        else if sender == self.segmentFlashMode {
            var error:NSError?
            self.device.lockForConfiguration(&error)
            self.device.flashMode = AVCaptureFlashMode.fromRaw(sender.selectedSegmentIndex)!
            self.device.unlockForConfiguration()
        }
    }
    @IBAction func onSlideChanged(sender:UISlider){
        if (sender == self.slide_exposureDuration && self.device.exposureMode == AVCaptureExposureMode.Custom){
//            let p = pow( Float64(sender.value), Float64(EXPOSURE_MINIMUM_DURATION) ) // Apply power function to expand slider's low-end range
//            let minDurationSeconds = max(CMTimeGetSeconds(self.device.activeFormat.minExposureDuration),
//                    Float64(EXPOSURE_MINIMUM_DURATION));
//            let maxDurationSeconds = CMTimeGetSeconds(self.device.activeFormat.maxExposureDuration);
//            let newDurationSeconds = p * ( maxDurationSeconds - minDurationSeconds ) + minDurationSeconds; // Scale from 0-1 slider range to actual duration
//            NSLog("newDurationSeconds:%f", newDurationSeconds)
            let exosureDuration = CMTimeMakeWithSeconds(Float64(self.slide_exposureDuration.value) / 1000,1000*1000*1000 )
            var error:NSError?
            self.device.lockForConfiguration(&error)
            self.device.setExposureModeCustomWithDuration(exosureDuration, ISO: AVCaptureISOCurrent, completionHandler: { (time) -> Void in
                
            })
            self.device.unlockForConfiguration()
        }
        else if (sender == self.slide_iso && self.device.exposureMode == AVCaptureExposureMode.Custom) {
            var error:NSError?
            self.device.lockForConfiguration(&error)
            self.device.setExposureModeCustomWithDuration(AVCaptureExposureDurationCurrent, ISO: self.slide_iso.value, completionHandler: { (time) -> Void in
                
            })
            self.device.unlockForConfiguration()
        }
        else if (sender == self.slide_baise && self.device.exposureMode != AVCaptureExposureMode.Custom){
            var error: NSError?
            self.device.lockForConfiguration(&error)
            self.device.setExposureTargetBias(self.slide_baise.value, completionHandler: { (time) -> Void in
                
            })
            self.device.unlockForConfiguration()
        }
        else if (sender == self.slide_lensPosition && self.device.focusMode == AVCaptureFocusMode.Locked) {
            var error : NSError?
            self.device.lockForConfiguration(&error)
            self.device.setFocusModeLockedWithLensPosition(self.slide_lensPosition.value, completionHandler: { (time) -> Void in
                
            })
            self.device.unlockForConfiguration()
        }
    }
}

