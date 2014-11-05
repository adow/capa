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

class CameraViewController : UIViewController,UIGestureRecognizerDelegate{
    // MARK: - AV
    var session:AVCaptureSession!
    var device:AVCaptureDevice!
    var captureOutput:AVCaptureStillImageOutput!
    var sessionQueue : dispatch_queue_t!
    // MARK: - UI
    @IBOutlet var flashButton:FlashButton!
    @IBOutlet var previewView:CPPreviewView!
    @IBOutlet var debugLabel:UILabel!
    @IBOutlet var focusView:FocusControl!
    @IBOutlet var exposureView:ExposureControl!
    var focusTapGesture : UITapGestureRecognizer!
    var focusPressGesture : UILongPressGestureRecognizer!
    var exposureTapGesutre: UITapGestureRecognizer!
    var panGesture : UIPanGestureRecognizer!
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
            dispatch_async(dispatch_get_main_queue(), { [unowned self] () -> Void in
                self.focusView.device = self.device
                self.focusView.center = self.previewView.center
                self.exposureView.device = self.device
                self.exposureView.center = self.previewView.center
                
                self.updateExposureMode()
                self.updateExposureISO()
                self.updateExposureShuttle()
                self.updateExposureTargetBias()
                self.updateFocusMode()
                self.updateFocusLensPosition()
                self.updateFlashMode()
                
                self.focusTapGesture = UITapGestureRecognizer(target: self, action: "onTapGesture:")
                self.previewView.addGestureRecognizer(self.focusTapGesture)
                self.panGesture = UIPanGestureRecognizer(target: self, action: "onPanGesture:")
                self.previewView.addGestureRecognizer(self.panGesture)
                
                
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
    // MARK: - Gesture
    /// 触摸就显示对焦点，对焦点出现后可以拖动位置
    func onTapGesture(gesture:UITapGestureRecognizer){
        let center = gesture.locationInView(self.previewView)
        let focus_x = center.x / self.previewView.frame.size.width
        let focus_y = center.y / self.previewView.frame.size.height
        self.focusView.updateFocusPointOfInterest(CGPoint(x: focus_x, y: focus_y))
    }
    ///在 Preview 上拖动就可以设置曝光补偿，同时会出现测光点，这时可以修改测光点
    func onPanGesture(gesture:UIPanGestureRecognizer){
        if gesture.state == UIGestureRecognizerState.Began {
            var error : NSError?
            self.device.lockForConfiguration(&error)
            self.device.exposureMode = AVCaptureExposureMode.Locked
        }
        else if (gesture.state == UIGestureRecognizerState.Ended || gesture.state == UIGestureRecognizerState.Cancelled) {
            device.unlockForConfiguration()
        }
        else if gesture.state == UIGestureRecognizerState.Changed {
            let move = gesture.translationInView(self.previewView)
            if fabs(move.y) >= 10 {
                var bias = self.device.exposureTargetBias - Float(move.y / self.previewView.frame.size.height)
                bias = min(bias, 8.0)
                bias = max(bias, -8.0)
                self.device.setExposureTargetBias(bias, completionHandler: { (time) -> Void in
                    
                })
            }
        }
    
    }
    // MARK: GestureDelegate
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
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
                    self.updateExposureTargetBias()
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
        if mode == AVCaptureExposureMode.AutoExpose || mode == AVCaptureExposureMode.Locked{
            self.exposureView.state = ExposureControl.State.Active
        }
    }
    private func updateExposureISO(iso:Float = AVCaptureISOCurrent){
        NSLog("updateExposureISO:%f", iso)
    }
    private func updateExposureShuttle(duration:CMTime = AVCaptureExposureDurationCurrent){
        let seconds = CMTimeGetSeconds(duration)
        NSLog("updateExposureShuttle:%f", seconds)
    }
    private func updateExposureTargetBias(){
        NSLog("updateExposureTargetBias:%f", self.device.exposureTargetBias)
        self.exposureView.updateTargetBias(self.device.exposureTargetBias)
    }
    private func updateExposureTargetOffset(){
    }
    // MARK: Focus
    private func updateFocusMode(){
        let mode = self.device.focusMode
        NSLog("updateFocusMode:\(mode)")
        if mode == AVCaptureFocusMode.AutoFocus {
            self.focusView.state = FocusControl.State.Active
        }
    }
    private func updateFocusLensPosition(lensPosition:Float = AVCaptureLensPositionCurrent){
        NSLog("updateFocusLensPosition:%f", lensPosition)
        self.focusView.updateLensPosition(lensPosition)
    }
    // MARK: Flash light
    private func updateFlashMode(){
        let mode = self.device.flashMode
        NSLog("updateFlashMode:\(mode)")
    }
}