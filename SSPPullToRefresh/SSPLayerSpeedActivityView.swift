//
//  SSPLayerSpeedActivityView.swift
//  BezierAnimation
//
//  Created by Sergey Lomov on 4/24/17.
//  Copyright © 2017 Rozdoum. All rights reserved.
//

import UIKit

open class SSPLayerSpeedActivityView: SSPActivityIndicatorView {

    private var animationAddingTime:CFTimeInterval?
    
    // Should be called in subclass at animation adding
    public final func setAnimationAddingTime () {
        animationAddingTime = CACurrentMediaTime()
    }
    
    public final override func reset() {
        layer.speed = 0.0
        layer.timeOffset = animationAddingTime!
    }
    
    public final override func startAnimating() {
        let stopedLayerTime = layer.convertTime(CACurrentMediaTime(), from: nil)
        layer.speed = 1.0
        layer.timeOffset = 0.0
        let runedLayerTime = layer.convertTime(CACurrentMediaTime(), from: nil)
        layer.timeOffset = -1 * (runedLayerTime - stopedLayerTime)
    }
    
    public final override func stopAnimating() {
        let layerTime = layer.convertTime(CACurrentMediaTime(), from: nil)
        layer.speed = 0
        layer.timeOffset = layerTime
    }

}
