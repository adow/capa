//
//  WorkPreviewViewController.swift
//  capa
//
//  Created by 秦 道平 on 14/11/15.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

import UIKit

class WorkPreviewViewController: UIViewController,UICollectionViewDataSource,UICollectionViewDelegate,UIScrollViewDelegate {
    var photo_list:[PhotoModal]!
    var photoIndex:Int!
    @IBOutlet weak var collectionView:UICollectionView!
    @IBOutlet weak var buttonUse:UIButton!
    @IBOutlet weak var buttonRemove:UIButton!
    var editing_photo:PhotoModal? {
        if photoIndex < photo_list.count {
            return photo_list[photoIndex]
        }
        else{
            return nil
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.collectionView.hidden = true
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.collectionView.scrollToItemAtIndexPath(NSIndexPath(forItem: self.photoIndex, inSection: 0), atScrollPosition: UICollectionViewScrollPosition.CenteredHorizontally, animated: false) ///只有在viewDidAppear 中调用滚动才用
        self.collectionView.hidden = false
        self.updateToolbar()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let workInfoViewController = segue.destinationViewController as WorkInfoViewController
        workInfoViewController.photo = editing_photo!
    }
    ///MARK: - UICollectionView
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.photo_list!.count
    }
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("photo-cell", forIndexPath: indexPath) as WorkPreviewCollectionViewCell
        cell.layoutIfNeeded() ///要先调用一次layoutIfNeeded()，否则开始的几个cell的宽度还没有改变
        cell.collectionViewOnwer = collectionView ///cell 中需要访问 collectionView
        let photo = self.photo_list[indexPath.row]
        cell.imageView.image = photo.originalImage!
//        cell.imageView.image = UIImage(contentsOfFile: photo.originalPath)
        cell.setupConstraints() ///根据图片设置新的约束条件
        return cell
    }
    ///MARK: - UIScrollViewDelegate
    ///滚动完后，要知道当前的照片的位置，然后更新工具条的未知,还要更新 WorkspaceViewController 中选中的 cell
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        let pageIndex = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        NSLog("pageIndex:%d", pageIndex)
        self.photoIndex = pageIndex
        self.updateToolbar()
        NSNotificationCenter.defaultCenter().postNotificationName(kWorkspaceScrollPhotoNotification,
            object: NSNumber(integer: self.photoIndex))///通知 WorkspaceViewController 更新选中的 cell,因为从 preview 返回的时候要动画回到这个 cell
    }
    ///MARK: - Action
    @IBAction func onButtonState(sender:UIButton!){
        let photo = self.photo_list[self.photoIndex]
        if sender === self.buttonUse {
            photo.state = PhotoModal.State.use
            photo.write_info()
        }
        else if sender === self.buttonRemove {
            photo.state = PhotoModal.State.remove
            photo.write_info()
        }
        self.updateToolbar()
    }
    ///根据当前的图片来更新工具条的状态
    private func updateToolbar(){
        if self.photoIndex >= self.photo_list.count {
            NSLog("empty photo list")
            return
        }
        let photo = self.photo_list[self.photoIndex]
        if photo.state == PhotoModal.State.use {
            self.buttonUse.selected = true
        }
        else{
            self.buttonUse.selected = false
        }
        if photo.state == PhotoModal.State.remove {
            self.buttonRemove.selected = true
        }
        else{
            self.buttonRemove.selected = false
        }
    }
    @IBAction func onButtonDelete(sender:UIButton!){
        let alert = UIAlertController(title: "删除?", message: "删除照片", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
            
        }))
        alert.addAction(UIAlertAction(title: "删除", style: UIAlertActionStyle.Default, handler: { [unowned self](action) -> Void in
            let hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
            let indexPath = NSIndexPath(forItem: self.photoIndex, inSection: 0)
            var target_photoIndex = self.photoIndex
            self.collectionView.performBatchUpdates({() -> Void in
                let photo = self.photo_list[self.photoIndex]
                photo.remove() ///先删除文件
                self.photo_list.removeAtIndex(self.photoIndex) ///从当前的列表删除
                self.collectionView.deleteItemsAtIndexPaths([indexPath,]) ///实现删除动画
                ///要计算下一个显示的照片,因为他会自动把后面的一张照片移过来显示
                target_photoIndex = min(target_photoIndex!,self.photo_list.count - 1)
                target_photoIndex = max(target_photoIndex!,0)
                }, completion: { (completed) -> Void in
                    hud.hide(true, afterDelay: 1.0)
                    self.photoIndex = target_photoIndex ///更新当前正在编辑的图片
                    self.updateToolbar() ///更新这个图片对应的工具条状态
                    NSNotificationCenter.defaultCenter().postNotificationName(kWorkspaceScrollPhotoNotification,
                        object: NSNumber(integer: self.photoIndex)) ///要让 WorkspaceViewController 也更新选中正在编辑的 cell
            })
        }))
        self.presentViewController(alert, animated: true) { () -> Void in
            
        }
    }
    ///保存到相册然后删除
    @IBAction func onButtonSave(sender:UIButton!){
        let hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        let photo = self.photo_list[self.photoIndex]
        var target_photoIndex = self.photoIndex
        photo.saveToCameraRoll { [unowned self]() -> () in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                let indexPath = NSIndexPath(forItem: self.photoIndex, inSection: 0)
                self.collectionView.performBatchUpdates({() -> Void in
                    ///和删除时的流程一样
                    photo.remove()
                    self.photo_list.removeAtIndex(self.photoIndex)
                    self.collectionView.deleteItemsAtIndexPaths([indexPath,])
                    target_photoIndex = min(target_photoIndex!,self.photo_list.count - 1)
                    target_photoIndex = max(target_photoIndex!,0)
                    }, completion: { (completed) -> Void in
                        hud.hide(true, afterDelay: 1.0)
                        self.updateToolbar()
                        NSNotificationCenter.defaultCenter().postNotificationName(kWorkspaceScrollPhotoNotification,
                            object: NSNumber(integer: self.photoIndex))
                })
            })
        }
    }
    
}
