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
    var thumgImage:UIImage? {
        return UIImage(contentsOfFile: thumbPath)
    }
    var originalImage:UIImage?{
        return UIImage(contentsOfFile: originalPath)
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
            ALAssetsLibrary().writeImageToSavedPhotosAlbum(image.CGImage,
                orientation: ALAssetOrientation(rawValue: image.imageOrientation.rawValue)!,
                completionBlock: {
                (url,error)-> () in
//                NSLog("save to:%@", url)
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
}
func photo_list_in_workspace(state:PhotoModalState? = nil)->[PhotoModal]!{
    let workspace = workspace_path
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
    return photo_list
}

func save_to_workspace(imageData:NSData,orientation:AVCaptureVideoOrientation)->PhotoModal{
    let workspace = workspace_path
    let bundle =  "\(workspace)\(NSDate().timeIntervalSince1970).photo"
    if !NSFileManager.defaultManager().fileExistsAtPath(bundle) {
        NSFileManager.defaultManager().createDirectoryAtPath(bundle, withIntermediateDirectories: true, attributes: nil, error: nil)
    }
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
    NSLog("imageOrientation:\(imageOrientation)")
    let originalImage = image.rotate(imageOrientation)
    let originalData = UIImageJPEGRepresentation(originalImage, 1.0)
    let original_filename = "\(bundle)/original.jpg"
    originalData.writeToFile(original_filename,atomically:true)
//    imageData.writeToFile(original_filename, atomically: true)
    NSLog("save original to workspace:%@", original_filename)
    
    let thumbImage = originalImage.resizeImageWithWidth(100.0)
//    let thumbImage = image.resizeImageWithWidth(100.0)
    let thumbData = UIImageJPEGRepresentation(thumbImage, 1.0)
    let thumb_filename = "\(bundle)/thumb.jpg"
    thumbData.writeToFile(thumb_filename, atomically: true)
    NSLog("save thumb to workspace:%@", thumb_filename)
    
    return PhotoModal(bundlePath: bundle, thumbPath: thumb_filename, originalPath: original_filename,state:.undefined)
}
