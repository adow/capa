//
//  WorkspaceCollectionViewCell.swift
//  capa
//
//  Created by 秦 道平 on 14/11/13.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

import UIKit

class WorkspaceCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var thumbImageView:UIImageView!
    @IBOutlet weak var useMarkButton:UIButton!
    @IBOutlet weak var removeMarkButton:UIButton!
    @IBOutlet weak var markImageView:UIImageView!
    var indexPath:NSIndexPath!
    weak var viewController:WorkspaceViewController!
    var tapGesture:UITapGestureRecognizer?
    var photo:PhotoModal?{
        didSet{
            //updateState()
            if let photo_value = photo {
                switch photo_value.state {
                case .undefined:
                    markImageView.image = nil
                case .use:
                    markImageView.image = UIImage(named: "mark-use-highlight")
                case .remove:
                    markImageView.image = UIImage(named: "mark-remove-hightlight")
                }
            }
            else{
                markImageView.image = nil
            }
            
        }
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        
    }
    func setupGesture(){
        if tapGesture == nil {
            tapGesture = UITapGestureRecognizer(target: self, action: "onTapGesture:")
            tapGesture?.numberOfTapsRequired = 2
            tapGesture?.cancelsTouchesInView = true
            tapGesture?.delaysTouchesBegan = true
            self.addGestureRecognizer(tapGesture!)
        }
    }
    private func updateState()->(){
        if let photo = photo {
            switch photo.state{
            case PhotoModal.State.undefined:
                useMarkButton.selected = false
                removeMarkButton.selected = false
            case PhotoModal.State.use:
                useMarkButton.selected = true
                removeMarkButton.selected = false
            case PhotoModal.State.remove:
                useMarkButton.selected = false
                removeMarkButton.selected = true
            }
        }
            
        else{
            useMarkButton.selected = false
            removeMarkButton.selected = false
        }
    }
    @IBAction func onButton(sender:UIButton!){
        if sender === useMarkButton {
            if sender.selected {
                photo?.state = PhotoModal.State.undefined
            }
            else{
                photo?.state = PhotoModal.State.use
            }
            
        }
        else if sender === removeMarkButton {
            if sender.selected {
                photo?.state = PhotoModal.State.undefined
            }
            else{
                photo?.state = PhotoModal.State.remove
            }
        }
        self.updateState()
        
    }
    ///双击 Tap 的时候，进入 Preview
    @IBAction func onTapGesture(gesture:UITapGestureRecognizer){
        self.viewController.editing_photo = self.photo
        self.viewController.editing_index = self.indexPath
        NSNotificationCenter.defaultCenter().postNotificationName(kWorkspaceScrollPhotoNotification,
            object: NSNumber(integer: self.indexPath.row))
        self.viewController.performSegueWithIdentifier("segue_workspace_preview", sender: nil)
    }
}
