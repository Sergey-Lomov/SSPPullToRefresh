//
//  SSPPullToRefreshView.swift
//  BezierAnimation
//
//  Created by Sergey Lomov on 4/19/17.
//  Copyright © 2017 Rozdoum. All rights reserved.
//

import UIKit

protocol SSPPullToRefreshDelegate {
    func preparationDidFinish(refreshView:SSPPullToRefreshView)
    func compressingDidFinish(refreshView:SSPPullToRefreshView)
   // func pullReleaseDidFinish(refreshView:SSPPullToRefreshView)
}

class SSPPullToRefreshView : UIView {
    var delegate:SSPPullToRefreshDelegate?
    
    func setPullProgress(progress:CGFloat) {}
    func releasePull() {}
    func startUpdateAnimation() {}
    func startCompressingAnimation() {}
    
    var activityIndicatorView:SSPActivityIndicatorView?
}
