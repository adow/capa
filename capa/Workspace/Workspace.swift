//
//  Workspace.swift
//  capa
//
//  Created by 秦 道平 on 14/11/13.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

import UIKit
import AVFoundation
import AssetsLibrary
import ImageIO
import CoreLocation

var workspace_path : String!{
get{
    let document = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as String
    let workspace = document + "/workspace/"
    return workspace
}
}
enum PhotoModalState:Int,Printable{
    case undefined = 0, use = 1, remove = 2
    var description:String{
        switch self {
        case .undefined:
            return "undefined"
        case .use:
            return "use"
        case .remove:
            return "remove"
        }
    }
}
func == (left:PhotoModal,right:PhotoModal) -> Bool{
    return left.bundlePath == right.bundlePath
}
class PhotoModal:Equatable {
    let bundlePath :String!
    let thumbPath :String!
    let originalPath :String!
    var state :PhotoModalState
    var editing:Bool = false
    var thumgImage:UIImage?{
        return UIImage(contentsOfFile: self.thumbPath)
    }
    var originalImage:UIImage?{
        return UIImage(contentsOfFile: self.originalPath)
    }
    init(bundlePath:String,thumbPath:String,originalPath:String,state:PhotoModalState){
        self.bundlePath = bundlePath
        self.thumbPath = thumbPath
        self.originalPath = originalPath
        self.state = state
        self.load_info()
        
    }
    
    typealias CallBack = ()->()
    /// 保存到相机交卷
    func saveToCameraRoll(callback:CallBack? = nil){
        if let image = originalImage {
            ///meta
            let imageData = NSData(contentsOfFile: self.originalPath)
            let source = CGImageSourceCreateWithData(imageData, nil)
            let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as NSDictionary

            ALAssetsLibrary().writeImageToSavedPhotosAlbum(image.CGImage, metadata: metadata, completionBlock: { (url, error) -> Void in
                if let callback_value = callback {
                    callback_value()
                }
            })
        }
    }
    /// 删除相片文件
    func remove(){
        NSLog("remove photo:%@", self.bundlePath)
        var error : NSError?
        NSFileManager.defaultManager().removeItemAtPath(self.bundlePath, error: &error)
        if let error_value = error {
            NSLog("remove photo error:%@", error_value)
        }
    }
    var info_path :String {
        return self.bundlePath + "/info.json"
    }
    var exif_path :String{
        return self.bundlePath + "/exif.json"
    }
    var gps_path : String{
        return self.bundlePath + "/gps.json"
    }
    ///读取配置文件
    func load_info(){
        NSLog("load info:%@", self.info_path)
        let data = NSData(contentsOfFile: self.info_path)
        if let data_value = data {
            let dict = NSJSONSerialization.JSONObjectWithData(data_value, options: NSJSONReadingOptions.AllowFragments, error: nil) as NSDictionary
            let state_raw = dict["state"]?.integerValue
            if let state_raw_value = state_raw {
                self.state = PhotoModalState(rawValue: state_raw_value)!
            }
            
        }
    }
    ///写入配置文件
    func write_info(){
        let dict = ["state":NSNumber(integer: self.state.rawValue)] as NSDictionary
        let data = NSJSONSerialization.dataWithJSONObject(dict, options: NSJSONWritingOptions.PrettyPrinted, error: nil)
        data?.writeToFile(self.info_path, atomically: true)
        NSLog("write info:%@", self.info_path)
    }
    func updateState(_state:PhotoModalState){
        self.state = _state
        self.write_info()
    }
    ///获得 exif
    func load_exif() -> NSDictionary?{
        let data = NSData(contentsOfFile: self.exif_path)
        if let data = data {
            let dict = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: nil) as NSDictionary
            return dict
        }
        return nil
    }
    /// 获得 gps
    func load_gps() -> NSDictionary? {
        let data = NSData(contentsOfFile: self.gps_path)
        if let data = data {
            let dict = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: nil) as NSDictionary
            return dict
        }
        return nil
    }
}
func photo_list_in_workspace(state:PhotoModalState? = nil)->[PhotoModal]!{
    let workspace = workspace_path
    NSLog("workspace:%@", workspace)
    let filelist = NSFileManager.defaultManager().contentsOfDirectoryAtPath(workspace, error: nil) as [String]?
    var photo_list = [PhotoModal]()
    if let filelist_value = filelist {
        for one_file in filelist_value {
            if one_file.hasSuffix(".photo") {
                let photo = PhotoModal(bundlePath: workspace + one_file,
                    thumbPath: workspace + one_file + "/thumb.jpg",
                    originalPath: workspace + one_file + "/original.jpg",state:.undefined)
                if state == nil ||  photo.state == state {
                    photo_list.append(photo)
                }
            }
        }        
    }
    return photo_list.reverse()
}

