//
//  Workspace.swift
//  capa
//
//  Created by 秦 道平 on 14/11/13.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

import UIKit

var workspace_path : String!{
get{
    let document = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as String
    let workspace = document + "/workspace/"
    return workspace
}
}
struct PhotoModal {
    let bundlePath :String!
    let thumbPath :String!
    let originalPath :String!
    var thumgImage:UIImage? {
        return UIImage(contentsOfFile: thumbPath)
    }
    var originalImage:UIImage?{
        return UIImage(contentsOfFile: originalPath)
    }
}
func photo_list_in_workspace()->[PhotoModal]!{
    let workspace = workspace_path
    let filelist = NSFileManager.defaultManager().contentsOfDirectoryAtPath(workspace, error: nil) as [String]
    var photo_list = [PhotoModal]()
    for one_file in filelist {
        if one_file.hasSuffix(".photo") {
            let photo = PhotoModal(bundlePath: workspace + one_file,
                thumbPath: workspace + one_file + "/original.jpg",
                originalPath: workspace + one_file + "/thumb.jpg")
            photo_list.append(photo)
        }
    }
    return photo_list
}

func save_to_workspace(imageData:NSData)->PhotoModal{
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
    
    return PhotoModal(bundlePath: bundle, thumbPath: thumb_filename, originalPath: original_filename)
}
