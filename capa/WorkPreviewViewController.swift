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
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        cell.collectionViewOnwer = collectionView
        let photo = self.photo_list[indexPath.row]
        cell.imageView.image = photo.originalImage!
        cell.setupConstraints() ///根据图片设置新的约束条件
        return cell
    }
    ///MARK: - UIScrollViewDelegate
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        let pageIndex = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        NSLog("pageIndex:%d", pageIndex)
        self.photoIndex = pageIndex
        self.updateToolbar()
        
        NSNotificationCenter.defaultCenter().postNotificationName(kWorkspaceScrollPhotoNotification,
            object: NSNumber(integer: self.photoIndex))
    }
    ///MARK: - Action
    @IBAction func onButtonState(sender:UIButton!){
        let photo = self.photo_list[self.photoIndex]
        if sender === self.buttonUse {
            photo.state = PhotoModalState.use
            photo.write_info()
        }
        else if sender === self.buttonRemove {
            photo.state = PhotoModalState.remove
            photo.write_info()
        }
        self.updateToolbar()
    }
    private func updateToolbar(){
        let photo = self.photo_list[self.photoIndex]
        if photo.state == PhotoModalState.use {
            self.buttonUse.selected = true
        }
        else{
            self.buttonUse.selected = false
        }
        if photo.state == PhotoModalState.remove {
            self.buttonRemove.selected = true
        }
        else{
            self.buttonRemove.selected = false
        }
    }
    @IBAction func onButtonDelete(sender:UIButton!){
        let indexPath = NSIndexPath(forItem: self.photoIndex, inSection: 0)
        self.collectionView.performBatchUpdates({ [unowned self]() -> Void in
            let photo = self.photo_list[self.photoIndex]
            photo.remove()
            self.photo_list.removeAtIndex(self.photoIndex)
            self.collectionView.deleteItemsAtIndexPaths([indexPath,])
        }, completion: { (completed) -> Void in
            
        })
    }
    ///保存到相册然后删除
    @IBAction func onButtonSave(sender:UIButton!){
        let photo = self.photo_list[self.photoIndex]
        photo.saveToCameraRoll { [unowned self]() -> () in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                let indexPath = NSIndexPath(forItem: self.photoIndex, inSection: 0)
                self.collectionView.performBatchUpdates({ [unowned self]() -> Void in
                    photo.remove()
                    self.photo_list.removeAtIndex(self.photoIndex)
                    self.collectionView.deleteItemsAtIndexPaths([indexPath,])
                    }, completion: { (completed) -> Void in
                        
                })
            })
        }
    }
    
}
