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
import ImageIO
import CoreLocation

let kGPS = "kGPS"
let kSQUARE = "kSQUARE"
class CameraViewController : UIViewController,UIGestureRecognizerDelegate,UIPickerViewDataSource,UIPickerViewDelegate,CLLocationManagerDelegate{
    // MARK: - AV
    var session:AVCaptureSession!
    var device:AVCaptureDevice!
    var captureOutput:AVCaptureStillImageOutput!
    var sessionQueue : dispatch_queue_t!
    ///全部的快门数
    lazy var shuttles:[Float] = {
       return [2,3,4,6,8,10,15,20,30,45,60,90,
        125,180,250,350,500,750,1000,1500,2000,3000,4000,6000,8000]
    }()
    ///全部iso
    lazy var isos:[Float] = {
       return [50,64,80,100,125,160,200,250,320,400,500,640,800,1000,1250,1600]
    }()
    var shuttles_available:[Float]=[Float]()
    var isos_availabel:[Float] = [Float]()
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
    var locationManager:CLLocationManager? = nil
    var currentLocation:CLLocation? = nil
    // MARK: - UI
    @IBOutlet var shuttleButton:UIButton!
    @IBOutlet var flashButton:FlashButton!
    @IBOutlet var previewView:CPPreviewView!
    @IBOutlet var debugLabel:UILabel!
    @IBOutlet var orientationDebugLabel:UILabel!
    @IBOutlet var touchView:UIView!
    @IBOutlet var focusView:FocusControl!
    @IBOutlet var exposureView:ExposureControl!
    @IBOutlet var shuttlesPickerView:UIPickerView!
    @IBOutlet var isoPickerView:UIPickerView!
    @IBOutlet var writingActivityView:UIActivityIndicatorView!
    @IBOutlet var shuttleISOLabelView:UIView!
    @IBOutlet var filmButton:UIButton!
    @IBOutlet var settingButton:UIButton!
    @IBOutlet var squareMaskView:UIView!
    @IBOutlet var sqaureConstraintTop:NSLayoutConstraint!
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
                    self.focusView.transform = CGAffineTransformIdentity
                    self.exposureView.transform = CGAffineTransformIdentity
                    self.flashButton.transform = CGAffineTransformIdentity
                    break
                case .LandscapeLeft:
                    self.focusView.transform = CGAffineTransformMakeRotation(radius(-90.0))
                    self.exposureView.transform = CGAffineTransformMakeRotation(radius(-90.0))
                    self.flashButton.transform = CGAffineTransformMakeRotation(radius(-90.0))
                    break
                case .LandscapeRight:
                    self.focusView.transform = CGAffineTransformMakeRotation(radius(90.0))
                    self.exposureView.transform = CGAffineTransformMakeRotation(radius(90.0))
                    self.flashButton.transform = CGAffineTransformMakeRotation(radius(90.0))
                    break
                case .PortraitUpsideDown:
                    self.focusView.transform = CGAffineTransformMakeRotation(radius(180.0))
                    self.focusView.transform = CGAffineTransformMakeRotation(radius(180.0))
                    self.flashButton.transform = CGAffineTransformMakeRotation(radius(180.0))
                    break
                default:
                    break
                }
                self.orientateShuttleAndISOLabel(self.cameraOriention)
            })
            
        }
    }
    /// shuttle 按钮在开始时的位置
    var shuttleButtonCenterStart:CGPoint = CGPoint(x: 0, y: 0)
    // MARK: - ViewController
    override func viewDidLoad() {
        self.view.layer.anchorPoint = CGPoint(x: 0.5, y:1.0)
        self.view.frame = CGRectOffset(self.view.frame,
            0.0,
            0.5 * self.view.frame.size.height)
        let anchor = CGPoint(x: 0.0, y: self.view.frame.size.height / 2)
        for child_view in self.shuttleISOLabelView.subviews {
            if let background_view = child_view as? UIView {
                background_view.layer.cornerRadius = 2.0
            }
        }
        self.shuttlesPickerView.layer.shadowColor = UIColor.blackColor().CGColor
        self.shuttlesPickerView.layer.shadowOpacity = 0.9
        self.shuttlesPickerView.layer.shadowRadius = 3.0
        self.shuttlesPickerView.layer.shadowOffset = CGSizeMake(3.0, 3.0)
//        self.shuttlesPickerView.layer.shadowPath = UIBezierPath(rect: self.shuttlesPickerView.layer.bounds).CGPath
        self.isoPickerView.layer.shadowColor = UIColor.blackColor().CGColor
        self.isoPickerView.layer.shadowOpacity = 0.9
        self.isoPickerView.layer.shadowRadius = 3.0
        self.isoPickerView.layer.shadowOffset = CGSizeMake(3.0, 3.0)
//        self.isoPickerView.layer.shadowPath = UIBezierPath(rect: self.isoPickerView.layer.bounds).CGPath
        
        session = AVCaptureSession()
        self.previewView.session=session
        self.sessionQueue=dispatch_queue_create("capture session",DISPATCH_QUEUE_SERIAL)
        dispatch_async(self.sessionQueue){
            [unowned self] () -> () in
            self.session.beginConfiguration()
            
            var error : NSError?
//            self.device=AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
            let devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
            for one_device in devices {
                if one_device.position == AVCaptureDevicePosition.Back {
                    self.device = one_device as AVCaptureDevice
                    break
                }
            }
            if (self.device == nil){
                NSLog("could not use camera")
                return
            }
            let captureInput = AVCaptureDeviceInput.deviceInputWithDevice(self.device, error: &error) as AVCaptureDeviceInput
            if let error_value = error {
                NSLog("error:%@", error_value)
                return
            }
            NSLog("minISO:%f,maxISO:%f,minDuration:%f,maxDuration:%f,lensApertue:%f",
                self.device.activeFormat.minISO,self.device.activeFormat.maxISO,
                CMTimeGetSeconds(self.device.activeFormat.minExposureDuration),
                CMTimeGetSeconds(self.device.activeFormat.maxExposureDuration),
                self.device.lensAperture)
            self.session .addInput(captureInput)
            self.captureOutput=AVCaptureStillImageOutput()
            let outputSettings=[AVVideoCodecKey:AVVideoCodecJPEG]
            self.captureOutput.outputSettings=outputSettings
            self.session.addOutput(self.captureOutput)
            self.session.sessionPreset = AVCaptureSessionPresetPhoto
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
                //self.previewView.addGestureRecognizer(self.focusTapGesture)
                self.touchView.addGestureRecognizer(self.focusTapGesture)
                self.panGesture = UIPanGestureRecognizer(target: self, action: "onPanGesture:")
//                self.previewView.addGestureRecognizer(self.panGesture)
                self.touchView.addGestureRecognizer(self.panGesture)
                
                
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
        _resetExposureFocus()
        _setFinderView()

        ///更新可用的ISO和快门速度
        updateAvailableISOAndShuttles()
        _hideFilmSettingButton()
        ///快门拖动手势
        let shuttlePanGesture = UIPanGestureRecognizer(target: self, action: "onPanGesture:")
        shuttleButton.addGestureRecognizer(shuttlePanGesture)
        ///用来识别方向
        motionManager = CMMotionManager()
        motionManager.accelerometerUpdateInterval = 1.0
        motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.mainQueue(), withHandler: { [unowned self](data, error) -> Void in
            //            NSLog("x:%f,y:%f,z:%f", data.acceleration.x,data.acceleration.y,data.acceleration.z)
            self.updateCameraOriention(data.acceleration)
        })
        ///location
        if NSUserDefaults.standardUserDefaults().boolForKey(kGPS) == true {
            locationManager = CLLocationManager()
            locationManager?.delegate = self
            locationManager?.pausesLocationUpdatesAutomatically = true
            locationManager?.activityType = CLActivityType.Fitness
            locationManager?.requestWhenInUseAuthorization()
            locationManager?.startUpdatingLocation()
        }
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onApplicationDidBecomeActiveNotification:", name: UIApplicationDidBecomeActiveNotification, object: nil)
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        motionManager.stopAccelerometerUpdates()
        locationManager?.stopUpdatingLocation()
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
        NSNotificationCenter.defaultCenter().removeObserver(self)
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
    ///设置取景器
    private func _setFinderView(){
        ///正方形取景器
        if NSUserDefaults.standardUserDefaults().boolForKey(kSQUARE) {
            let preview_width = self.previewView.frame.size.width
            let preview_height : CGFloat = preview_width / (3/4)
            let preview_top = (self.view.frame.size.height - preview_height) / 2.0
            let preview_bottom = preview_top + preview_height
            
            var squareMaskFrame = self.squareMaskView.frame
            let squareMaskTop = preview_top + preview_width
            squareMaskFrame.origin.y = squareMaskTop
            self.squareMaskView.frame = squareMaskFrame
            self.sqaureConstraintTop.constant = squareMaskTop
            self.squareMaskView.hidden = false
        }
        else{
            self.squareMaskView.hidden = true
        }
    }
    /// 重设自动曝光程序
    private func _resetExposureFocus(){
        var error:NSError?
        if device != nil {
            ///开始的时候都是自动对焦和测光
            device.lockForConfiguration(&error)
            device.exposureMode = AVCaptureExposureMode.ContinuousAutoExposure
            device.focusMode = AVCaptureFocusMode.ContinuousAutoFocus
            device.unlockForConfiguration()
        }
        ///曝光补偿控件先设置到屏幕中央，不能直接设置曝光补偿，因为那样会锁定补偿
        exposureView.center = previewView.center
        exposureView.updateConstraints()
    }
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
                ///有正方形取景框的时候剪裁为正方形
                if NSUserDefaults.standardUserDefaults().boolForKey(kSQUARE) {
                    save_to_workspace(imageData,self.cameraOriention,squareMarginPercent:0.0,
                        location: self.currentLocation)
                }
                else{
                    save_to_workspace(imageData, self.cameraOriention, location: self.currentLocation)
                }
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
    private func _showFilmSettingButton(){
        if (self.filmButton.alpha > 0.0) {
            return
        }
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: { () -> Void in
            self.filmButton.alpha = 0.3
            self.settingButton.alpha = 0.3
            }) { (completed) -> Void in
                
        }
    }
    private func _hideFilmSettingButton(){
        UIView.animateWithDuration(3.0, delay: 1.0, options: UIViewAnimationOptions.CurveEaseIn, animations: { () -> Void in
            self.filmButton.alpha = 0.0
            self.settingButton.alpha = 0.0
            }) { (completed) -> Void in
                
        }
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
        if gesture.view === self.touchView {
            if gesture.state == UIGestureRecognizerState.Began {                
                var error : NSError?
                self.device.lockForConfiguration(&error)
                self.device.exposureMode = AVCaptureExposureMode.Locked
            }
            else if (gesture.state == UIGestureRecognizerState.Ended || gesture.state == UIGestureRecognizerState.Cancelled) {
                device.unlockForConfiguration()
            }
            else if gesture.state == UIGestureRecognizerState.Changed {
                let move = gesture.translationInView(self.touchView)
                if self.cameraOriention == AVCaptureVideoOrientation.Portrait || self.cameraOriention == AVCaptureVideoOrientation.PortraitUpsideDown {
                    if fabs(move.y) >= 10 {
                        var bias = self.device.exposureTargetBias - Float(move.y / self.touchView.frame.size.height)
                        bias = min(bias, self.device.maxExposureTargetBias)
                        bias = max(bias, self.device.minExposureTargetBias)
                        self.device.setExposureTargetBias(bias, completionHandler: { (time) -> Void in
                            
                        })
                    }
                }
                else if self.cameraOriention == AVCaptureVideoOrientation.LandscapeLeft || self.cameraOriention == AVCaptureVideoOrientation.LandscapeRight {
                    if fabs(move.x) >= 10 {
                        var bias = self.device.exposureTargetBias + Float(move.x / self.touchView.frame.size.width)
                        bias = min(bias, self.device.maxExposureTargetBias)
                        bias = max(bias, self.device.minExposureTargetBias)
                        self.device.setExposureTargetBias(bias, completionHandler: { (time) -> Void in
                            
                        })
                    }
                }
            }
        }
        else if gesture.view === self.shuttleButton {
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
                self._showFilmSettingButton()
            }
            else if gesture.state == UIGestureRecognizerState.Ended || gesture.state == UIGestureRecognizerState.Cancelled {
                resetShuttleButton(self)
                self._hideFilmSettingButton()
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
                else if move.y <= -40.0 {
                    gesture.removeTarget(self, action: "onPanGesture:")
                    self.performSegueWithIdentifier("segue_camera_setting", sender: nil)
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
        var orientation:AVCaptureVideoOrientation!
        if acceleration.x >= 0.5 {
            orientation = AVCaptureVideoOrientation.LandscapeLeft
        }
        else if acceleration.x <= -0.5 {
            orientation = AVCaptureVideoOrientation.LandscapeRight
        }
        else if acceleration.y <= -0.5 {
            orientation = AVCaptureVideoOrientation.Portrait
        }
        else if acceleration.y >= 0.5 {
            orientation = AVCaptureVideoOrientation.PortraitUpsideDown
        }
        else{
            orientation = AVCaptureVideoOrientation.Portrait
        }
        let log = NSString(format: "\(self.cameraOriention),x:%@,y:%@,z:%@",
            acceleration.x.format(".1"),acceleration.y.format(".1"),acceleration.z.format("1."))
        self.orientationDebugLabel.text = log
        if orientation != self.cameraOriention {
            self.cameraOriention = orientation
            NSLog("cameraOrientation changed:\(self.cameraOriention)")
        }
        
    }
    ///旋转快门和iso提示文字
    private func orientateShuttleAndISOLabel(orientation:AVCaptureVideoOrientation){
        for child_view in self.shuttleISOLabelView.subviews {
            if let label = child_view as? UILabel {
                switch orientation{
                case AVCaptureVideoOrientation.Portrait:
                    label.transform = CGAffineTransformIdentity
                case AVCaptureVideoOrientation.LandscapeLeft:
                    label.transform = CGAffineTransformMakeRotation(radius(-90.0))
                case AVCaptureVideoOrientation.LandscapeRight:
                    label.transform = CGAffineTransformMakeRotation(radius(90.0))
                case AVCaptureVideoOrientation.PortraitUpsideDown:
                    label.transform = CGAffineTransformMakeRotation(radius(180.0))
                default:
                    label.transform = CGAffineTransformIdentity
                }
            }
        }
    }
    ///所有相机参数修改时更新界面
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
        let str_min_exposure_duration = CMTimeGetSeconds(self.device.activeFormat.minExposureDuration).format(".8")
        let str_max_exposure_duration = CMTimeGetSeconds(self.device.activeFormat.maxExposureDuration).format(".3")
        let info = "exposure:\(self.device.exposureMode),s:\(CMTimeGetSeconds(self.device.exposureDuration)),bias:\(self.device.exposureTargetBias),iso:\(self.device.ISO),exp_center:\(NSStringFromCGPoint(self.device.exposurePointOfInterest)),focus:\(self.device.focusMode),position:\(self.device.lensPosition),focus_center:\(NSStringFromCGPoint(self.device.focusPointOfInterest)),flash:\(self.device.flashMode),minISO:\(self.device.activeFormat.minISO),maxISO:\(self.device.activeFormat.maxISO),minDuration:\(str_min_exposure_duration),maxDuration:\(str_max_exposure_duration)"
        self.debugLabel.text = info
    }
    // MARK: Exposure
    private func updateAvailableISOAndShuttles(){
        self.isos_availabel.removeAll(keepCapacity:false)
        if self.device == nil {
            return
        }
        for one_iso in self.isos{
            if one_iso >= self.device.activeFormat.minISO && one_iso <= self.device.activeFormat.maxISO {
                self.isos_availabel.append(one_iso)
            }
        }
        
        self.shuttles_available.removeAll(keepCapacity: false)
        let min_seconds = CMTimeGetSeconds(self.device.activeFormat.minExposureDuration)
        let max_seconds = CMTimeGetSeconds(self.device.activeFormat.maxExposureDuration)
        for one_shuttle in self.shuttles {
            let seconds = 1.0 / Float64(one_shuttle)
            if seconds >= min_seconds && seconds <= max_seconds {
                self.shuttles_available.append(one_shuttle)
            }
        }
        self.isoPickerView.reloadAllComponents()
        self.shuttlesPickerView.reloadAllComponents()
    }
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
//            return shuttles.count
            return shuttles_available.count
        }
        else if pickerView == isoPickerView {
            return isos_availabel.count
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
//            let title = shuttles[row]
            let title = shuttles_available[row]
            label.text = "1/\(title)"
        }
        else if pickerView == isoPickerView {
//            let title = isos[row]
            let title = isos_availabel[row]
            label.text = "\(title)"
        }
        return label
    }
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        NSLog("didSelectRow:%d", row)
        var error:NSError?
        self.device.lockForConfiguration(&error)
        self.device.exposureMode = AVCaptureExposureMode.Custom
        NSLog("minISO:%f,maxISO:%f", self.device.activeFormat.minISO,self.device.activeFormat.maxISO)
        if pickerView === self.isoPickerView {
            let row_iso = self.isoPickerView.selectedRowInComponent(0)
//            let iso = self.isos[row_iso]
            let iso = self.isos_availabel[row_iso]
            self.device.setExposureModeCustomWithDuration(AVCaptureExposureDurationCurrent, ISO: iso, completionHandler: { (time) -> Void in
                
            })
        }
        else{
            let row_shuttles = self.shuttlesPickerView.selectedRowInComponent(0)
//            let shuttle = 1 / self.shuttles[row_shuttles]
            let shuttle = 1 / self.shuttles_available[row_shuttles]
            self.device.setExposureModeCustomWithDuration(CMTimeMakeWithSeconds(Float64(shuttle), 1000 * 1000 * 1000), ISO: AVCaptureISOCurrent, completionHandler: { (time) -> Void in
                
            })
        }
            
        
        self.device.unlockForConfiguration()
    }
    // MARK: - CLLocationManagerDelegate
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.NotDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        NSLog("location failed:%@", error)
    }
    func locationManager(manager: CLLocationManager!, didUpdateToLocation newLocation: CLLocation!, fromLocation oldLocation: CLLocation!) {
        NSLog("location:%@", newLocation)
        self.currentLocation = newLocation
    }
    /// MARK: - Notification
    func onApplicationDidBecomeActiveNotification(notification:NSNotification){
        NSLog("applicationDidBecomeActive")
        _resetExposureFocus()
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