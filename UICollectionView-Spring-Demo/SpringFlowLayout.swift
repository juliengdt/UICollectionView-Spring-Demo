//
//  SpringFlowLayout.swift
//  UICollectionView-Spring-Demo
//
//  Created by nathan on 15/9/6.
//  Copyright © 2015年 Teehan+Lax. All rights reserved.
//

import UIKit

class SpringFlowLayout: UICollectionViewFlowLayout {
    
    
    var scrollResistanceFactor :CGFloat = 0.0;
    var dynamicAnimator = UIDynamicAnimator()
    var visibleIndexPathsSet = NSMutableSet()
    var visibleHeaderAndFootSet = NSMutableSet()
    var latestDelta : CGFloat = 0.0;
    var interfaceOrientation = UIInterfaceOrientation(rawValue: 0)
    
    let kScrollResistanceFactorDefault = 900.0
    
    override init() {
        super.init()
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init()
        setup()
    }
    
    
    func setup(){
        itemSize = CGSizeMake(306, 40)
        dynamicAnimator = UIDynamicAnimator(collectionViewLayout: self)
        visibleIndexPathsSet = NSMutableSet()
        visibleHeaderAndFootSet = NSMutableSet()
    }
    
    override func prepareLayout() {
        super.prepareLayout()
        
        if (UIApplication.sharedApplication().statusBarOrientation != interfaceOrientation){
            dynamicAnimator.removeAllBehaviors()
            visibleIndexPathsSet = NSMutableSet()
        }
        
        interfaceOrientation = UIApplication.sharedApplication().statusBarOrientation;
        
        let frame = CGRectMake((collectionView?.bounds.origin.x)!, (collectionView?.bounds.origin.y)!, (collectionView?.frame.size.width)!, (collectionView?.frame.size.height)!)
        let visibleRect = CGRectInset(frame, -100, -100)
        
        let itemsInVisibleRectArray = super.layoutAttributesForElementsInRect(visibleRect)
        
        let flattenedArray = itemsInVisibleRectArray!.map({$0.indexPath})
        
        let itemsIndexPathsInVisibleRectSet = NSSet(array: flattenedArray)
        
        let noLongerVisibleBehaviours = dynamicAnimator.behaviors.filter(){
            let attribute = ($0 as! UIAttachmentBehavior).items[0] as! UICollectionViewLayoutAttributes
            return !itemsIndexPathsInVisibleRectSet.containsObject(attribute.indexPath)
        }
        
        for obj in noLongerVisibleBehaviours {
            let behavior = obj as! UIAttachmentBehavior
            dynamicAnimator.removeBehavior(behavior)
            let attribute = behavior.items.first as! UICollectionViewLayoutAttributes
            visibleIndexPathsSet.removeObject(attribute.indexPath)
            visibleHeaderAndFootSet.removeObject(attribute.indexPath)
        }
        
        let newlyVisibleItems = itemsInVisibleRectArray!.filter(){
            let item = $0 as UICollectionViewLayoutAttributes
            if item.representedElementCategory == .Cell{
                return !visibleIndexPathsSet.containsObject(item.indexPath)
            }else{
                return !visibleHeaderAndFootSet.containsObject(item.indexPath)
            }
        }
        
        let touchLocation = collectionView?.panGestureRecognizer.locationInView(collectionView)
        
        for item in newlyVisibleItems{
            
            var center = item.center
            let springBehaviour = UIAttachmentBehavior(item: item, attachedToAnchor: center)
            springBehaviour.length = 1.0
            springBehaviour.damping = 0.8
            springBehaviour.frequency = 1.0
            
            if !(touchLocation?.x == 0 && touchLocation?.y == 0) {
                if (scrollDirection == .Vertical){
                    let distanceFromTouch = (touchLocation?.y)! - springBehaviour.anchorPoint.y
                    var scrollResistance : CGFloat
                    
                    if scrollResistanceFactor != 0 {
                        scrollResistance = distanceFromTouch / scrollResistanceFactor
                    }else{
                        scrollResistance = distanceFromTouch / CGFloat(kScrollResistanceFactorDefault)
                    }
                    
                    if latestDelta < 0 {
                        center.y = center.y + max(latestDelta, latestDelta * scrollResistance)
                    }else{
                        center.y = center.y + min(latestDelta, latestDelta * scrollResistance)
                    }
                    
                    item.center = center
                }else{
                    
                    let distanceFromTouch = (touchLocation?.x)! - springBehaviour.anchorPoint.x
                    var scrollResistance : CGFloat
                    
                    if scrollResistanceFactor != 0 {
                        scrollResistance = distanceFromTouch / scrollResistanceFactor
                    }else{
                        scrollResistance = distanceFromTouch / CGFloat(kScrollResistanceFactorDefault)
                    }
                    
                    if latestDelta < 0 {
                        center.x = center.x + max(latestDelta, latestDelta * scrollResistance)
                    }else{
                        center.x = center.x + min(latestDelta, latestDelta * scrollResistance)
                    }
                    
                    item.center = center
                }
            }
            
            dynamicAnimator.addBehavior(springBehaviour)
            if item.representedElementCategory == .Cell{
                visibleIndexPathsSet.addObject(item.indexPath)
            }else{
                visibleHeaderAndFootSet.addObject(item.indexPath)
            }
            
        }
        
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        let attributes = dynamicAnimator.itemsInRect(rect) as! [UICollectionViewLayoutAttributes]
        return attributes
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        
        let dynamicLayoutAttributes = dynamicAnimator.layoutAttributesForCellAtIndexPath(indexPath)
        
        if dynamicLayoutAttributes != nil{
            return dynamicLayoutAttributes
        }else{
            return super.layoutAttributesForItemAtIndexPath(indexPath)
        }
        
    }
    
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        
        let scrollView = collectionView
        let kScrollResistanceFactorDefault :CGFloat = 900.0
        
