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
class PhotoModal {
    let bundlePath :String!
    let thumbPath :String!
    let originalPath :String!
    var state :PhotoModalState
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
        
    }
    /// 保存到相机交卷
    func saveToCameraRoll(){
        if let image = originalImage {
            ALAssetsLibrary().writeImageToSavedPhotosAlbum(image.CGImage,
                orientation: ALAssetOrientation(rawValue: image.imageOrientation.rawValue)!,
                completionBlock: {
                (url,error)-> () in
                NSLog("save to:%@", url)
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
}
func photo_list_in_workspace()->[PhotoModal]!{
    let workspace = workspace_path
    let filelist = NSFileManager.defaultManager().contentsOfDirectoryAtPath(workspace, error: nil) as [String]
    var photo_list = [PhotoModal]()
    for one_file in filelist {
        if one_file.hasSuffix(".photo") {
            let photo = PhotoModal(bundlePath: workspace + one_file,
                thumbPath: workspace + one_file + "/thumb.jpg",
                originalPath: workspace + one_file + "/original.jpg",state:.undefined)
            photo_list.append(photo)
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
    let original_filename = "\(bundle)/original.jpg"
    imageData.writeToFile(original_filename,atomically:true)
    NSLog("save original to workspace:%@", original_filename)
    
    let thumbImage = image.resizeImageWithWidth(100.0)
    let thumbData = UIImageJPEGRepresentation(thumbImage, 1.0)
    let thumb_filename = "\(bundle)/thumb.jpg"
    thumbData.writeToFile(thumb_filename, atomically: true)
    NSLog("save thumb to workspace:%@", thumb_filename)
    
    return PhotoModal(bundlePath: bundle, thumbPath: thumb_filename, originalPath: original_filename,state:.undefined)
}
