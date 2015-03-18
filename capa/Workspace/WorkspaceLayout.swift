//
//  WorkspaceLayout.swift
//  capa
//
//  Created by 秦 道平 on 14/11/13.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

import UIKit

let item_space : CGFloat = 1.0
let items_in_line = 4
/// 屏幕大小
var screen_width : CGFloat {
    return UIScreen.mainScreen().bounds.size.width
}
/// 单元大小
var item_width : CGFloat{
    let width = (screen_width - CGFloat(items_in_line - 1) * item_space) / CGFloat(items_in_line)
    return CGFloat(Int(width))
}

class WorkspaceLayout: UICollectionViewFlowLayout {
    override func prepareLayout() {
        super.prepareLayout()
        self.itemSize = CGSizeMake(item_width , item_width)
        self.minimumLineSpacing = item_space
        self.minimumInteritemSpacing = item_space
        self.scrollDirection = UICollectionViewScrollDirection.Vertical
    }
    override func collectionViewContentSize() -> CGSize {
        let items = self.collectionView!.numberOfItemsInSection(0)
        var lines = Int(items / items_in_line)
        if (items % items_in_line) > 0 {
            lines += 1
        }
        let top_margin : CGFloat = 44.0
        let line_height = itemSize.height + minimumLineSpacing
        let height = top_margin + CGFloat(lines) * line_height
        return CGSizeMake(self.collectionView!.frame.size.width, height)
    }
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return true
    }
}
