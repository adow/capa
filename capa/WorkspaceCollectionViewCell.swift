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
    var photo:PhotoModal?{
        didSet{
            updateState()
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
