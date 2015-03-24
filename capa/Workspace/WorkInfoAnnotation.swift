//
//  WorkInfoAnnotation.swift
//  capa
//
//  Created by 秦 道平 on 15/3/24.
//  Copyright (c) 2015年 秦 道平. All rights reserved.
//

import UIKit
import MapKit

class WorkInfoAnnotation: NSObject,MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String
    var subtitle: String
    
    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
    }
}
