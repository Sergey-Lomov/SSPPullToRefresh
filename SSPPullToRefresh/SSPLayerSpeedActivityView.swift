//
//  SSPLayerSpeedActivityView.swift
//  BezierAnimation
//
//  Created by Sergey Lomov on 4/24/17.
//  Copyright © 2017 Rozdoum. All rights reserved.
//

import UIKit

class SSPLayerSpeedActivityView: SSPActivityIndicatorView {

    // Should be setted in subclass at animation adding
    internal var animationAddingTime:CFTimeInterval?
    
    open override func reset() {
        layer.speed = 0.0
        layer.timeOffset = animationAddingTime!
    }
    
    open override func startAnimating() {
        let stopedLayerTime = layer.convertTime(CACurrentMediaTime(), from: nil)
        layer.speed = 1.0
        layer.timeOffset = 0.0
        let runedLayerTime = layer.convertTime(CACurrentMediaTime(), from: nil)
        layer.timeOffset = -1 * (runedLayerTime - stopedLayerTime)
    }
    
    open override func stopAnimating() {
        let layerTime = layer.convertTime(CACurrentMediaTime(), from: nil)
        layer.speed = 0
        layer.timeOffset = layerTime
    }

}
