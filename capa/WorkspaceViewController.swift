//
//  WorkspaceViewController.swift
//  capa
//
//  Created by 秦 道平 on 14/11/11.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

import UIKit

class WorkspaceViewController: UIViewController,UICollectionViewDataSource,UICollectionViewDelegate {

    @IBOutlet var collection:UICollectionView!
    var photo_list:[PhotoModal]?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.collection.allowsMultipleSelection = true
        photo_list = photo_list_in_workspace()
        NSLog("photo_list:%d", photo_list!.count)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func onButtonCancel(sender:UIButton!){
        self.dismissViewControllerAnimated(true, completion: { () -> Void in
            
        })
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let photo_list_value = photo_list {
            return photo_list_value.count
        }
        else{
            return 0
        }
    }
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("photo-cell", forIndexPath: indexPath) as WorkspaceCollectionViewCell
        let photo = photo_list![indexPath.row]
        cell.thumbImageView.image = photo.thumgImage
        return cell
    }
}
