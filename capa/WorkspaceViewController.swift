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
    var toolbar : UIView!
    var markerView :UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
//        self.collection.allowsMultipleSelection = true
        self.reload_photo_list()
        
        toolbar = WorkspaceToolbar.toolbar()
        self.collection.addSubview(toolbar)
        toolbar.hidden = true
  
        markerView = WorkspaceMarkerView.markerView()
        self.collection.addSubview(markerView)
        markerView.hidden = true

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func reload_photo_list(){
        photo_list = photo_list_in_workspace()
        NSLog("photo_list:%d", photo_list!.count)
        self.collection.reloadData()
    }
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "segue_workspace_preview" {
            let cell = sender as WorkspaceCollectionViewCell
            let photo = cell.photo
            let previewViewController = segue.destinationViewController as WorkPreviewViewController
            previewViewController.photo = photo
        }
    }
    // MARK: - Actions
    @IBAction func onButtonCancel(sender:UIBarButtonItem!){
        self.dismissViewControllerAnimated(true, completion: { () -> Void in
            
        })
    }
    @IBAction func onButtonAction(sender:UIBarButtonItem!){
        let alertController = UIAlertController(title: "操作", message: "批量操作照片", preferredStyle: UIAlertControllerStyle.ActionSheet)
        alertController.addAction(UIAlertAction(title: "将所有标记为 留用 的照片存入相机交卷", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            
        }))
        alertController.addAction(UIAlertAction(title: "将所有标记为 弃用 的照片删除", style: UIAlertActionStyle.Destructive, handler: { (action) -> Void in
            
        }))
        alertController.addAction(UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
            
        }))
        self.presentViewController(alertController, animated: true) { () -> Void in
            
        }
    }
    @IBAction func savePhotosToCameraRollMarkUse(sender:UIBarButtonItem!){
        if let photo_list_value = photo_list {
            for one_photo in photo_list_value {
                if one_photo.state == PhotoModalState.use {
                    one_photo.saveToCameraRoll()
                }
            }
        }
    }
    @IBAction func removePhotosMarkRemove(sender:UIBarButtonItem!){
        if let photo_list_value = photo_list {
            for one_photo in photo_list_value {
                if one_photo.state == PhotoModalState.remove {
                    one_photo.remove()
                }
            }
            self.reload_photo_list()
        }
    }
    // MARK: - UICollectionView
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
        cell.photo = photo
//        println("image orientation:\(photo.originalImage?.imageOrientation),\(indexPath.row)")
        println("\(indexPath.row):\(photo.state)")
        return cell
    }
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = self.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as WorkspaceCollectionViewCell
//        NSLog("cell frame:%@", NSStringFromCGRect(cell.frame))
        var x = cell.frame.origin.x - (toolbar.frame.size.width - cell.frame.size.width) / 2
        var y = cell.frame.origin.y + cell.frame.size.height
        toolbar.frame = CGRectMake(x, y, toolbar.frame.size.width, toolbar.frame.size.height)
        toolbar.hidden = false
        let toolbar_m = toolbar as WorkspaceToolbar
        toolbar_m.photo = cell.photo

        var marker_x = cell.frame.origin.x - 10.0
        var marker_y = cell.frame.origin.y - 10.0
        markerView.frame = CGRectMake(marker_x, marker_y,
            markerView.frame.size.width, markerView.frame.size.height)
        markerView.hidden = false
        let markerView_m = markerView as WorkspaceMarkerView
        markerView_m.photo = cell.photo
    }
}
