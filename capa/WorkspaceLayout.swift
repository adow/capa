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
        self.itemSize = CGSizeMake(100 , 150.0)
        self.minimumLineSpacing = 5.0
        self.minimumInteritemSpacing = 5.0
        self.scrollDirection = UICollectionViewScrollDirection.Vertical
    }
    override func collectionViewContentSize() -> CGSize {
        let items = self.collectionView!.numberOfItemsInSection(0)
        let height = CGFloat(items * 100)
        return CGSizeMake(self.collectionView!.frame.size.width, height)
    }
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return true
    }
}