        var delta : CGFloat = 0.0;
        
        if (scrollDirection == .Vertical){
            delta = newBounds.origin.y - scrollView!.bounds.origin.y
        }else{
            delta = newBounds.origin.x - scrollView!.bounds.origin.x
        }
        
        latestDelta = delta
        
        let touchLocation = collectionView?.panGestureRecognizer.locationInView(collectionView)
        
        for springBehaviour in dynamicAnimator.behaviors {
            
            let springBe = springBehaviour as! UIAttachmentBehavior
            
            if scrollDirection == .Vertical {
                
                let distanceFromTouch = touchLocation!.y - springBe.anchorPoint.y
                var scrollResistance : CGFloat
                
                if scrollResistanceFactor > 0 {
                    scrollResistance = distanceFromTouch / scrollResistanceFactor
                }else{
                    scrollResistance = distanceFromTouch / kScrollResistanceFactorDefault
                }
                
                let item = springBe.items.first
                var center = item?.center
                
                if delta < 0 {
                    center?.y = (center?.y)! + max(delta, delta * scrollResistance)
                }else{
                    center?.y = (center?.y)! + min(delta, delta * scrollResistance)
                }
                item?.center = center!
                
                dynamicAnimator.updateItemUsingCurrentState(item!)
                
            } else {
                let distanceFromTouch = touchLocation!.x - springBe.anchorPoint.x
                var scrollResistance : CGFloat
                
                if scrollResistanceFactor > 0 {
                    scrollResistance = distanceFromTouch / scrollResistanceFactor
                }else{
                    scrollResistance = distanceFromTouch / kScrollResistanceFactorDefault
                }
                
                let item = springBe.items.first
                var center = item?.center
                
                if delta < 0 {
                    center?.x = (center?.x)! + max(delta, delta * scrollResistance)
                }else{
                    center?.x = (center?.x)! + min(delta, delta * scrollResistance)
                }
                item?.center = center!
                
                dynamicAnimator.updateItemUsingCurrentState(item!)
            }
        }
        return false
    }
    
    
    override func prepareForCollectionViewUpdates(updateItems: [UICollectionViewUpdateItem]) {
        super.prepareForCollectionViewUpdates(updateItems)
        
        for item in updateItems {
            
            if (item.updateAction == .Insert){
                
                if dynamicAnimator.layoutAttributesForCellAtIndexPath(item.indexPathAfterUpdate) != nil{
                    return;
                }
                
                let attributes = UICollectionViewLayoutAttributes(forCellWithIndexPath: item.indexPathAfterUpdate)
                
                let springBehaviour = UIAttachmentBehavior(item: attributes, attachedToAnchor: attributes.center)
                
                springBehaviour.length = 1.0
                springBehaviour.damping = 0.8
                springBehaviour.frequency = 1.0
                
                dynamicAnimator.addBehavior(springBehaviour)
            }
        }
    }
}


