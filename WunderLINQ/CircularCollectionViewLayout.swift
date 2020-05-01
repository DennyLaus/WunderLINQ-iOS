/*
WunderLINQ Client Application
Copyright (C) 2020  Keith Conger, Black Box Embedded, LLC

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

import UIKit

class CircularCollectionViewLayoutAttributes: UICollectionViewLayoutAttributes {
    
    var anchorPoint = CGPoint(x: 0.5, y: 0.5)
    var angle: CGFloat = 0 {
      didSet {
        zIndex = Int(angle * 1000000)
          transform = CGAffineTransform(rotationAngle: angle)
      }
    }
    
    override func copy(with zone: NSZone?) -> Any {
        let copy = super.copy(with: zone) as! CircularCollectionViewLayoutAttributes
        copy.anchorPoint = self.anchorPoint
        copy.angle = self.angle
        return copy
    }
}

class CircularCollectionViewLayout: UICollectionViewLayout {
    
    let itemSize = CGSize(width: 120, height: 120)

    var angleAtExtreme: CGFloat {
        return collectionView!.numberOfItems(inSection: 0) > 0 ?
            -CGFloat(collectionView!.numberOfItems(inSection: 0) - 1) * anglePerItem : 0
    }
    
    var angle: CGFloat {
        return angleAtExtreme * collectionView!.contentOffset.x / (collectionViewContentSize.width - collectionView!.bounds.width)
    }

    var radius: CGFloat = 500 {
      didSet {
        invalidateLayout()
      }
    }
    
    var anglePerItem: CGFloat {
      return atan((itemSize.width + 25) / radius)
    }
    
    var attributesList = [CircularCollectionViewLayoutAttributes]()
    
    override var collectionViewContentSize: CGSize {
        return CGSize(width: CGFloat(collectionView!.numberOfItems(inSection: 0)) * itemSize.width,
                      height: collectionView!.bounds.height)
    }
    
    override public class var layoutAttributesClass: AnyClass {
      return CircularCollectionViewLayoutAttributes.self
    }
    
    override func prepare() {
        super.prepare()

        let centerX = collectionView!.contentOffset.x + (collectionView!.bounds.width / 2.0)

        let anchorPointY = ((itemSize.height / 2.0) + radius) / itemSize.height
        
        let theta = atan2(collectionView!.bounds.width / 2.0, radius + (itemSize.height / 2.0) - (collectionView!.bounds.height / 2.0))
        
        var startIndex = 0
        var endIndex = collectionView!.numberOfItems(inSection: 0) - 1
        
        if (angle < -theta) {
          startIndex = Int(floor((-theta - angle) / anglePerItem))
        }
        
        endIndex = min(endIndex, Int(ceil((theta - angle) / anglePerItem)))
        
        if (endIndex < startIndex) {
          endIndex = 0
          startIndex = 0
        }
        attributesList = (0..<collectionView!.numberOfItems(inSection: 0)).map { (i)
          -> CircularCollectionViewLayoutAttributes in
            
            let attributes = CircularCollectionViewLayoutAttributes(forCellWith: NSIndexPath(item: i, section: 0) as IndexPath)
            attributes.size = self.itemSize
            
            // Adjusts where top icon is centered
            attributes.center = CGPoint(x: centerX, y: 70)
            
            attributes.angle = self.angle + (self.anglePerItem * CGFloat(i))
            attributes.anchorPoint = CGPoint(x: 0.5, y: anchorPointY)
            
            return attributes
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
      return attributesList
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
      return attributesList[indexPath.row]
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
      return true
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        var finalContentOffset = proposedContentOffset
        
        let factor = -angleAtExtreme/(collectionViewContentSize.width - collectionView!.bounds.width)

        let proposedAngle = proposedContentOffset.x*factor
        let ratio = proposedAngle/anglePerItem
        var multiplier: CGFloat
        if (velocity.x > 0) {
          multiplier = ceil(ratio)
        } else if (velocity.x < 0) {
          multiplier = floor(ratio)
        } else {
          multiplier = round(ratio)
        }
        finalContentOffset.x = multiplier*anglePerItem/factor
        return finalContentOffset
    }
}
