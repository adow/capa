//
//  WorkspaceViewController.swift
//  capa
//
//  Created by 秦 道平 on 14/11/11.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

import UIKit

let kWorkspaceScrollPhotoNotification = "kWorkspaceScrollPhotoNotification"
let kHIDEGUIDEWORKSPACE = "kHIDEGUIDEWORKSPACE"
class WorkspaceViewController: UIViewController,UICollectionViewDataSource,UICollectionViewDelegate,WorkspaceToolbarDelegate {
    @IBOutlet weak var collection:UICollectionView!
    @IBOutlet weak var filterSegment:UISegmentedControl!
    @IBOutlet weak var leftConstraint:NSLayoutConstraint!
    @IBOutlet weak var rightConstraint:NSLayoutConstraint!
    @IBOutlet weak var guideView:UIVisualEffectView!
    var photo_list:[PhotoModal]? = [PhotoModal]()
    var toolbar : UIView!
    var editing_photo : PhotoModal? = nil ///正在编辑的照片
    var editing_index : NSIndexPath? = nil ///正在编辑的位置
    var editing_cell_frame : CGRect? = nil ///正在编辑的cell的位置
    var hud:MBProgressHUD? = nil
    var photosSaved:Int = 0 ///保存一张就计数一张
    var photosDeletedTarget:Int = 0 ///一共要删除记账照片
    var is_vc_visible:Bool! = true ///当前这个vc是否正在显示中
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.collection.allowsMultipleSelection = true
        
