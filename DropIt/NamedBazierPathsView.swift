//
//  NamedBazierPathsView.swift
//  DropIt
//
//  Created by Tom Yu on 6/30/16.
//  Copyright © 2016 kangleyu. All rights reserved.
//

import UIKit

class NamedBazierPathsView: UIView {
    var bezierPaths = [String:UIBezierPath]() {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func drawRect(rect: CGRect) {
        for (_, path) in bezierPaths {
            path.stroke()
        }
    }

}
