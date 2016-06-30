//
//  DropItView.swift
//  DropIt
//
//  Created by Tom Yu on 6/30/16.
//  Copyright © 2016 kangleyu. All rights reserved.
//

import UIKit
import CoreMotion

class DropItView: NamedBazierPathsView, UIDynamicAnimatorDelegate {
    
    private let dropsPerRow = Constants.DropsPerRow
    private let dropBehavior = FallingObjectBehavior()
    private var attachment: UIAttachmentBehavior? {
        willSet {
            if attachment != nil {
                animator.removeBehavior(attachment!)
                bezierPaths[Constants.Attachment] = nil
            }
        }
        didSet {
            if attachment != nil {
                animator.addBehavior(attachment!)
                attachment!.action = {
                    // break the cycle reference
                    [unowned self] in
                    if let attachedDrop = self.attachment?.items.first as? UIView {
                        self.bezierPaths[Constants.Attachment] =
                            UIBezierPath.lineFrom(self.attachment!.anchorPoint, to: attachedDrop.center)
                    }
                }
            }
        }
    }
    
    // lazy var here to allow call self here
    private lazy var animator: UIDynamicAnimator = {
        let animator = UIDynamicAnimator(referenceView: self)
        animator.delegate = self
        return animator
    }()
    
    var animating: Bool = false {
        didSet {
            if animating {
                animator.addBehavior(dropBehavior)
                updateRealGravity()
            } else {
                animator.removeBehavior(dropBehavior)
            }
        }
    }
    
    var readGravity: Bool = false {
        didSet {
            updateRealGravity()
        }
    }
    
    private let motionManager = CMMotionManager()
    private func updateRealGravity() {
        if readGravity {
            if motionManager.accelerometerAvailable && !motionManager.accelerometerActive {
                motionManager.accelerometerUpdateInterval = 0.25
                motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.mainQueue()) {
                    [unowned self]
                    (data, error) in
                    if self.dropBehavior.dynamicAnimator != nil {
                        if var dx = data?.acceleration.x, var dy = data?.acceleration.y {
                            switch UIDevice.currentDevice().orientation {
                                case.Portrait: dy = -dy
                                case.PortraitUpsideDown: break
                                case.LandscapeRight: swap(&dx, &dy)
                                case.LandscapeLeft: swap(&dx, &dy); dy = -dy
                                default: dx = 0; dy = 0
                            }
                            self.dropBehavior.gravity.gravityDirection = CGVector(dx: dx, dy: dy)
                        }
                    } else {
                        self.motionManager.stopAccelerometerUpdates()
                    }
                }
            }
        } else {
            motionManager.stopAccelerometerUpdates()
        }
    }
    
    private var dropSize: CGSize {
        let size = bounds.size.width / CGFloat(dropsPerRow)
        return CGSize(width: size, height: size)
    }
    
    private var lastDrop: UIView?
    
    func grabDrop(recognizer: UIPanGestureRecognizer) {
        let gesturePoint = recognizer.locationInView(self)
        switch recognizer.state {
        case .Began:
            // create the attachment
            if let dropToAttachTo = lastDrop where dropToAttachTo.superview != nil {
                attachment = UIAttachmentBehavior(item: dropToAttachTo, attachedToAnchor: gesturePoint)
            }
            lastDrop = nil
        case .Changed:
            // change the attachment's anchor point
            attachment?.anchorPoint = gesturePoint
        default:
            attachment = nil
        }
    }
    
    func dynamicAnimatorDidPause(animator: UIDynamicAnimator) {
        removeCompleteRow()
    }
    
    func addDrop() {
        var frame = CGRect(origin: CGPoint.zero, size: dropSize)
        frame.origin.x   = CGFloat.random(dropsPerRow) * dropSize.width
        
        let drop = UIView(frame: frame)
        drop.backgroundColor = UIColor.random
        
        addSubview(drop)
        dropBehavior.addItem(drop)
        lastDrop = drop
    }
    
    private func removeCompleteRow() {
        var dropsToRemove = [UIView]()
        
        var hitTestRect = CGRect(origin: bounds.lowerLeft, size: dropSize)
        repeat {
            hitTestRect.origin.x = bounds.minX
            hitTestRect.origin.y -= dropSize.height
            var dropsTested = 0
            var dropsFound = [UIView]()
            while dropsTested < dropsPerRow {
                if let hitView = hitTest(hitTestRect.mid, withEvent: nil) where hitView.superview == self {
                    dropsFound.append(hitView)
                } else {
                    break
                }
                hitTestRect.origin.x += dropSize.width
                dropsTested += 1
            }
            if dropsTested == dropsPerRow {
                dropsToRemove = dropsFound
            }
        } while dropsToRemove.count == 0 && hitTestRect.origin.y > bounds.minY
        
        for drop in dropsToRemove {
            dropBehavior.removeItem(drop)
            drop.removeFromSuperview()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let path = UIBezierPath(ovalInRect: CGRect(center: bounds.mid, size: dropSize))
        dropBehavior.addBarrier(path, named: Constants.MiddleBarrier)
        bezierPaths[Constants.MiddleBarrier] = path
        
    }

}
