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
    }
    ///MARK: - Action
    @IBAction func onButtonState(sender:UIButton!){
        let photo = self.photo_list[self.photoIndex]
        if sender === self.buttonUse {
            photo.state = PhotoModalState.use
        }
        else if sender === self.buttonRemove {
            photo.state = PhotoModalState.remove
        }
    }
    private func updateToolbar(){
        let photo = self.photo_list[self.photoIndex]
        if photo.state == PhotoModalState.use {
            self.buttonUse.highlighted = true
        }
        else{
            self.buttonUse.highlighted = false
        }
        if photo.state == PhotoModalState.remove {
            self.buttonRemove.highlighted = true
        }
        else{
            self.buttonRemove.highlighted = false
        }
    }
}
