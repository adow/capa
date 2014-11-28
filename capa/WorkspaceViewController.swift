//
//  WorkspaceViewController.swift
//  capa
//
//  Created by 秦 道平 on 14/11/11.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

import UIKit

class WorkspaceViewController: UIViewController,UICollectionViewDataSource,UICollectionViewDelegate,WorkspaceMarkerViewDelegate,WorkspaceToolbarDelegate {
    @IBOutlet var collection:UICollectionView!
    var photo_list:[PhotoModal]?
    var toolbar : UIView!
    var markerView :UIView!
    var editing_photo : PhotoModal? = nil ///正在编辑的照片
    var hud:MBProgressHUD? = nil
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
//        self.collection.allowsMultipleSelection = true
        self.reload_photo_list()
        
        toolbar = WorkspaceToolbar.toolbar()
        (toolbar as WorkspaceToolbar).delegate = self
        self.collection.addSubview(toolbar)
        toolbar.hidden = true
  
        markerView = WorkspaceMarkerView.markerView()
        (markerView as WorkspaceMarkerView).delegate = self
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
//            let cell = sender as WorkspaceCollectionViewCell
//            let photo = cell.photo
            let photo = self.editing_photo!
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
            self.removePhotosMarkRemove(nil)
        }))
        alertController.addAction(UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
            
        }))
        self.presentViewController(alertController, animated: true) { () -> Void in
            
        }
    }
    @IBAction func savePhotosToCameraRollMarkUse(sender:UIBarButtonItem!){
        hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        if let photo_list_value = photo_list {
            var delete_photo_list = [PhotoModal]()
            for one_photo in photo_list_value {
                if one_photo.state == PhotoModalState.use {
                    one_photo.saveToCameraRoll() ///保存到相册
                    delete_photo_list.append(one_photo) ///标记为删除
                }
            }
            self.removePhotos(delete_photo_list)///删除这些照片
        }
        
    }
    @IBAction func removePhotosMarkRemove(sender:UIBarButtonItem!){
        hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        var delete_photo_list = [PhotoModal]()
        if let photo_list_value = photo_list {
            for one_photo in photo_list_value {
                if one_photo.state == .remove {
                    delete_photo_list.append(one_photo)
                }
            }
        }
        self.removePhotos(delete_photo_list)
    }
    ///批量删除照片
    private func removePhotos(photos:[PhotoModal]){
        if var photo_list_value = photo_list {
            self.collection.performBatchUpdates({ [unowned self]() -> Void in
                var delete_index_path = [NSIndexPath]()
                for one_photo in photos {
                    let index = find(self.photo_list!,one_photo)
                    if let index_value = index{
                        let indexPath = NSIndexPath(forRow: index_value, inSection: 0)
                        delete_index_path.append(indexPath)
                    }
                }
                for one_photo in photos {
                    let index = find(self.photo_list!,one_photo)
                    if let index_value = index {
                        NSLog("remove photo index:%d", index_value)
                        self.photo_list?.removeAtIndex(index_value)
                    }
                    //TODO: one_photo.remove()
                }
                self.collection.deleteItemsAtIndexPaths(delete_index_path)
            }, completion: { [unowned self](completed) -> Void in
//                self.hud?.hide?(true, afterDelay: 1.0)
                if let hud_value = self.hud {
                    hud_value.hide(true,afterDelay:1.0)
                }
            })
            
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
//        println("\(indexPath.row):\(photo.state)")
        return cell
    }
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
//        NSLog("cell frame:%@", NSStringFromCGRect(cell.frame))
        editing_photo?.editing = false ///把原来的状态修改
        let cell = self.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as WorkspaceCollectionViewCell
        editing_photo = cell.photo
        editing_photo?.editing = true
        var x = cell.frame.origin.x - (toolbar.frame.size.width - cell.frame.size.width) / 2
        var y = cell.frame.origin.y + cell.frame.size.height
        x = fmax(x, 0)
        x = fmin(x, collectionView.frame.size.width - toolbar.frame.size.width)
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
        collectionView.reloadData()
    }
    /// MARK: - WorkspaceMarkerViewDelegate
    func onMarkUseButton(photo: PhotoModal?) {
        NSLog("mark useful")
        photo?.state = .use
        self.collection.reloadData()
    }
    func onMarkNouseButton(photo: PhotoModal?) {
        NSLog("mark no use")
        photo?.state = .remove
        self.collection.reloadData()
    }
    /// MARK: - WorkspaceToolbarDelegate
    func onToolbarItem(photo: PhotoModal?, itemButton: UIButton) {
        NSLog("on toolbar:%d",itemButton.tag)
        if itemButton.tag == 1 {
            self.performSegueWithIdentifier("segue_workspace_preview", sender: nil)
        }
    }
}
