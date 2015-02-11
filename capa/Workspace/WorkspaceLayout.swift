//
//  WorkspaceLayout.swift
//  capa
//
//  Created by 秦 道平 on 14/11/13.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

import UIKit

class WorkspaceLayout: UICollectionViewFlowLayout {
    override func prepareLayout() {
        super.prepareLayout()
        self.itemSize = CGSizeMake(100 , 100.0)
        self.minimumLineSpacing = 15.0
        self.minimumInteritemSpacing = 5.0
        self.scrollDirection = UICollectionViewScrollDirection.Vertical
    }
    override func collectionViewContentSize() -> CGSize {
        let items = self.collectionView!.numberOfItemsInSection(0)
        var lines = Int(items / 3)
        if (items % 3) > 0 {
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
