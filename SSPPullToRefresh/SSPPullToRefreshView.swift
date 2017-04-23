//
//  SSPPullToRefreshView.swift
//  BezierAnimation
//
//  Created by Sergey Lomov on 4/19/17.
//  Copyright © 2017 Rozdoum. All rights reserved.
//

import UIKit

public protocol SSPPullToRefreshDelegate {
    func preparationDidFinish(refreshView:SSPPullToRefreshView)
    func compressingDidFinish(refreshView:SSPPullToRefreshView)
    func pullReleaseDidFinish(refreshView:SSPPullToRefreshView)
}

open class SSPPullToRefreshView : UIView {
    open var delegate:SSPPullToRefreshDelegate?
    open var activityIndicatorView:SSPActivityIndicatorView?
    
    open func setPullProgress(progress:CGFloat) {}
    open func releasePull() {}
    open func startUpdateAnimation() {}
    open func startCompressingAnimation() {}
}
