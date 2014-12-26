//
//  WorkspaceViewController.swift
//  capa
//
//  Created by 秦 道平 on 14/11/11.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

import UIKit

class WorkspaceViewController: UIViewController,UICollectionViewDataSource,UICollectionViewDelegate,WorkspaceMarkerViewDelegate,WorkspaceToolbarDelegate {
    @IBOutlet weak var collection:UICollectionView!
    @IBOutlet weak var filterSegment:UISegmentedControl!
    var photo_list:[PhotoModal]? = [PhotoModal]()
    var toolbar : UIView!
    var markerView :UIView!
    var editing_photo : PhotoModal? = nil ///正在编辑的照片
    var editing_index : NSIndexPath? = nil ///正在编辑的位置
    var hud:MBProgressHUD? = nil
    var photosDeleted:Int = 0 ///已经删除多少张照片
    var photosDeletedTarget:Int = 0 ///一共要删除记账照片
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
//        self.collection.allowsMultipleSelection = true
        
        
        toolbar = WorkspaceToolbar.toolbar()
        (toolbar as WorkspaceToolbar).delegate = self
        self.collection.addSubview(toolbar)
        toolbar.hidden = true
  
        markerView = WorkspaceMarkerView.markerView()
        (markerView as WorkspaceMarkerView).delegate = self
        self.collection.addSubview(markerView)
        markerView.hidden = true
        
        

    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
//        self.reload_photo_list()
        toolbar.hidden = true
        markerView.hidden = true
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.reload_photo_list()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func reset_editing(){
        toolbar.hidden = true
        markerView.hidden = true
        editing_photo = nil
    }
    private func reload_photo_list(){
        self.reset_editing()
        photo_list?.removeAll(keepCapacity: true)
        if self.filterSegment.selectedSegmentIndex == 0 {
//            photo_list = photo_list_in_workspace()
            for one_photo in photo_list_in_workspace() {
                photo_list?.append(one_photo)
            }
        }
        else {
            let state = PhotoModalState(rawValue: self.filterSegment.selectedSegmentIndex)
            if let state_value = state {
//                photo_list = photo_list_in_workspace(state: state)
                for one_photo in photo_list_in_workspace(state: state){
                    photo_list?.append(one_photo)
                }
            }
        }
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
//            let photo = self.editing_photo!
            let previewViewController = segue.destinationViewController as WorkPreviewViewController
            previewViewController.photo_list = self.photo_list
            previewViewController.photoIndex = self.editing_index!.row
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
            self.savePhotosToCameraRollMarkUse(nil)
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
        self.photosDeleted = 0
        if let photo_list_value = photo_list {
            ///第一次循环，用来计算一共要删除几张
            for one_photo in photo_list_value {
                if one_photo.state == PhotoModalState.use {
                    self.photosDeletedTarget += 1
                }
            }
            NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "_savePhotoTimer:", userInfo: nil, repeats: true)
            ///对每张照片进行删除
            var save_photo_list = [PhotoModal]()
            photo_loop:for one_photo in photo_list_value {
                if one_photo.state == PhotoModalState.use {
                    save_photo_list.append(one_photo)
                    one_photo.saveToCameraRoll(callback: { [unowned self]() -> () in
                        self.photosDeleted += 1 ///删除完后就计数器+1
                    })
                }
            }
            
        }
        
    }
    @IBAction func removePhotosMarkRemove(sender:UIBarButtonItem!){
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
    @IBAction func onFilterSegment(sender:UISegmentedControl!){
        self.reload_photo_list()
        toolbar.hidden = true
        markerView.hidden = true
    }
    ///计算已经是否已经删除完了
    @objc private func _savePhotoTimer(timer:NSTimer){
        NSLog("photosDeleted:%d", self.photosDeleted)
        if self.photosDeleted >= self.photosDeletedTarget {
            timer.invalidate()
            NSLog("stop timer")
            var delete_photo_list = [PhotoModal]()
            if let photo_list_value = photo_list {
                for one_photo in photo_list_value {
                    if one_photo.state == .use {
                        delete_photo_list.append(one_photo)
                    }
                }
            }
            self.removePhotos(delete_photo_list)
        }
    }
    ///批量删除照片
    func removePhotos(photos:[PhotoModal]){
        if var photo_list_value = photo_list {
            hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
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
                    one_photo.remove()
                }
                self.collection.deleteItemsAtIndexPaths(delete_index_path)
            }, completion: { [unowned self](completed) -> Void in
//                self.hud?.hide(true, afterDelay: 1.0)
                if let hud_value = self.hud {
                    hud_value.hide(true)
                }
                self.reset_editing()
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
        cell.viewController = self
        cell.indexPath = indexPath
        let photo = photo_list![indexPath.row]
        cell.thumbImageView.image = photo.thumgImage!
        cell.photo = photo
//        println("image orientation:\(photo.originalImage?.imageOrientation),\(indexPath.row)")
//        println("\(indexPath.row):\(photo.state)")
        return cell
    }
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
//        NSLog("cell frame:%@", NSStringFromCGRect(cell.frame))
        self.editing_index = indexPath
        editing_photo?.editing = false ///把原来的状态修改
        let cell = self.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as WorkspaceCollectionViewCell
        editing_photo = cell.photo
        editing_photo?.editing = true
        var x = cell.frame.origin.x - (toolbar.frame.size.width - cell.frame.size.width) / 2
        var y = cell.frame.origin.y + cell.frame.size.height + 3.0
        x = fmax(x, 0)
        x = fmin(x, collectionView.frame.size.width - toolbar.frame.size.width)
        toolbar.frame = CGRectMake(x, y, toolbar.frame.size.width, toolbar.frame.size.height)
        toolbar.hidden = false
        let toolbar_m = toolbar as WorkspaceToolbar
        toolbar_m.photo = cell.photo
        collectionView.reloadData()
    }
    /// MARK: - WorkspaceMarkerViewDelegate
    func onMarkUseButton(photo: PhotoModal?) {
        NSLog("mark useful")
        photo?.state = .use
        photo?.write_info()
        self.collection.reloadData()
    }
    func onMarkNouseButton(photo: PhotoModal?) {
        NSLog("mark no use")
        photo?.state = .remove
        photo?.write_info()
        self.collection.reloadData()
    }
    /// MARK: - WorkspaceToolbarDelegate
    func onToolbarItem(photo: PhotoModal?, itemButton: UIButton) {
        NSLog("on toolbar:%d",itemButton.tag)
        if itemButton.tag == 0 {
            if let photo_value = photo {
                hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
                photo_value.saveToCameraRoll(callback: { [unowned self]() -> () in
                    self.removePhotos([photo_value,])
                })
                hud?.hide(true,afterDelay:1.0)
            }
        }
        else if itemButton.tag == 1 {
            self.performSegueWithIdentifier("segue_workspace_preview", sender: nil)
        }
        else if itemButton.tag == 2 {
            photo!.state = PhotoModalState.use
            photo!.write_info()
            self.collection.reloadData()
        }
        else if itemButton.tag == 3 {
            photo!.state = PhotoModalState.remove
            photo!.write_info()
            self.collection.reloadData()
        }
        else if itemButton.tag == 4 {
            if let photo_value = photo {
                self.removePhotos([photo_value,])
            }
        }
    }
}
