//
//  WorkInfoViewController.swift
//  capa
//
//  Created by 秦 道平 on 15/3/24.
//  Copyright (c) 2015年 秦 道平. All rights reserved.
//

import UIKit
import ImageIO
import MapKit
class WorkInfoViewController: UITableViewController {
    var photo:PhotoModal!
    @IBOutlet weak var apatureLabel:UILabel!
    @IBOutlet weak var shuttleLabel:UILabel!
    @IBOutlet weak var isoLabel:UILabel!
    @IBOutlet weak var sizeLabel:UILabel!
    @IBOutlet weak var lenseLabel:UILabel!
    @IBOutlet weak var mapView:MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        sizeLabel.text = "\(Int(photo.originalImage!.size.width)) x \(Int(photo.originalImage!.size.height))"
        let exif_dict = photo.load_exif()
        if let exif_dict = exif_dict {
            if let apature = exif_dict["FNumber"] as? Double {
                apatureLabel.text = apature.format(".1")
            }
            if let exposure = exif_dict["ExposureTime"] as? Double {
                let shuttle = Int(1 / exposure)
                shuttleLabel.text = "1/\(shuttle)"
            }
            if let iso = exif_dict["ISOSpeedRatings"] as? [NSNumber] {
                isoLabel.text = "\(iso[0])"
            }
            if let lense = exif_dict[kCGImagePropertyExifLensModel as NSString] as? String{
                lenseLabel.text = lense
            }
        }
        let gps_dict = photo.load_gps()
        if let gps_dict = gps_dict {
            if let latitude = gps_dict["Latitude"] as? Double {
                if let longtitude = gps_dict["Longitude"] as? Double {
//                    self.mapView.centerCoordinate = CLLocationCoordinate2DMake(latitude, longtitude)
                    let url = "http://api.map.baidu.com/ag/coord/convert?from=0&to=2&x=\(longtitude)&y=\(latitude)"
                    http_get_json(NSURL(string: url)!, { (json) -> () in
                        if let dict = json as? [String:AnyObject] {
                            let encodeX = dict["x"]! as String
                            let encodeY = dict["y"]! as String
                            NSLog("\(encodeX),\(encodeY)")
                            let longtitude_b = encodeX.decodeBase64() as NSString
                            let latitude_b = encodeY.decodeBase64() as NSString
                            let center = CLLocationCoordinate2DMake(latitude_b.doubleValue, longtitude_b.doubleValue)
                            self.mapView.setRegion(MKCoordinateRegionMakeWithDistance(center, 1000, 1000), animated: false)
                            let annotation = WorkInfoAnnotation(coordinate: center,title: "拍摄地点",subtitle: "")
                            self.mapView.addAnnotation(annotation)
                        }
                    }, onError: { (error) -> () in
                        
                    })
                    
                }
            }
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewDidAppear(animated: Bool) {
        
    }

    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
