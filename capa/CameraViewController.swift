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
import AssetsLibrary
import CoreMotion

class CameraViewController : UIViewController,UIGestureRecognizerDelegate,UIPickerViewDataSource,UIPickerViewDelegate{
    // MARK: - AV
    var session:AVCaptureSession!
    var device:AVCaptureDevice!
    var captureOutput:AVCaptureStillImageOutput!
    var sessionQueue : dispatch_queue_t!
    lazy var shuttles:[Float] = {
       return [1,2,3,4,6,8,10,15,20,30,45,60,90,
        125,180,250,350,500,750,1000]
    }()
    lazy var isos:[Float] = {
       return [50,64,80,100,125,160,200,250,320,400,500,640]
    }()
    /// 相机的状态，是拍摄还是写入中
    enum CameraState : Int,Printable {
        case preview = 0, writing = 1
        var description:String{
            switch self {
            case .preview:
                return "preview"
            case .writing:
                return "writing"
            }
        }
    }
    ///相机的状态
    var cameraState:CameraState!{
        didSet{
            if cameraState == .preview {
                self.view.userInteractionEnabled = true
                self.writingActivityView.stopAnimating()
            }
            else if cameraState == .writing {
                self.view.userInteractionEnabled = false
                self.writingActivityView.startAnimating()
            }
        }
    }
    // MARK: - UI
    @IBOutlet var shuttleButton:UIButton!
    @IBOutlet var flashButton:FlashButton!
    @IBOutlet var previewView:CPPreviewView!
    @IBOutlet var debugLabel:UILabel!
    @IBOutlet var focusView:FocusControl!
    @IBOutlet var exposureView:ExposureControl!
    @IBOutlet var shuttlesPickerView:UIPickerView!
    @IBOutlet var isoPickerView:UIPickerView!
    @IBOutlet var workspaceButton:UIButton!
    @IBOutlet var writingActivityView:UIActivityIndicatorView!
    var focusTapGesture : UITapGestureRecognizer!
    var focusPressGesture : UILongPressGestureRecognizer!
    var exposureTapGesutre: UITapGestureRecognizer!
    var panGesture : UIPanGestureRecognizer!
    var motionManager:CMMotionManager!
    var cameraOriention:AVCaptureVideoOrientation!{
        /// 设置完之后更新相机方向
        didSet{
            UIView.animateWithDuration(0.3, animations: { [unowned self]() -> Void in
                switch self.cameraOriention! {
                case AVCaptureVideoOrientation.Portrait:
                    self.workspaceButton.transform = CGAffineTransformIdentity
                    self.focusView.transform = CGAffineTransformIdentity
                    self.exposureView.transform = CGAffineTransformIdentity
                    self.flashButton.transform = CGAffineTransformIdentity
                    break
                case .LandscapeLeft:
                    self.workspaceButton.transform = CGAffineTransformMakeRotation(radius(-90.0))
                    self.focusView.transform = CGAffineTransformMakeRotation(radius(-90.0))
                    self.exposureView.transform = CGAffineTransformMakeRotation(radius(-90.0))
                    self.flashButton.transform = CGAffineTransformMakeRotation(radius(-90.0))
                    break
                case .LandscapeRight:
                    self.workspaceButton.transform = CGAffineTransformMakeRotation(radius(90.0))
                    self.focusView.transform = CGAffineTransformMakeRotation(radius(90.0))
                    self.exposureView.transform = CGAffineTransformMakeRotation(radius(90.0))
                    self.flashButton.transform = CGAffineTransformMakeRotation(radius(90.0))
                    break
                case .PortraitUpsideDown:
                    self.workspaceButton.transform = CGAffineTransformMakeRotation(radius(180.0))
                    self.focusView.transform = CGAffineTransformMakeRotation(radius(180.0))
                    self.focusView.transform = CGAffineTransformMakeRotation(radius(180.0))
                    self.flashButton.transform = CGAffineTransformMakeRotation(radius(180.0))
                    break
                default:
                    break
                }
            })
            
        }
    }
    /// shuttle 按钮在开始时的位置
    var shuttleButtonCenterStart:CGPoint = CGPoint(x: 0, y: 0)
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
                self.cameraOriention = AVCaptureVideoOrientation.Portrait
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
//        self.testImageRotate()
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.setNeedsStatusBarAppearanceUpdate()
        dispatch_async(self.sessionQueue, { () -> Void in
            if self.device != nil {
                self.device.addObserver(self,forKeyPath: "exposureDuration",options: .New ,context: nil)
                self.device.addObserver(self, forKeyPath: "lensPosition", options: .New, context: nil)
                self.device.addObserver(self, forKeyPath: "exposureTargetBias", options: .New, context: nil)
                self.device.addObserver(self, forKeyPath: "exposureTargetOffset", options: .New, context: nil)
                self.device.addObserver(self, forKeyPath: "ISO", options: .New, context: nil)
                self.device.addObserver(self, forKeyPath: "exposureMode", options: .New, context: nil)
                self.device.addObserver(self, forKeyPath: "focusMode", options: .New, context: nil)
                self.device.addObserver(self, forKeyPath: "flashMode", options: .New, context: nil)
                self.session.startRunning()
            }
        })
        
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        motionManager = CMMotionManager()
        motionManager.accelerometerUpdateInterval = 1.0
        motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.mainQueue(), withHandler: { [unowned self](data, error) -> Void in
//            NSLog("x:%f,y:%f,z:%f", data.acceleration.x,data.acceleration.y,data.acceleration.z)
            self.updateCameraOriention(data.acceleration)
        })
        let shuttlePanGesture = UIPanGestureRecognizer(target: self, action: "onPanGesture:")
        self.shuttleButton.addGestureRecognizer(shuttlePanGesture)
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        motionManager.stopAccelerometerUpdates()
    }
    override func viewDidDisappear(animated:Bool){
        super.viewDidDisappear(animated)
        if (self.device != nil) {
            self.device.removeObserver(self, forKeyPath: "exposureDuration")
            self.device.removeObserver(self, forKeyPath: "lensPosition")
            self.device.removeObserver(self, forKeyPath: "exposureTargetBias")
            self.device.removeObserver(self, forKeyPath: "exposureTargetOffset")
            self.device.removeObserver(self, forKeyPath: "ISO")
            self.device.removeObserver(self, forKeyPath: "exposureMode")
            self.device.removeObserver(self, forKeyPath: "focusMode")
            self.device.removeObserver(self, forKeyPath: "flashMode")
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
//        let layer=self.previewView.layer as AVCaptureVideoPreviewLayer
//        if (layer.connection != nil ){
//            layer.connection.videoOrientation = AVCaptureVideoOrientation(ui: toInterfaceOrientation)
//        }
    }
    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
//        let layer=self.previewView.layer as AVCaptureVideoPreviewLayer
//        if (layer.connection != nil ){
//            layer.connection.videoOrientation = AVCaptureVideoOrientation(ui: toInterfaceOrientation)
//        }
    }
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
//        let layer=self.previewView.layer as AVCaptureVideoPreviewLayer
//        if (layer.connection != nil ){
//            if size.width == 320.0 {
//                layer.connection.videoOrientation = AVCaptureVideoOrientation.Portrait
//            }
//            else if size.width == 480.0 {
//                layer.connection.videoOrientation = AVCaptureVideoOrientation.LandscapeLeft
//            }
//        }
    }
    
    // MARK: - Action
    private func _saveToPhotosAlbum(){
        if (self.captureOutput != nil){
            let connection = self.captureOutput.connections[0] as AVCaptureConnection
            self.captureOutput.captureStillImageAsynchronouslyFromConnection(connection, completionHandler: { (buffer, error) -> Void in
                let imageData=AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer)
                let image : UIImage=UIImage(data: imageData)!
                ALAssetsLibrary().writeImageToSavedPhotosAlbum(image.CGImage, orientation: ALAssetOrientation(rawValue: image.imageOrientation.rawValue)!, completionBlock: {
                    (url,error)-> () in
                    
                })
            })
        }
    }
    private func _saveToWorkspace(){
        self.cameraState = .writing
        if (self.captureOutput != nil){
            let connection = self.captureOutput.connections[0] as AVCaptureConnection
            self.captureOutput.captureStillImageAsynchronouslyFromConnection(connection, completionHandler: {[unowned self] (buffer, error) -> Void in
                let imageData=AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer)
                save_to_workspace(imageData,self.cameraOriention)
                self.cameraState = .preview
            })
        }
    }
    @IBAction func onShuttleButton(sender:UIButton!){
//        self._saveToPhotosAlbum()
        self._saveToWorkspace()
//        NSLog("capture photo")
        
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
        /// 在preview 上拖动
        if gesture.view == self.previewView {
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
        else if gesture.view == self.shuttleButton {
//            NSLog("pan on shuttle")
            /// 快门按钮回到原位
            func resetShuttleButton(_weak_self:CameraViewController!,delay:NSTimeInterval = 0.0)->(){
                UIView.animateWithDuration(0.1, delay: delay,
                    options: UIViewAnimationOptions.CurveEaseIn,
                    animations: {() -> Void in
                    _weak_self.shuttleButton.center = _weak_self.shuttleButtonCenterStart
                }, completion: { (completed) -> Void in
                    
                })
            }
            if gesture.state == UIGestureRecognizerState.Began {
                shuttleButtonCenterStart = shuttleButton.center
            }
            else if gesture.state == UIGestureRecognizerState.Ended || gesture.state == UIGestureRecognizerState.Cancelled {
                resetShuttleButton(self)
            }
            else if gesture.state == UIGestureRecognizerState.Changed {
                let min_x = CGFloat(0.0)
                let min_y = self.view.frame.size.height - 100.0
                let max_x = CGFloat(100.0)
                let max_y = self.view.frame.size.height + 10.0
                
                let move = gesture.translationInView(self.shuttleButton)
                var x = shuttleButtonCenterStart.x + move.x
                var y = shuttleButtonCenterStart.y + move.y
                x = fmin(fmax(x, min_x),max_x)
                y = fmin(fmax(y, min_y),max_y)
                let new_center = CGPoint(x: x, y: y)
                shuttleButton.center = new_center
                
                if move.y >= 40.0 {
                    gesture.removeTarget(self, action: "onPanGesture:")
                    self.performSegueWithIdentifier("segue_camera_workspace", sender: nil)
                    resetShuttleButton(self, delay: 0.3)
                    
                }
            }
            
            
        }
    
    }
    // MARK: GestureDelegate
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    // MARK: - Update UI
    /// 修改屏幕方向
    private func updateCameraOriention(acceleration:CMAcceleration){
        //        NSLog("accelerationY:%f", accelerationY)
        var orientation:AVCaptureVideoOrientation!
        if acceleration.y <= -1.0 && acceleration.y >= -0.5 {
            orientation = AVCaptureVideoOrientation.Portrait
        }
        else if acceleration.y >= -0.5 && acceleration.y <= 0.5 {
            if acceleration.x > 0.0 {
                orientation = AVCaptureVideoOrientation.LandscapeLeft
            }
            else{
                orientation = AVCaptureVideoOrientation.LandscapeRight
            }
        }
        else if acceleration.y >= 0.5 && acceleration.y <= 1.0 {
            orientation = AVCaptureVideoOrientation.PortraitUpsideDown
        }
        else{
            orientation = AVCaptureVideoOrientation.Portrait
        }
        if orientation != self.cameraOriention {
            self.cameraOriention = orientation
            NSLog("cameraOrientation changed:\(self.cameraOriention)")
        }
        
    }
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
//        NSLog("updateExposureMode:\(mode)")
        if mode == AVCaptureExposureMode.AutoExpose || mode == AVCaptureExposureMode.Locked{
            self.exposureView.state = ExposureControl.State.Active
        }
    }
    private func updateExposureISO(iso:Float = AVCaptureISOCurrent){
//        NSLog("updateExposureISO:%f", iso)
        var min_iso = iso
        var min_distance:Float = 1000000
        var to_row = 0
        let rows =  0..<isos.count
        for one_row in rows {
            let one_iso = isos[one_row]
            let distance = fabsf(one_iso - iso)
            if (distance < min_distance) {
                min_distance = distance
                min_iso = one_iso
                to_row = one_row
            }
        }
//        NSLog("to_row:%d", to_row)
        self.isoPickerView.selectRow(to_row, inComponent: 0, animated: true)
        
    }
    private func updateExposureShuttle(duration:CMTime = AVCaptureExposureDurationCurrent){
        let seconds = CMTimeGetSeconds(duration)
//        NSLog("updateExposureShuttle:%f", seconds)
        var min_shuttles = duration
        var min_distance:Float = 10000000
        var to_row = 0
        let rows = 0..<self.shuttles.count
        for one_row in rows {
            let one_duration = 1 / self.shuttles[one_row]
            let distance = fabsf(one_duration - Float(seconds))
            if distance < min_distance {
                min_distance = distance
                to_row = one_row
            }
        }
        self.shuttlesPickerView.selectRow(to_row, inComponent: 0, animated: true)
    }
    private func updateExposureTargetBias(){
//        NSLog("updateExposureTargetBias:%f", self.device.exposureTargetBias)
        self.exposureView.updateTargetBias(self.device.exposureTargetBias)
    }
    private func updateExposureTargetOffset(){
    }
    // MARK: Focus
    private func updateFocusMode(){
        let mode = self.device.focusMode
//        NSLog("updateFocusMode:\(mode)")
        if mode == AVCaptureFocusMode.AutoFocus {
            self.focusView.state = FocusControl.State.Active
        }
    }
    private func updateFocusLensPosition(lensPosition:Float = AVCaptureLensPositionCurrent){
//        NSLog("updateFocusLensPosition:%f", lensPosition)
        self.focusView.updateLensPosition(lensPosition)
    }
    // MARK: Flash light
    private func updateFlashMode(){
        let mode = self.device.flashMode
        NSLog("updateFlashMode:\(mode)")
    }
    // MARK: - UIPicketView
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView === shuttlesPickerView {
            return shuttles.count
        }
        else if pickerView == isoPickerView {
            return isos.count
        }
        else {
            return 3
        }
    }
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        return "1/\(row)"
    }
    func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView!) -> UIView {
        let label = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: 100.0, height: 44.0))
        label.textAlignment = NSTextAlignment.Center
        label.textColor = UIColor.whiteColor()
        if pickerView === shuttlesPickerView {
            let title = shuttles[row]
            label.text = "1/\(title)"
        }
        else if pickerView == isoPickerView {
            let title = isos[row]
            label.text = "\(title)"
        }
        return label
    }
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        NSLog("didSelectRow:%d", row)
        let row_shuttles = self.shuttlesPickerView.selectedRowInComponent(0)
        let row_iso = self.isoPickerView.selectedRowInComponent(0)
        let iso = self.isos[row_iso]
        let shuttle = 1 / self.shuttles[row_shuttles]
        var error:NSError?
        self.device.lockForConfiguration(&error)
        self.device.exposureMode = AVCaptureExposureMode.Custom
        self.device.setExposureModeCustomWithDuration(CMTimeMakeWithSeconds(Float64(shuttle), 1000), ISO: iso) { (time) -> Void in
            
        }
        self.device.unlockForConfiguration()
    }
    /// MARK: - Test
    func testImageRotate(){
//        let image = UIImage(named: "cards")
        let image = UIImage(named: "solar")
        NSLog("imageOrientation:\(image?.imageOrientation)")
        let image_rotate = image?.rotate(UIImageOrientation.Right)
//        let imageView = UIImageView(image: image!)
        let imageView = UIImageView(image: image_rotate!)
        self.view.addSubview(imageView)
        
    }
}