///写入照片到工作区
func save_to_workspace(imageData:NSData,orientation:AVCaptureVideoOrientation,squareMarginPercent:CGFloat? = nil,
    location:CLLocation? = nil)->PhotoModal{
    var outputImageData:NSData! ///输出的照片数据内容
    /// rotate
    let image : UIImage=UIImage(data: imageData)!
    var imageOrientation : UIImageOrientation!
    switch orientation {
    case .LandscapeLeft:
        imageOrientation = UIImageOrientation.Right
    case .LandscapeRight:
        imageOrientation = UIImageOrientation.Left
    case .Portrait:
        imageOrientation = UIImageOrientation.Up
    case .PortraitUpsideDown:
        imageOrientation = UIImageOrientation.Down
    default:
        imageOrientation = UIImageOrientation.Up
    }
//    NSLog("imageOrientation:\(imageOrientation)")
    let originalImage = image.rotate(imageOrientation)
    var thumbImage : UIImage!
    /// square
    if let squareMarginPercent_value = squareMarginPercent {
        let squareImage = originalImage.squareImage(squareMarginPercent: squareMarginPercent!)
        outputImageData = UIImageJPEGRepresentation(squareImage, 1.0)
        thumbImage = squareImage.resizeImageWithTarget(item_width * 2.0)
    }
    else{
        outputImageData = UIImageJPEGRepresentation(originalImage, 1.0)
        thumbImage = originalImage.resizeImageWithTarget(item_width * 2.0)
    }
    /// metadata
    let metadata = metadata_from_image_data(imageData, location: location)
    let source = CGImageSourceCreateWithData(outputImageData, nil)
    let uti = CGImageSourceGetType(source)
    var dest_data = NSMutableData()
    var destination = CGImageDestinationCreateWithData(dest_data, uti, 1, nil)
    CGImageDestinationAddImageFromSource(destination, source, 0, metadata)
    let suc = CGImageDestinationFinalize(destination)
    /// write
    let workspace = workspace_path
    let bundle =  "\(workspace)\(NSDate().timeIntervalSince1970).photo"
    if !NSFileManager.defaultManager().fileExistsAtPath(bundle) {
        NSFileManager.defaultManager().createDirectoryAtPath(bundle, withIntermediateDirectories: true, attributes: nil, error: nil)
    }
    /// exif file
    let exif_filename = "\(bundle)/exif.json"
    let exif_dict = metadata[kCGImagePropertyExifDictionary as NSString] as? NSDictionary
    if let exif_dict = exif_dict {
        let exif_data = NSJSONSerialization.dataWithJSONObject(exif_dict, options: NSJSONWritingOptions.PrettyPrinted, error: nil)
        if let exif_data = exif_data {
            exif_data.writeToFile(exif_filename, atomically: true)
            NSLog("save exif to bundle:%@", exif_filename)
        }
    }
    /// gps file
    let gps_filename = "\(bundle)/gps.json"
    let gps_dict = metadata[kCGImagePropertyGPSDictionary as NSString] as? NSDictionary
    if let gps_dict = gps_dict {
        var dict_mutable = gps_dict.mutableCopy() as NSMutableDictionary
        dict_mutable.removeObjectForKey("TimeStamp")
        let gps_data = NSJSONSerialization.dataWithJSONObject(dict_mutable, options: NSJSONWritingOptions.PrettyPrinted, error: nil)
        if let gps_data = gps_data {
            gps_data.writeToFile(gps_filename, atomically: true)
            NSLog("save gps to bundle:%@", gps_filename)
        }
    }
    let original_filename = "\(bundle)/original.jpg"
    dest_data.writeToFile(original_filename, atomically: true)
    NSLog("save original to workspace:%@", original_filename)
    ///缩略图
    let thumbData = UIImageJPEGRepresentation(thumbImage, 1.0)
    let thumb_filename = "\(bundle)/thumb.jpg"
    thumbData.writeToFile(thumb_filename, atomically: true)
    NSLog("save thumb to workspace:%@", thumb_filename)
    
    return PhotoModal(bundlePath: bundle, thumbPath: thumb_filename, originalPath: original_filename,state:.undefined)
}
///直接存入相片集
func save_to_cameraroll(imageData:NSData,
    orientation:AVCaptureVideoOrientation,
    squareMarginPercent:CGFloat? = nil,
    location:CLLocation? = nil,
    callback:(()->())? = nil){
    var outputImageData:NSData! ///输出的照片数据内容
    let image : UIImage=UIImage(data: imageData)!
    var imageOrientation : UIImageOrientation!
    switch orientation {
    case .LandscapeLeft:
        imageOrientation = UIImageOrientation.Right
    case .LandscapeRight:
        imageOrientation = UIImageOrientation.Left
    case .Portrait:
        imageOrientation = UIImageOrientation.Up
    case .PortraitUpsideDown:
        imageOrientation = UIImageOrientation.Down
    default:
        imageOrientation = UIImageOrientation.Up
    }
    let rotateImage = image.rotate(imageOrientation)
    /// square
    if let squareMarginPercent_value = squareMarginPercent {
        let squareImage = rotateImage.squareImage(squareMarginPercent: squareMarginPercent!)
        outputImageData = UIImageJPEGRepresentation(squareImage, 1.0)
    }
    else{
        outputImageData = UIImageJPEGRepresentation(rotateImage, 1.0)
    }
    /// metadata
    let metadata = metadata_from_image_data(imageData, location: location)
    let source = CGImageSourceCreateWithData(outputImageData, nil)
    let uti = CGImageSourceGetType(source)
    var dest_data = NSMutableData()
    var destination = CGImageDestinationCreateWithData(dest_data, uti, 1, nil)
    CGImageDestinationAddImageFromSource(destination, source, 0, metadata)
    let suc = CGImageDestinationFinalize(destination)
   
    let outputImage = UIImage(data: outputImageData)
    ///meta
    ALAssetsLibrary().writeImageToSavedPhotosAlbum(outputImage!.CGImage, metadata: metadata, completionBlock: { (url, error) -> Void in
        if let callback = callback {
            callback()
        }
    })
}
/// 从数据中获取元数据信息
private func metadata_from_image_data (imageData:NSData,location:CLLocation? = nil)->NSDictionary {
    /// metadata
    let source = CGImageSourceCreateWithData(imageData, nil)
    let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as NSDictionary
    let metadata_mutable = metadata.mutableCopy() as NSMutableDictionary
    metadata_mutable.setObject(NSNumber(int: 0), forKey: "Orientation") ///修改方向为 up，因为下面会旋转图片
    let exif_dict = (metadata_mutable.objectForKey(kCGImagePropertyExifDictionary) as? NSDictionary)?.mutableCopy() as? NSMutableDictionary
    if let exif_dict = exif_dict {
        exif_dict.setObject("Capa Camera", forKey: kCGImagePropertyExifMakerNote as NSString) ///设置文件中的相机信息
        metadata_mutable.setObject(exif_dict, forKey: kCGImagePropertyExifDictionary as NSString)
    }
    //NSLog("exif:%@", exif_dict!)
    let tiff_dict = (metadata_mutable.objectForKey(kCGImagePropertyTIFFDictionary) as? NSDictionary)?.mutableCopy() as? NSMutableDictionary
    if let tiff_dict_value = tiff_dict {
        tiff_dict_value.setObject(NSNumber(int: 0), forKey: "Orientation") /// tiff 中的方向也修改为 up, 因为下面会旋转图片
        metadata_mutable.setObject(tiff_dict_value, forKey: kCGImagePropertyTIFFDictionary as NSString)
    }
    ///gps
    if let location_value = location {
        let location_dict = gps_dictionary_for_location(location_value) /// 写入 gps 信息
        metadata_mutable.setObject(location_dict, forKey: kCGImagePropertyGPSDictionary as NSString)
    }
    NSLog("metadata:%@", metadata_mutable)
    return metadata_mutable
}
///把gps数据整合为NSDictionary，用来写入到metadata
func gps_dictionary_for_location(location:CLLocation)->NSDictionary{
    var exifLatitude  = location.coordinate.latitude
    var exifLongitude = location.coordinate.longitude
    var latRef:NSString?
    var longRef:NSString?
    if (exifLatitude < 0.0) {
        exifLatitude = exifLatitude * -1.0
        latRef = "S"
    } else {
        latRef = "N"
    }
    
    if (exifLongitude < 0.0) {
        exifLongitude = exifLongitude * -1.0
        longRef = "W"
    } else {
        longRef = "E"
    }
    var locDict = NSMutableDictionary()
    locDict[kCGImagePropertyGPSTimeStamp as NSString] = location.timestamp
    locDict[kCGImagePropertyGPSLatitudeRef as NSString] = latRef
    locDict[kCGImagePropertyGPSLatitude as NSString] = NSNumber(double: exifLatitude)
    locDict[kCGImagePropertyGPSLongitudeRef as NSString] = longRef
    locDict[kCGImagePropertyGPSLongitude as NSString] = NSNumber(double: exifLongitude)
    locDict[kCGImagePropertyGPSDOP as NSString] = NSNumber(double: location.horizontalAccuracy)
    locDict[kCGImagePropertyGPSAltitude as NSString] = NSNumber(double: location.altitude)
    return locDict
}
