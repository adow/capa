//
//  CameraViewController.swift
//  capa
//
//  Created by 秦 道平 on 14/10/22.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class CameraViewController : UIViewController, UIPickerViewDataSource,UIPickerViewDelegate {
    // MARK: - AV
    var session:AVCaptureSession!
    var device:AVCaptureDevice!
    var captureOutput:AVCaptureStillImageOutput!
    var sessionQueue : dispatch_queue_t!
    // MARK: - UI
    @IBOutlet var flashButton:FlashButton!
    @IBOutlet var previewView:CPPreviewView!
    @IBOutlet var debugLabel:UILabel!
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            return 3
    }
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
            return 1
    }
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
            return "selection \(row)"
    }
    
    // MARK: - ViewController
    override func viewDidLoad() {
        session = AVCaptureSession()
        self.previewView.session=session
        self.sessionQueue=dispatch_queue_create("capture session",DISPATCH_QUEUE_SERIAL)
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
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.updateExposureMode()
                self.updateExposureISO()
                self.updateExposureShuttle()
                self.updateExposureTargetBias()
                self.updateFocusMode()
                self.updateFocusLensPosition()
                self.updateFlashMode()
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
    @IBAction func onFlashButton(sender:FlashButton!){
        NSLog("flashButton:%d", sender.stateItem!.value)
        var error : NSError?
        self.device.lockForConfiguration(&error)
        self.device.flashMode = AVCaptureFlashMode(rawValue: sender.stateItem!.value)!
        self.device.unlockForConfiguration()
    }
    // MARK: - Update UI
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        switch keyPath {
            case "exposureDuration":
                if let duration = change[NSKeyValueChangeNewKey]?.CMTimeValue {
                    self.updateExposureShuttle(duration: duration)
                }
                
                break
            case "ISO":
                if let iso = change[NSKeyValueChangeNewKey]?.floatValue {
                    self.updateExposureISO(iso: iso)
                }
                break
            case "lensPosition":
                if let lensPosition = change[NSKeyValueChangeNewKey]?.floatValue {
                    self.updateFocusLensPosition(lensPosition: lensPosition)
                }
                break
            case "exposureTargetBias":
                if let bias = change[NSKeyValueChangeNewKey]?.floatValue {
                    self.updateExposureTargetBias(bias: bias)
                }
                break
            case "exposureTargetOffset":
                break
            case "exposureMode":
                self.updateExposureMode()
                break
            case "focusMode":
                self.updateFocusMode()
                break
            case "flashMode":
                self.updateFlashMode()
                break
            default:
                break
        }
        self.updateDebug()
    }
    private func updateDebug(){
        let info = "exposure:\(self.device.exposureMode),s:\(CMTimeGetSeconds(self.device.exposureDuration)),bias:\(self.device.exposureTargetBias),iso:\(self.device.ISO),exp_center:\(NSStringFromCGPoint(self.device.exposurePointOfInterest)),focus:\(self.device.focusMode),position:\(self.device.lensPosition),focus_center:\(NSStringFromCGPoint(self.device.focusPointOfInterest)),flash:\(self.device.flashMode)"
        self.debugLabel.text = info
    }
    // MARK: Exposure
    private func updateExposureMode(){
        let mode = self.device.exposureMode
        NSLog("updateExposureMode:\(mode)")
    }
    private func updateExposureISO(iso:Float = AVCaptureISOCurrent){
        NSLog("updateExposureISO:%f", iso)
    }
    private func updateExposureShuttle(duration:CMTime = AVCaptureExposureDurationCurrent){
        let seconds = CMTimeGetSeconds(duration)
        NSLog("updateExposureShuttle:%f", seconds)
    }
    private func updateExposureTargetBias(bias:Float = AVCaptureExposureTargetBiasCurrent){
        NSLog("updateExposureTargetBias:%f", bias)
    }
    private func updateExposureTargetOffset(targetOffset:Float? = nil){
        
    }
    private func updateExposurePointOfInterest(){
        
    }
    // MARK: Focus
    private func updateFocusMode(){
        let mode = self.device.focusMode
        NSLog("updateFocusMode:\(mode)")
    }
    private func updateFocusLensPosition(lensPosition:Float = AVCaptureLensPositionCurrent){
        NSLog("updateFocusLensPosition:%f", lensPosition)
    }
    private func updateFocusPointOfInterest(){
        
    }
    // MARK: Flash light
    private func updateFlashMode(){
        let mode = self.device.flashMode
        NSLog("updateFlashMode:\(mode)")
    }
}