//
//  WorkPreviewCollectionLayout.swift
//  capa
//
//  Created by 秦 道平 on 14/12/14.
//  Copyright (c) 2014年 秦 道平. All rights reserved.
//

import UIKit

class WorkPreviewCollectionLayout: UICollectionViewFlowLayout {
    let margin : CGFloat = 30.0
    override func prepareLayout() {
        super.prepareLayout()
        let collection_size = self.collectionView!.frame.size
        self.itemSize = CGSize(width: collection_size.width,
            height: collection_size.height - self.sectionInset.bottom - self.sectionInset.top)
        self.minimumInteritemSpacing = 0.0
        self.minimumLineSpacing = 0.0
        self.scrollDirection = UICollectionViewScrollDirection.Horizontal
    }
    override func collectionViewContentSize() -> CGSize {
        let total = self.collectionView!.dataSource?.collectionView(self.collectionView!, numberOfItemsInSection: 0)
        return CGSize(width: (self.itemSize.width) * CGFloat(total!) ,
            height: self.itemSize.height)
    }
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return true
    }
}