        toolbar = WorkspaceToolbar.toolbar()
        (toolbar as! WorkspaceToolbar).delegate = self
        self.collection.addSubview(toolbar)
        toolbar.hidden = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: "onTapGesture:")
        guideView.addGestureRecognizer(tapGesture)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "notificationScrollPhoto:", name: kWorkspaceScrollPhotoNotification, object: nil)
       
        
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
//        self.reload_photo_list()
        toolbar.hidden = true
        guideView.hidden = NSUserDefaults.standardUserDefaults().boolForKey(kHIDEGUIDEWORKSPACE)
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.is_vc_visible = true
        self.reload_photo_list()
    }
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.is_vc_visible = false
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    ///MARK: load
    ///编辑状态
    private func reset_editing(){
        toolbar.hidden = true
        editing_photo = nil
    }
    ///重新载入照片列表
    private func reload_photo_list(){
        self.reset_editing()
        photo_list?.removeAll(keepCapacity: true)
        if self.filterSegment.selectedSegmentIndex == 0 {
            for one_photo in Workspace.photoListInWorkspace() {
                photo_list?.append(one_photo)
            }
        }
        else {
            let state = PhotoModal.State(rawValue: self.filterSegment.selectedSegmentIndex)
            if let state_value = state {
                for one_photo in Workspace.photoListInWorkspace(state: state){
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
            let previewViewController = segue.destinationViewController as! WorkPreviewViewController
            previewViewController.photo_list = self.photo_list
            previewViewController.photoIndex = self.editing_index!.row
        }
    }
    
    // MARK: - UIGesture
    func onTapGesture(gesture:UIGestureRecognizer){
        guideView.hidden = true
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: kHIDEGUIDEWORKSPACE)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    
    //MARK: - Notification
    /// 这个通知有两个地方调用
    /// 一个是在 WorkPreviewViewController 中，当滚动图片时，这里会同步正在显示(编辑) 那一张，
    /// 还有一个是 cell 中双击时，会选中当前的这张，然后转到 WorkPreviewViewController 去
    /// 最后他们都会调用 update_editing_cell_frame,
    /// 用来确定正在显示(编辑)的这个 cell 在 view 中的位置
    func notificationScrollPhoto(notification:NSNotification){
        let photo_number = notification.object as? NSNumber
        let photo_index = photo_number?.integerValue
        if let photo_index_value = photo_index {
            let index_path = NSIndexPath(forItem: photo_index_value, inSection: 0)
            /// 这个cell 是否是可见的
            var cell_visible = false
            for one_index_path in self.collection.indexPathsForVisibleItems() as! [NSIndexPath] {
                if index_path.section == one_index_path.section && index_path.row == one_index_path.row {
                    cell_visible = true
                    break
                }
            }
            if !cell_visible {
                self.collection.scrollToItemAtIndexPath(index_path,
                    atScrollPosition: UICollectionViewScrollPosition.CenteredVertically,
                    animated: false)
            }
            
            let cell = self.collectionView(self.collection, cellForItemAtIndexPath: index_path)
            self.update_editing_cell_frame(cell)
        }
    }
    ///确定这个cell在整个view中的位置
    func update_editing_cell_frame(cell:UICollectionViewCell!){
        let cell_frame = cell.frame
        var x = 16.0 + leftConstraint.constant + cell_frame.origin.x - self.collection.contentOffset.x
        var y = self.collection.frame.origin.y + cell_frame.origin.y - self.collection.contentOffset.y
        /// 很奇怪的是，当这个 WorkspaceViewController 正在显示的时候，如果 collectionView 滚动到顶部，这时的 contentOffset.y 是 -64.0, 也就是一个导航条的高度;
        /// 但是如果这个 WorkspaceViewController 没有显示的时候，比如正在有 WorkPreviewViewController 来更新这个位置的时候, contetnOffset.y 在顶部时是 0.0;
        /// 这导致的问题是，如果在 WorkPreviewViewController 来更新这个位置时，他总是少了 64.0 的。
        /// 所以这里的修正方法是，判断一下当前这个 WorkspaceViewController 是否正在显示，如果不显示了，就要把这个位置往下面移动一下.
        if !is_vc_visible {
            y += 64.0
        }
        editing_cell_frame = CGRectMake(x, y, cell_frame.size.width, cell_frame.size.height)
//        NSLog("editing_cell_frame:%@,%@", NSStringFromCGRect(editing_cell_frame!),NSStringFromCGRect(cell_frame))
    }
}
// MARK: - Actions
extension WorkspaceViewController {
    @IBAction func onButtonCancel(sender:UIBarButtonItem!){
        self.dismissViewControllerAnimated(true, completion: { () -> Void in
            
        })
    }
    ///批量操作
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
    ///把标记为使用的图片存入系统相册,会开启一个计数器线程，直到保存全部完成了，计数器会开始删除所有标记为使用的图片
    @IBAction func savePhotosToCameraRollMarkUse(sender:UIBarButtonItem!){
        self.hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        self.photosSaved = 0
        if let photo_list_value = photo_list {
            ///第一次循环，用来计算一共要删除几张
            for one_photo in photo_list_value {
                if one_photo.state == PhotoModal.State.use {
                    self.photosDeletedTarget += 1
                }
            }
            ///开始一个计数器，检查是否保存完了
            NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "_savePhotoTimer:", userInfo: nil, repeats: true)
            ///对每张照片进行删除
            photo_loop:for one_photo in photo_list_value {
                if one_photo.state == PhotoModal.State.use {
                    one_photo.saveToCameraRoll(callback: { [unowned self]() -> () in
                        self.photosSaved += 1 ///计数要删除的图片数，当 photosSaved == photosDeletedTarget 就开始真正的批量删除
                    })
                }
            }
            
        }
        
    }
    ///把标记为删除的图片删除
    @IBAction func removePhotosMarkRemove(sender:UIBarButtonItem!){
        let alert = UIAlertController(title: "删除?", message: "删除照片", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
            
        }))
        alert.addAction(UIAlertAction(title: "删除", style: UIAlertActionStyle.Default, handler: { [unowned self](action) -> Void in
            var delete_photo_list = [PhotoModal]()
            if let photo_list_value = self.photo_list {
                for one_photo in photo_list_value {
                    if one_photo.state == .remove {
                        delete_photo_list.append(one_photo)
                    }
                }
            }
            self.removePhotos(delete_photo_list)
        }))
        self.presentViewController(alert, animated: true) { () -> Void in
            
        }
        
        
    }
    ///筛选图片
    @IBAction func onFilterSegment(sender:UISegmentedControl!){
        self.reload_photo_list()
        toolbar.hidden = true
    }
    ///计算已经是否已经删除完了
    @objc private func _savePhotoTimer(timer:NSTimer){
        NSLog("photosDeleted:%d", self.photosSaved)
        if self.photosSaved >= self.photosDeletedTarget {
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
            self.hud?.hide(true)
            self.removePhotos(delete_photo_list)
        }
    }
    ///批量删除照片
    func removePhotos(photos:[PhotoModal]){
        if var photo_list_value = self.photo_list {
            self.hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
            self.collection.performBatchUpdates({ [unowned self]() -> Void in
                ///先要获取要删除的照片的位置
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
                        self.photo_list?.removeAtIndex(index_value)///从照片列表中删除
                    }
                    one_photo.remove()///删除文件
                }
                self.collection.deleteItemsAtIndexPaths(delete_index_path)
                }, completion: { [unowned self](completed) -> Void in
                    if let hud_value = self.hud {
                        hud_value.hide(true)
                    }
                    self.reset_editing()
                    self.collection.reloadData()
            })
            
        }
        
        
    }
}
// MARK: - UICollectionView
extension WorkspaceViewController:UICollectionViewDelegate,UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let photo_list_value = photo_list {
            return photo_list_value.count
        }
        else{
            return 0
        }
    }
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("photo-cell", forIndexPath: indexPath) as! WorkspaceCollectionViewCell
        cell.setupGesture()
        cell.viewController = self
        cell.indexPath = indexPath
        let photo = photo_list![indexPath.row]
        cell.photo = photo
        if let thumbImage = photo.thumgImage {
            cell.thumbImageView.image = thumbImage
        }
        return cell
    }
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if self.editing_index == indexPath && indexPath.row > 0 {
            return
        }
        self.editing_index = indexPath
        editing_photo?.editing = false ///把原来的状态修改
        let cell = self.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! WorkspaceCollectionViewCell
        editing_photo = cell.photo
        editing_photo?.editing = true
        var x = cell.frame.origin.x - (toolbar.frame.size.width - cell.frame.size.width) / 2
        var y = cell.frame.origin.y + cell.frame.size.height + 3.0
        x = fmax(x, 0)
        x = fmin(x, collectionView.frame.size.width - toolbar.frame.size.width)
        let toolbar_m = toolbar as! WorkspaceToolbar
        toolbar_m.photo = cell.photo
        toolbar.hidden = false
        let target_frame = CGRectMake(x, y, toolbar.frame.size.width, toolbar.frame.size.height)
        let start_frame = CGRectOffset(target_frame, 0.0, -10.0)
        toolbar.frame = start_frame
        toolbar.alpha = 0.0
        UIView.animateWithDuration(0.3, animations:{ [unowned self]() -> Void in
            self.toolbar.frame = target_frame
            self.toolbar.alpha = 1.0
            }) { [unowned self](completed) -> Void in
        }
        update_editing_cell_frame(cell)
    }
}
extension WorkspaceViewController:WorkspaceToolbarDelegate {
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
            photo!.state = PhotoModal.State.use
            photo!.write_info()
            self.collection.reloadData()
        }
        else if itemButton.tag == 3 {
            photo!.state = PhotoModal.State.remove
            photo!.write_info()
            self.collection.reloadData()
        }
        else if itemButton.tag == 4 {
            let alert = UIAlertController(title: "删除?", message: "删除照片", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
                
            }))
            alert.addAction(UIAlertAction(title: "删除", style: UIAlertActionStyle.Default, handler: { [unowned self](action) -> Void in
                if let photo_value = photo {
                    self.removePhotos([photo_value,])
                }
            }))
            self.presentViewController(alert, animated: true) { () -> Void in
                
            }
            
        }
    }
}