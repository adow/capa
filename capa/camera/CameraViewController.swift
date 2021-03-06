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
let kHIDEGUIDE = "kHIDEGUIDE"
let kDEBUG = "kDEBUG"
let kWORKFLOW = "kWORKFLOW"
let kHIDESHUTTLEGUIDE = "KHIDESHUTTLEGUIDE"
class CameraViewController : UIViewController,UIScrollViewDelegate{
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
    ///可用的快门数
    var shuttles_available:[Float]=[Float]()
    ///可用的 iso
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
    @IBOutlet weak var shuttleButton:UIButton!
    @IBOutlet weak var flashButton:FlashButton!
    @IBOutlet weak var previewView:CPPreviewView!
    @IBOutlet weak var debugLabel:UILabel!
    @IBOutlet weak var orientationDebugLabel:UILabel!
    @IBOutlet weak var touchView:UIView!
    @IBOutlet weak var focusView:FocusControl!
    @IBOutlet weak var exposureView:ExposureControl!
    @IBOutlet weak var shuttlesPickerView:UIPickerView!
    @IBOutlet weak var isoPickerView:UIPickerView!
    @IBOutlet weak var writingActivityView:UIActivityIndicatorView!
    @IBOutlet weak var shuttleISOLabelView:UIView!
    @IBOutlet weak var squareMaskView:UIView!
    @IBOutlet weak var sqaureConstraintTop:NSLayoutConstraint!
    @IBOutlet weak var guideView:UIVisualEffectView!
    @IBOutlet weak var guideScrollView:UIScrollView!
    @IBOutlet weak var guidePage:UIPageControl!
    @IBOutlet weak var gpsLoadingView:GpsLoadingView!
    @IBOutlet weak var shuttleGuideLabel:UILabel!
    var focusTapGesture : UITapGestureRecognizer!
    var focusPressGesture : UILongPressGestureRecognizer!
    var exposureTapGesutre: UITapGestureRecognizer!
    var panGesture : UIPanGestureRecognizer!
    var guideTapGesture:UITapGestureRecognizer!
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
                self.orientateShuttleAndISOLabel(self.cameraOriention)///选中一些其他的按钮
            })
            
        }
    }
    /// shuttle 按钮在开始时的位置
    var shuttleButtonCenterStart:CGPoint = CGPoint(x: 0, y: 0)
    ///引导页数量
    let totalGuides = 5
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
        ///快门和iso可以选择的列表
        self.shuttlesPickerView.layer.shadowColor = UIColor.blackColor().CGColor
        self.shuttlesPickerView.layer.shadowOpacity = 0.9
        self.shuttlesPickerView.layer.shadowRadius = 3.0
        self.shuttlesPickerView.layer.shadowOffset = CGSizeMake(3.0, 3.0)
        self.isoPickerView.layer.shadowColor = UIColor.blackColor().CGColor
        self.isoPickerView.layer.shadowOpacity = 0.9
        self.isoPickerView.layer.shadowRadius = 3.0
        self.isoPickerView.layer.shadowOffset = CGSizeMake(3.0, 3.0)
        
        ///引导图
        self.guideScrollView.contentSize = CGSize(width: 200.0 * CGFloat(totalGuides), height: 200.0)
        self.guideTapGesture = UITapGestureRecognizer(target: self, action: "onTapGesture:")
        self.guideView.addGestureRecognizer(self.guideTapGesture)
        
        session = AVCaptureSession()
        self.previewView.session=session
        self.sessionQueue=dispatch_queue_create("capture session",DISPATCH_QUEUE_SERIAL)
        dispatch_async(self.sessionQueue){
            [unowned self] () -> () in
            self.session.beginConfiguration()
            
            var error : NSError?
            let devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
            for one_device in devices {
                if one_device.position == AVCaptureDevicePosition.Back {
                    self.device = one_device as! AVCaptureDevice
                    break
                }
            }
            if (self.device == nil){
                NSLog("could not use camera")
                return
            }
            let captureInput = AVCaptureDeviceInput.deviceInputWithDevice(self.device, error: &error)as! AVCaptureDeviceInput
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
                self.touchView.addGestureRecognizer(self.focusTapGesture)
                self.panGesture = UIPanGestureRecognizer(target: self, action: "onPanGesture:")
                self.touchView.addGestureRecognizer(self.panGesture)
                
                
            })
        }
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.setNeedsStatusBarAppearanceUpdate()
        ///显示引导图
        guideView.hidden = NSUserDefaults.standardUserDefaults().boolForKey(kHIDEGUIDE)
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
        debugLabel.hidden = !NSUserDefaults.standardUserDefaults().boolForKey(kDEBUG)
        ///重新设置曝光和对焦方式
        _resetExposureFocus()
        ///设置取景器
        _setFinderView()
        ///开始的时候不要显示快门拖动提示
        self._toggleShuttleGuide(false)
        ///更新可用的ISO和快门速度
        updateAvailableISOAndShuttles()
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
            self.gpsLoadingView.hidden = false
            self.gpsLoadingView.state = .run
            ///点击显示当前的未知
            self.gpsLoadingView.onGpsTouched = {
                NSLog("tap location:%@", self.currentLocation!)
                let geocoder = CLGeocoder()
                geocoder.reverseGeocodeLocation(self.currentLocation!, completionHandler: { (result, errorCallback) -> Void in
                    let placemarks = result as! [CLPlacemark]
                    let place=placemarks[0]
                    let hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
                    hud.mode = MBProgressHUDModeText
                    hud.removeFromSuperViewOnHide = true
                    hud.detailsLabelText = "\(place.name)"
                    hud.hide(true, afterDelay: 1.0)
                })
            }
            ///处理定位超时的情况
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(300 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) { [unowned self]() -> Void in
                if let locationManager = self.locationManager {
                    locationManager.stopUpdatingLocation()
                    ///如果精度还可以，显示完成，否则显示定位结束
                    if self.currentLocation?.horizontalAccuracy < 300.0 {
                        self.gpsLoadingView.state = .completed
                    }
                    else{
                        self.gpsLoadingView.state = .stop
                    }
                }
            }
        }
        else{
            self.gpsLoadingView.hidden = true
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
    }
    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
    }
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
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
    /// 传统工作流，直接存入系统相册
    private func _saveToPhotosAlbum(){
        if (self.captureOutput != nil){
            self.cameraState = .writing
            let connection = self.captureOutput.connections[0] as! AVCaptureConnection
            self.captureOutput.captureStillImageAsynchronouslyFromConnection(connection, completionHandler: { (buffer, error) -> Void in
                let imageData=AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer)
                if NSUserDefaults.standardUserDefaults().boolForKey(kSQUARE) {
                    Workspace.saveToCameraRoll(imageData, orientation: self.cameraOriention, squareMarginPercent: 0.0, location: self.currentLocation, callback: { () -> () in
                        self.cameraState = .preview
                    })
                }
                else{
                    Workspace.saveToCameraRoll(imageData, orientation: self.cameraOriention, location: self.currentLocation, callback: { () -> () in
                        self.cameraState = .preview
                    })
                }
            })
        }
    }
    ///Capa 工作流，保存到工作区
    private func _saveToWorkspace(){
        self.cameraState = .writing
        if (self.captureOutput != nil){
            let connection = self.captureOutput.connections[0] as! AVCaptureConnection
            self.captureOutput.captureStillImageAsynchronouslyFromConnection(connection, completionHandler: {[unowned self] (buffer, error) -> Void in
                let imageData=AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer)
                ///有正方形取景框的时候剪裁为正方形
                if NSUserDefaults.standardUserDefaults().boolForKey(kSQUARE) {
                    Workspace.saveToWorkspace(imageData, orientation: self.cameraOriention, squareMarginPercent: 0.0, location: self.currentLocation)
                }
                else{
                    Workspace.saveToWorkspace(imageData, orientation: self.cameraOriention,location: self.currentLocation)
                }
                self.cameraState = .preview
            })
        }
    }
    ///按下快门按钮
    @IBAction func onShuttleButton(sender:UIButton!){
        ///屏幕一黑
        UIView.animateWithDuration(0.1, animations: { [unowned self]() -> Void in
           self.previewView.alpha = 0.0
        }) { (completed) -> Void in
            UIView.animateWithDuration(0.1, animations: { () -> Void in
               self.previewView.alpha = 1.0
            }, completion: { (completed) -> Void in
                
            })
        }
        if NSUserDefaults.standardUserDefaults().integerForKey(kWORKFLOW) == 0 {
            ////是否要提示快门拖动操作
            if !NSUserDefaults.standardUserDefaults().boolForKey(kHIDESHUTTLEGUIDE) {
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: kHIDESHUTTLEGUIDE)
                self._toggleShuttleGuide(true)
            }
            self._saveToWorkspace()
        }
        else{
            self._saveToPhotosAlbum()
        }
        
    }
    ///闪光灯模式切换按钮
    @IBAction func onFlashButton(sender:FlashButton!){
        NSLog("flashButton:%d", sender.currentItem!.value)
        var error : NSError?
        self.device.lockForConfiguration(&error)
        self.device.flashMode = AVCaptureFlashMode(rawValue: sender.currentItem!.value)!
        self.device.unlockForConfiguration()
    }
    ///关闭引导
    @IBAction func onButtonCloseGuide(sender:UIButton!){
        guideView.hidden = true
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: kHIDEGUIDE)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    ///是否显示快门拖动提示
    private func _toggleShuttleGuide(show:Bool){
        UIView.animateWithDuration(1.0, delay: 1.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            if !show {
                self.isoPickerView.alpha = 1.0
                self.shuttlesPickerView.alpha = 1.0
                self.gpsLoadingView.alpha = 1.0
                self.shuttleISOLabelView.alpha = 1.0
                self.shuttleGuideLabel.alpha = 0.0
            }
            else{
                self.isoPickerView.alpha = 0.0
                self.shuttlesPickerView.alpha = 0.0
                self.gpsLoadingView.alpha = 0.0
                self.shuttleISOLabelView.alpha = 0.0
                self.shuttleGuideLabel.alpha = 1.0
            }
        }) { (completed) -> Void in
        }
    }
    /// MARK: - Notification
    func onApplicationDidBecomeActiveNotification(notification:NSNotification){
        NSLog("applicationDidBecomeActive")
        ///重置曝光和对焦方式
        _resetExposureFocus()
    }
    /// MARK: - UIScrollViewDelegate
    func scrollViewDidScroll(scrollView: UIScrollView) {
        ///引导图换页面
        let x = scrollView.contentOffset.x
        let page = Int(x / 200.0)
        guidePage.currentPage = page
    }
    
}
// MARK: - Gesture
extension CameraViewController:UIGestureRecognizerDelegate{
    /// 触摸就显示对焦点，对焦点出现后可以拖动位置
    func onTapGesture(gesture:UITapGestureRecognizer){
        if gesture.view == self.touchView {
            let center = gesture.locationInView(self.previewView)
            let focus_x = center.x / self.previewView.frame.size.width
            let focus_y = center.y / self.previewView.frame.size.height
            self.focusView.updateFocusPointOfInterest(CGPoint(x: focus_x, y: focus_y))
        }
        else if gesture.view == self.guideView {
            ///处理引导图触摸操作
            let page = Int(guideScrollView.contentOffset.x / 200.0)
            if page < totalGuides-1 {
                let to_x = 200.0 * CGFloat(page + 1)
                guideScrollView.setContentOffset(CGPointMake(to_x, 0.0), animated: true)
            }
            else{
                guideView.hidden = true
                self.onButtonCloseGuide(nil)
            }
        }
    }
    ///在 Preview 上拖动就可以设置曝光补偿，同时会出现测光点，这时可以修改测光点
    func onPanGesture(gesture:UIPanGestureRecognizer){
        /// 在preview 上拖动
        if gesture.view === self.touchView {
            if gesture.state == UIGestureRecognizerState.Began {                
                self.exposureView.hidden = false
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
                    if NSUserDefaults.standardUserDefaults().integerForKey(kWORKFLOW) == 0 { ///只有 capa 工作流可以拖动进入工作区
                        gesture.removeTarget(self, action: "onPanGesture:")
                        self.performSegueWithIdentifier("segue_camera_workspace", sender: nil)
                    }
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
}
// MARK: - Update UI
extension CameraViewController{
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
        self.orientationDebugLabel.text = log as String
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
        self.exposureView.updateState()
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
        focusView.updateState()
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
}
// MARK: - CLLocationManagerDelegate
extension CameraViewController:CLLocationManagerDelegate{
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.NotDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        NSLog("location failed:%@", error)
    }
    func locationManager(manager: CLLocationManager!, didUpdateToLocation newLocation: CLLocation!, fromLocation oldLocation: CLLocation!) {
        if newLocation.horizontalAccuracy < 0.0{
            return
        }
        NSLog("location:%@", newLocation)
        self.currentLocation = newLocation
        if newLocation.horizontalAccuracy < 300.0 {
            manager.stopUpdatingLocation()
            self.gpsLoadingView.state = .completed
        }
    }
}
// MARK: - UIPicketView
extension CameraViewController:UIPickerViewDataSource,UIPickerViewDelegate{
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
            let title = Int(shuttles_available[row])
            label.text = "1/\(title)"
        }
        else if pickerView == isoPickerView {
            //            let title = isos[row]
            let title = Int(isos_availabel[row])
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
}