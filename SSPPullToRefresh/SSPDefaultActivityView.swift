//
//  SSPDefaultActivityView.swift
//  BezierAnimation
//
//  Created by Sergey Lomov on 4/24/17.
//  Copyright © 2017 Rozdoum. All rights reserved.
//

import UIKit

open class SSPDefaultActivityView: SSPLayerSpeedActivityView {

    var activity:UIActivityIndicatorView!
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        addDefaultActivity()
        
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addDefaultActivity()
    }
    
    private func addDefaultActivity () {
        activity = UIActivityIndicatorView()
        activity.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(activity)
        activity.isHidden = false
        activity.startAnimating()
        setAnimationAddingTime()
        
        let leftConstraint = NSLayoutConstraint(item: activity, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.left, multiplier: 1, constant: 0)
        let rightConstraint = NSLayoutConstraint(item: activity, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.right, multiplier: 1, constant: 0)
        let topConstraint = NSLayoutConstraint(item: activity, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 0)
        let bottomtConstraint = NSLayoutConstraint(item: activity, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: 0)
        
        NSLayoutConstraint.activate([leftConstraint, rightConstraint, topConstraint, bottomtConstraint])
    }
    
    
}
