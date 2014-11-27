//
//  WorkspaceCollectionViewCell.swift
//  capa
//
//  Created by 秦 道平 on 14/11/13.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

import UIKit

class WorkspaceCollectionViewCell: UICollectionViewCell {
    @IBOutlet var thumbImageView:UIImageView!
    @IBOutlet var useMarkButton:UIButton!
    @IBOutlet var removeMarkButton:UIButton!
    @IBOutlet var markImageView:UIImageView!
    var photo:PhotoModal?{
        didSet{
            //updateState()
            if let photo_value = photo {
                switch photo_value.state {
                case .undefined:
                    markImageView.image = nil
                case .use:
                    markImageView.image = UIImage(named: "mark-use")
                case .remove:
                    markImageView.image = UIImage(named: "mark-nouse2")
                }
                if photo_value.editing {
                    self.markImageView.hidden = true
                }
                else{
                    self.markImageView.hidden = false
                }
            }
            else{
                markImageView.image = nil
            }
            
        }
    }
    private func updateState()->(){
        if let photo_value = photo {
            switch photo_value.state{
            case PhotoModalState.undefined:
                useMarkButton.selected = false
                removeMarkButton.selected = false
            case PhotoModalState.use:
                useMarkButton.selected = true
                removeMarkButton.selected = false
            case PhotoModalState.remove:
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
                photo?.state = PhotoModalState.undefined
            }
            else{
                photo?.state = PhotoModalState.use
            }
            
        }
        else if sender === removeMarkButton {
            if sender.selected {
                photo?.state = PhotoModalState.undefined
            }
            else{
                photo?.state = PhotoModalState.remove
            }
        }
        self.updateState()
        
    }
}
