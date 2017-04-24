//
//  SSPLiquidRefreshView.swift
//  BezierAnimation
//
//  Created by Sergey Lomov on 4/15/17.
//  Copyright © 2017 Rozdoum. All rights reserved.
//

import UIKit

open class SSPLiquidRefreshView: SSPPullToRefreshView {

    open override var activityIndicatorView: SSPActivityIndicatorView? {
        didSet {
            oldValue?.removeFromSuperview()
            self.activityWrapper.addSubview(activityIndicatorView!)
        }
    }
    
    var fillColor:UIColor?
    var strokeColor:UIColor?
    
    var activitySizeCoeffecient:CGFloat = 1.0 // Relation between blob dimeter and activity frame size
    var blobRadius:CGFloat = 25
    var blobEdgeDistanceCoeffectient:CGFloat = 3 // Relation between blob radius and distance when blob drop
    var blobBulkCoeffectient:CGFloat = 1.5 // Increase recession effect
    var blobDestinationCoeffecient:CGFloat = 4 // Relation between blob radius and distance between legide height and destination blob Y position
    
    // Angle of line from blob curves startpoint to control point 1 should be equal 135˚ (-135˚ for left).
    // Folowing coeffectient means relation between radius and distance betwee start point and control point 1
    // Value of coeffetient was gained by experiments (uses tool https://www.desmos.com)
    private let blobCurvesPoint1DisplacementCoeffetient:CGFloat = 0.75
    private let innerJoinPointsAngle = CGFloat(M_PI / 4) // Angle of line from blob center to inner curves end points
    
    private let pullFinalOuterCurvesPoint1Angle:CGFloat = CGFloat(3 * M_PI / 2) // Angle of outer curves control point 1
    
    private var isLayersInit = false
    
    private let pullLayer = CALayer()
    private let updateLayer = CALayer()
    private let compressingLayer = CALayer()
    private let activityWrapper = UIView()
    
    private var updateBlobLayer:CAShapeLayer!
    private var preparationBlobAnimation:CAAnimation!
    private let preparationPhaseDuration:CFTimeInterval = 0.5
    private let preparationPrewaveDuration:CFTimeInterval = 0.15
    private let preparationWavesAmount:Int = 4
    private let preparationActivityPresentationDuration:CFTimeInterval = 0.5
    
    private var pullTensionLayer:CAShapeLayer!
    private var pullReleaseLayer:CAShapeLayer!
    private let pullReleaseWavesAmount:Int = 4
    private let pullReleaseDuration:CFTimeInterval = 0.8
    private let pullReleasePrewaveDuration:CFTimeInterval = 0.3
    private var pullReleaseInitialWaveForce:CGFloat {
        get {
            return blobEdgeDistanceCoeffectient * blobRadius / 8
        }
    }
    private var compressingBlobTension:CGFloat {
        get {
            return blobRadius / 2
        }
    }
    private var compressingInitialWaveForce:CGFloat {
        get {
            return compressingBlobTension / 2
        }
    }
    private let compressingPhaseDuration:CFTimeInterval = 0.8
    private let compressingPrecontactDuration:CFTimeInterval = 0.2 // Time for blob drop to liquid massive
    private let compressingPrestabilisationDuration:CFTimeInterval = 0.15 // Time for recessing from contact path to first wave path
    private let compressingWavesAmount:Int = 4
    private let compressingActivityHidingDuration:CFTimeInterval = 0.5
    private var compressingMassiveAnimation:CAAnimation!
    private var compressingMassiveLayer:CAShapeLayer!
    
    private typealias BezierCurve = (start:CGPoint, end:CGPoint, control1:CGPoint, control2:CGPoint)
    private typealias BlobCurves = (leftTop:BezierCurve, leftBottom:BezierCurve, rightTop:BezierCurve, rightBottom:BezierCurve)
    
// MARK: Pathes generation functions
    
    private func pullInitialPath(_ rect: CGRect) -> UIBezierPath {
        let initialLiquidHeight = rect.height
        let blobDistance = blobRadius * blobEdgeDistanceCoeffectient
        let centerX = rect.width / 2
        
        let leftOuterJoinPoint = CGPoint(x:0, y:initialLiquidHeight)
        let rightOuterJoinPoint = CGPoint(x:rect.width, y:initialLiquidHeight)
        
        let innerJoinPointsXCoefficient:CGFloat = 0.75// Set inner join points movement to corners. 1 - center, 0 - left/right corner
        let pullFinalBlobCenterX = rect.width / 2
        let pullFinalLeftInnerJoinPointX = pullFinalBlobCenterX - blobRadius * cos(innerJoinPointsAngle)
        let pullFinalRightInnerJoinPointX = pullFinalBlobCenterX + blobRadius * cos(innerJoinPointsAngle)
        let leftInnerJoinPointX = pullFinalLeftInnerJoinPointX * innerJoinPointsXCoefficient
        let rightInnerJoinPointX = pullFinalRightInnerJoinPointX + (frame.width - pullFinalRightInnerJoinPointX) * (1 - innerJoinPointsXCoefficient)
        let leftInnerJoinPoint = CGPoint(x:leftInnerJoinPointX, y:initialLiquidHeight)
        let rightInnerJoinPoint = CGPoint(x:rightInnerJoinPointX, y:initialLiquidHeight)
        
        let blobJoinPoint = CGPoint(x:centerX, y:initialLiquidHeight)
        
        // Bezier curve calculates with UI issue when start point and first control point are equal.
        // For fix this problem I was forced to move control point 1 up by 0.2 (less values also produces problem)
        let leftOuterCurvePoint1 = CGPoint(x:0, y:initialLiquidHeight + 0.2)
        let leftOuterCurvePoint2 = CGPoint(x: 0, y: leftOuterJoinPoint.y)
        let rightOuterCurvePoint1 = CGPoint(x: rect.width, y:initialLiquidHeight + 0.2)
        let rightOuterCurvePoint2 = CGPoint(x: rect.width, y: leftOuterJoinPoint.y)
        
        let pullFinalInnerCurvesPoint1Lenght = blobDistance // blobDistance equal to distance from inner curvew start point to control point 1, because for calculate start point coords uses 45˚ angle and ctg(45˚) = 1
        let leftInnerCurvePoint1X = leftOuterJoinPoint.x + pullFinalInnerCurvesPoint1Lenght
        let rightInnerCurvePoint1X = rightOuterJoinPoint.x - pullFinalInnerCurvesPoint1Lenght
        let leftInnerCurvesPoint1 = CGPoint(x: leftInnerCurvePoint1X, y: initialLiquidHeight)
        let rightInnerCurvesPoint1 = CGPoint(x: rightInnerCurvePoint1X, y: initialLiquidHeight)
        
        
        let pullFinalInnerCurvesPoint2Lenght = pullFinalRightInnerJoinPointX - pullFinalLeftInnerJoinPointX
        let leftInnerCurvePoint2X = leftInnerJoinPoint.x - pullFinalInnerCurvesPoint2Lenght
        let rightInnerCurvePoint2X = rightInnerJoinPoint.x + pullFinalInnerCurvesPoint2Lenght
        let leftInnerCurvePoint2 = CGPoint(x: leftInnerCurvePoint2X, y: initialLiquidHeight)
        let rightInnerCurvePoint2 = CGPoint(x: rightInnerCurvePoint2X, y: initialLiquidHeight)
        
        let pullFinalBlobPoint1Distance = blobRadius * blobCurvesPoint1DisplacementCoeffetient
        let leftBlobCurvePoint1X = leftInnerJoinPoint.x + pullFinalBlobPoint1Distance
        let rightBlobCurvePoint1X = rightInnerJoinPoint.x - pullFinalBlobPoint1Distance
        let leftBlobCurvePoint1 = CGPoint(x: leftBlobCurvePoint1X, y: initialLiquidHeight)
        let rightBlobCurvePoint1 = CGPoint(x: rightBlobCurvePoint1X, y: initialLiquidHeight)
        let leftBlobCurvePoint2 = CGPoint(x: blobJoinPoint.x, y: blobJoinPoint.y)
        let rightBlobCurvePoint2 = CGPoint(x: blobJoinPoint.x, y: blobJoinPoint.y)
        
        let resultPath = UIBezierPath()
        resultPath.move(to: CGPoint.zero)
        
        resultPath.addLine(to: CGPoint(x:0, y:initialLiquidHeight))
        
        resultPath.addCurve(to: leftOuterJoinPoint,
                            controlPoint1: leftOuterCurvePoint1,
                            controlPoint2: leftOuterCurvePoint2)
        
        resultPath.addCurve(to: leftInnerJoinPoint,
                            controlPoint1: leftInnerCurvesPoint1,
                            controlPoint2: leftInnerCurvePoint2)
        
        resultPath.addCurve(to: blobJoinPoint,
                            controlPoint1: leftBlobCurvePoint1,
                            controlPoint2: leftBlobCurvePoint2)
        
        // Right curves calculates semetrically to left, but draws from left to right instead semetrically right to left
        // By this reason control points should be swiped
        
        resultPath.addCurve(to: rightInnerJoinPoint,
                            controlPoint1: rightBlobCurvePoint2,
                            controlPoint2: rightBlobCurvePoint1)
        
        resultPath.addCurve(to: rightOuterJoinPoint,
                            controlPoint1: rightInnerCurvePoint2,
                            controlPoint2: rightInnerCurvesPoint1)
        
        resultPath.addCurve(to: CGPoint(x:rect.width, y:initialLiquidHeight),
                            controlPoint1: rightOuterCurvePoint2,
                            controlPoint2: rightOuterCurvePoint1)
        
        resultPath.addLine(to: CGPoint(x:rect.width, y:0))
        
        resultPath.close()
        return resultPath
    }
    
    private func pullDepletedlCurvesStartHeight (_ rect: CGRect) -> CGFloat {
        let heightDeprivation = self.heightDeprivation(inRect: rect)
        return rect.height - heightDeprivation * 2
    }

    private func pullFinalPath (_ rect: CGRect) -> UIBezierPath {
        let heightDeprivation = self.heightDeprivation(inRect: rect)
        let curvesInitialHeight = pullDepletedlCurvesStartHeight(rect)

        let blobDistance = blobRadius * blobEdgeDistanceCoeffectient
        let blobCenterY = rect.height - heightDeprivation + blobDistance
        let blobCenterX = rect.width / 2
        
        let leftOuterJoinPointX = blobCenterX - blobDistance // blobDistance should be multyplyed to ctg(45˚) = 1
        let rightOuterJoinPointX = blobCenterX + blobDistance // blobDistance should be multyplyed to ctg(45˚) = 1
        let outerJoinPointsY = rect.height - heightDeprivation
        let leftOuterJoinPoint = CGPoint(x:leftOuterJoinPointX, y:outerJoinPointsY)
        let rightOuterJoinPoint = CGPoint(x:rightOuterJoinPointX, y:outerJoinPointsY)
        
        let leftInnerJoinPointX = blobCenterX - blobRadius * cos(innerJoinPointsAngle)
        let rightInnerJoinPointX = blobCenterX + blobRadius * cos(innerJoinPointsAngle)
        let innerJoinPointsY = blobCenterY - blobRadius * cos(innerJoinPointsAngle)
        let leftInnerJoinPoint = CGPoint(x:leftInnerJoinPointX, y:innerJoinPointsY)
        let rightInnerJoinPoint = CGPoint(x:rightInnerJoinPointX, y:innerJoinPointsY)
        
        let blobJoinPoint = CGPoint(x:blobCenterX, y:blobCenterY + blobRadius)
        
        let outerCurvesPoint1Radius = heightDeprivation
        let outerCurvesPoint2Radius = heightDeprivation
        let outerCurvesPoint1XDisplacement = cos(pullFinalOuterCurvesPoint1Angle) * outerCurvesPoint1Radius
        let outerCurvesPoint1YDisplacement = -1 * sin(pullFinalOuterCurvesPoint1Angle) * outerCurvesPoint1Radius
        let leftOuterCurvePoint1 = CGPoint(x: outerCurvesPoint1XDisplacement, y: curvesInitialHeight + outerCurvesPoint1YDisplacement)
        // Displacements for control point 2 not necessary, because it's angle equal -90˚. sin(-90˚) = -1, cos(-90˚) = 0
        let leftOuterCurvePoint2 = CGPoint(x: leftOuterJoinPoint.x - outerCurvesPoint2Radius, y: leftOuterJoinPoint.y)
        let rightOuterCurvePoint1 = CGPoint(x: rect.width - outerCurvesPoint1XDisplacement, y: curvesInitialHeight + outerCurvesPoint1YDisplacement)
        let rightOuterCurvePoint2 = CGPoint(x: rightOuterJoinPoint.x + outerCurvesPoint2Radius, y: leftOuterJoinPoint.y)
        
        let innerCurvesPoint1 = CGPoint(x: rect.width / 2, y: outerJoinPointsY) //Yep one control point 1 for both curves
        // Inner curves control point 2 should be at top of mirrored join point. Angle of line from endpoint and control point 2 should be equal 45˚ (-45˚ for right). By this reason calculations became more shot:
        let leftInnerCurvePoint2X = rightInnerJoinPoint.x
        let rightInnerCurvePoint2X = leftInnerJoinPoint.x
        let innerCurvesPoint2Y = innerJoinPointsY - (rightInnerJoinPoint.x - leftInnerJoinPointX)
        let leftInnerCurvePoint2 = CGPoint(x: leftInnerCurvePoint2X, y: innerCurvesPoint2Y)
        let rightInnerCurvePoint2 = CGPoint(x: rightInnerCurvePoint2X, y: innerCurvesPoint2Y)
        
        let blobPoint1Distance = blobRadius * blobCurvesPoint1DisplacementCoeffetient
        let blobCurvesPoint1XDisplacement = cos(CGFloat(M_PI / 4 * 3)) * blobPoint1Distance
        let blobCurvesPoint1YDisplacement = sin(CGFloat(M_PI / 4 * 3)) * blobPoint1Distance
        let leftBlobCurvePoint1X = leftInnerJoinPoint.x - abs(blobCurvesPoint1XDisplacement)
        let rightBlobCurvePoint1X = rightInnerJoinPoint.x + abs(blobCurvesPoint1XDisplacement)
        let blobCurvesPoint1Y = innerJoinPointsY + blobCurvesPoint1YDisplacement
        let leftBlobCurvePoint1 = CGPoint(x: leftBlobCurvePoint1X, y: blobCurvesPoint1Y)
        let rightBlobCurvePoint1 = CGPoint(x: rightBlobCurvePoint1X, y: blobCurvesPoint1Y)
        let leftBlobCurvePoint2 = CGPoint(x: blobJoinPoint.x - blobRadius, y: blobJoinPoint.y)
        let rightBlobCurvePoint2 = CGPoint(x: blobJoinPoint.x + blobRadius, y: blobJoinPoint.y)
        
        let resultPath = UIBezierPath()
        resultPath.move(to: CGPoint.zero)
        
        resultPath.addLine(to: CGPoint(x:0, y:curvesInitialHeight))
        
        resultPath.addCurve(to: leftOuterJoinPoint,
                            controlPoint1: leftOuterCurvePoint1,
                            controlPoint2: leftOuterCurvePoint2)
        
        resultPath.addCurve(to: leftInnerJoinPoint,
                            controlPoint1: innerCurvesPoint1,
                            controlPoint2: leftInnerCurvePoint2)
        
        resultPath.addCurve(to: blobJoinPoint,
                            controlPoint1: leftBlobCurvePoint1,
                            controlPoint2: leftBlobCurvePoint2)
        
        // Right curves calculates semetrically to left, but draws from left to right instead semetrically right to left
        // By this reason control points should be swiped
        
        resultPath.addCurve(to: rightInnerJoinPoint,
                            controlPoint1: rightBlobCurvePoint2,
                            controlPoint2: rightBlobCurvePoint1)
        
        resultPath.addCurve(to: rightOuterJoinPoint,
                            controlPoint1: rightInnerCurvePoint2,
                            controlPoint2: innerCurvesPoint1)
        
        resultPath.addCurve(to: CGPoint(x:rect.width, y:curvesInitialHeight),
                            controlPoint1: rightOuterCurvePoint2,
                            controlPoint2: rightOuterCurvePoint1)
        
        resultPath.addLine(to: CGPoint(x:rect.width, y:0))
        
        resultPath.close()
        return resultPath
    }
    
    // Path for upper massive at start of update preparation animation
    private func preparationMassiveInitialPath(_ rect: CGRect) -> UIBezierPath {
        let heightDeprivation = self.heightDeprivation(inRect: rect)
        let pullFinalCurvesStartHeight = pullDepletedlCurvesStartHeight(rect)
        
        let blobDistance = blobRadius * blobEdgeDistanceCoeffectient
        let pullFinalBlobCenterY = rect.height - heightDeprivation + blobDistance
        let blobCenterX = rect.width / 2
        
        let pullFinalInnerJoinPointsY = pullFinalBlobCenterY - blobRadius * cos(innerJoinPointsAngle)
        let joinPointY = (pullFinalCurvesStartHeight + pullFinalInnerJoinPointsY) / 2
        let joinPoint = CGPoint(x: blobCenterX, y: joinPointY)
        
        let curvesPoint1Radius = heightDeprivation * 2
        let curvesPoint2Radius = joinPointY
        let curvesPoint1XDisplacement = cos(pullFinalOuterCurvesPoint1Angle) * curvesPoint1Radius
        let curvesPoint1YDisplacement = -1 * sin(pullFinalOuterCurvesPoint1Angle) * curvesPoint1Radius
        let leftCurvePoint1 = CGPoint(x: curvesPoint1XDisplacement, y: pullFinalCurvesStartHeight + curvesPoint1YDisplacement)
        let rightCurvePoint1 = CGPoint(x: rect.width - curvesPoint1XDisplacement, y: pullFinalCurvesStartHeight + curvesPoint1YDisplacement)
        // Displacements for control point 2 not necessary, because it's angle equal 0˚. sin(0˚) = 0, cos (0˚) = 1
        let curvesPoint2 = CGPoint(x: joinPoint.x, y: joinPoint.y - curvesPoint2Radius) //One point for both curves
        
        
        let resultPath = UIBezierPath()
        resultPath.move(to: CGPoint.zero)
        
        resultPath.addLine(to: CGPoint(x:0, y:pullFinalCurvesStartHeight))
        
        resultPath.addCurve(to: joinPoint,
                            controlPoint1: leftCurvePoint1,
                            controlPoint2: curvesPoint2)
        
        // Right curve calculates semetrically to left, but draws from left to right instead semetrically right to left
        // By this reason control points should be swiped
        
        resultPath.addCurve(to: CGPoint(x:rect.width, y:pullFinalCurvesStartHeight),
                            controlPoint1: curvesPoint2,
                            controlPoint2: rightCurvePoint1)

        resultPath.addLine(to: CGPoint(x:rect.width, y:0))
        
        resultPath.close()
        return resultPath
    }
    
    private func massiveWaves (rect: CGRect, amount:Int, initialForce:CGFloat, initialRecessin:Bool, duration:CFTimeInterval) -> CAAnimationGroup {
        let liquidHeight = liquidDepletionHeight(inRect: rect)
        return self.massiveWaves(rect: rect, amount: amount, initialForce: initialForce, initialRecessin: initialRecessin, duration: duration, liquidHeight:liquidHeight)
    }
    
    private func massiveWaves (rect: CGRect, amount:Int, initialForce:CGFloat, initialRecessin:Bool, duration:CFTimeInterval, liquidHeight:CGFloat) -> CAAnimationGroup {
        var pathes = Array<UIBezierPath>()
        for iterator in 0...amount {
            var force:CGFloat = 0
            if iterator != 0 {
                force = initialForce / CGFloat(amount) * CGFloat(iterator)
            }
            
            let isWaveEven = (amount - iterator) % 2 == 0
            let recessing = isWaveEven ? initialRecessin : !initialRecessin
            let path = massiveWavePath(inRect: rect, liquidHeight: liquidHeight, waveHeight: force, recessing: recessing)
            pathes.append(path)
        }
        
        return self.animationGroupForWavesPathes(pathes: pathes.reversed(), groupDuration: duration)
    }
   
    private func massiveWaveCurves(inRect rect: CGRect, liquidHeight:CGFloat, waveHeight:CGFloat, recessing:Bool) -> (left: BezierCurve, right: BezierCurve) {
        let waveCenterX = rect.width / 2
        let recessingMultyplier:CGFloat = recessing ? -1 : 1
        
        let joinPointY = liquidHeight + recessingMultyplier * waveHeight
        let joinPoint = CGPoint(x: waveCenterX, y: joinPointY)
        
        let leftCurvePointsX = waveCenterX / 2
        let rightCurvePointsX = (rect.width + waveCenterX) / 2
        let curvesPoint1Y = liquidHeight - recessingMultyplier * waveHeight * 2
        let curvesPoint2Y = joinPoint.y
        
        let leftCurvePoint1 = CGPoint(x: leftCurvePointsX, y:curvesPoint1Y)
        let rightCurvePoint1 = CGPoint(x: rightCurvePointsX, y:curvesPoint1Y)
        let leftCurvePoint2 = CGPoint(x: leftCurvePointsX, y:curvesPoint2Y)
        let rightCurvePoint2 = CGPoint(x:rightCurvePointsX, y:curvesPoint2Y)
        
        let leftCurve = BezierCurve(start: CGPoint(x:0, y:liquidHeight),
                                    end: joinPoint,
                                    control1: leftCurvePoint1,
                                    control2: leftCurvePoint2)
        let rightCurve = BezierCurve(start: joinPoint,
                                     end: CGPoint(x:rect.width, y:liquidHeight),
                                     control1: rightCurvePoint1,
                                     control2: rightCurvePoint2)
        
        return (leftCurve, rightCurve)
    }
    
    private func massiveWavePath(inRect rect: CGRect, liquidHeight:CGFloat, waveHeight:CGFloat, recessing:Bool) -> UIBezierPath {
        let waveCurves = self.massiveWaveCurves(inRect: rect, liquidHeight: liquidHeight, waveHeight: waveHeight, recessing: recessing)
        
        let resultPath = UIBezierPath()
        resultPath.move(to: CGPoint.zero)
        
        resultPath.addLine(to:waveCurves.left.start)
        
        resultPath.addCurve(to: waveCurves.left.end,
                            controlPoint1: waveCurves.left.control1,
                            controlPoint2: waveCurves.left.control2)
        
        // Right curve calculates semetrically to left, but draws from left to right instead semetrically right to left
        // By this reason control points should be swiped
        
        resultPath.addCurve(to: waveCurves.right.end,
                            controlPoint1: waveCurves.right.control2,
                            controlPoint2: waveCurves.right.control1)
        
        resultPath.addLine(to: CGPoint(x:rect.width, y:0))
        
        resultPath.close()
        return resultPath
    }
    
    private func preparationBlobPath(inRect rect: CGRect) -> UIBezierPath {
        let heightDeprivation = self.heightDeprivation(inRect: rect)
        let curvesInitialHeight = pullDepletedlCurvesStartHeight(rect)
        
        let blobDistance = blobRadius * blobEdgeDistanceCoeffectient
        let blobCenterY = rect.height - heightDeprivation + blobDistance
        let blobCenterX = rect.width / 2
        let controlPointsRadius = blobRadius / 2
        
        let pullFinalInnerJoinPointsY = blobCenterY - blobRadius
        let topJoinPointY = (curvesInitialHeight + pullFinalInnerJoinPointsY) / 2
        
        let leftJoinPoint = CGPoint(x:blobCenterX - blobRadius, y:blobCenterY)
        let rightJoinPoint = CGPoint(x:blobCenterX + blobRadius, y:blobCenterY)
        let bottomJoinPoint = CGPoint(x:blobCenterX, y:blobCenterY + blobRadius)
        let topJoinPoint = CGPoint(x: blobCenterX, y: topJoinPointY)
        
        let leftTopControlPoint1 = CGPoint(x: topJoinPoint.x, y: topJoinPoint.y + controlPointsRadius * 2)
        let leftTopControlPoint2 = CGPoint(x: leftJoinPoint.x, y: leftJoinPoint.y - controlPointsRadius)
        
        let leftBottomControlPoint1 = CGPoint(x: leftJoinPoint.x, y: leftJoinPoint.y + controlPointsRadius)
        let leftBottomControlPoint2 = CGPoint(x: bottomJoinPoint.x - controlPointsRadius, y: bottomJoinPoint.y)
        
        let rigthBottomControlPoint1 = CGPoint(x: bottomJoinPoint.x + controlPointsRadius, y: bottomJoinPoint.y)
        let rigthBottomControlPoint2 = CGPoint(x: rightJoinPoint.x, y: rightJoinPoint.y + controlPointsRadius)
        
        let rigthTopControlPoint1 = CGPoint(x: rightJoinPoint.x, y: rightJoinPoint.y - controlPointsRadius)
        let rigthTopControlPoint2 = CGPoint(x: topJoinPoint.x, y: topJoinPoint.y + controlPointsRadius * 2)
 
        let resultPath = UIBezierPath()
        resultPath.move(to: topJoinPoint)
        
        resultPath.addCurve(to: leftJoinPoint,
                            controlPoint1: leftTopControlPoint1,
                            controlPoint2: leftTopControlPoint2)

        resultPath.addCurve(to: bottomJoinPoint,
                            controlPoint1: leftBottomControlPoint1,
                            controlPoint2: leftBottomControlPoint2)
        
        resultPath.addCurve(to: rightJoinPoint,
                            controlPoint1: rigthBottomControlPoint1,
                            controlPoint2: rigthBottomControlPoint2)
        
        resultPath.addCurve(to: topJoinPoint,
                            controlPoint1: rigthTopControlPoint1,
                            controlPoint2: rigthTopControlPoint2)
        
        resultPath.close()
        return resultPath
    }
    
    private func preparationBlobWaves (rect: CGRect, amount:Int, initialForce:CGFloat, duration:CFTimeInterval) -> CAAnimationGroup {

        var pathes = Array<UIBezierPath>()
        for iterator in 0...amount {
            var force:CGFloat = 0
            if iterator != 0 {
                force = initialForce / CGFloat(amount) * CGFloat(iterator)
            }
            
            let isWaveEven = (amount - iterator) % 2 == 0
            if isWaveEven {
                force *= -1
            }
            
            let path = blobWavePath(inRect: rect, waveYForce: force, twoDirection:true)
            pathes.append(path)
        }
        
        return self.animationGroupForWavesPathes(pathes: pathes.reversed(), groupDuration: duration)
    }
    
    private func blobWavePath(inRect rect: CGRect, waveYForce:CGFloat, twoDirection:Bool) -> UIBezierPath {
        let blobCenter = self.updateBlobCenter(inRect: rect)
        return self.blobWavePath(inRect: rect, blobCenter: blobCenter, waveYForce: waveYForce, twoDirection: twoDirection)
    }
    
    private func blobWavePath(inRect rect: CGRect, blobCenter:CGPoint, waveYForce:CGFloat, twoDirection:Bool) -> UIBezierPath {
        let blobCurves = self.blobCurves(inRect: rect, blobCenter: blobCenter, verticalDeformation: waveYForce, twoDirection: twoDirection)
        
        let resultPath = UIBezierPath()
        resultPath.move(to: blobCurves.leftTop.start)
        
        resultPath.addCurve(to: blobCurves.leftTop.end,
                            controlPoint1: blobCurves.leftTop.control1,
                            controlPoint2: blobCurves.leftTop.control2)
        
        resultPath.addCurve(to: blobCurves.leftBottom.end,
                            controlPoint1: blobCurves.leftBottom.control1,
                            controlPoint2: blobCurves.leftBottom.control2)
        
        resultPath.addCurve(to: blobCurves.rightBottom.end,
                            controlPoint1: blobCurves.rightBottom.control1,
                            controlPoint2: blobCurves.rightBottom.control2)
        
        resultPath.addCurve(to: blobCurves.rightTop.end,
                            controlPoint1: blobCurves.rightTop.control1,
                            controlPoint2: blobCurves.rightTop.control2)
        
        resultPath.close()
        return resultPath
    }
    
    private func blobCurves(inRect rect: CGRect, blobCenter:CGPoint, verticalDeformation:CGFloat, twoDirection:Bool) -> BlobCurves {
        let controlPointsRadius = blobRadius / 2
        
        var topJoinPointDisplacement:CGFloat = 0
        var bottomJoinPointDisplacement:CGFloat = 0
        if verticalDeformation > 0 {
            bottomJoinPointDisplacement = verticalDeformation
            topJoinPointDisplacement = twoDirection ? verticalDeformation / 2 : 0
        } else {
            bottomJoinPointDisplacement = twoDirection ? verticalDeformation / 2 : 0
            topJoinPointDisplacement = verticalDeformation
        }
        
        let leftPoint = CGPoint(x:blobCenter.x - blobRadius, y:blobCenter.y)
        let rightPoint = CGPoint(x:blobCenter.x + blobRadius, y:blobCenter.y)
        let bottomPoint = CGPoint(x:blobCenter.x, y:blobCenter.y + blobRadius + bottomJoinPointDisplacement)
        let topPoint = CGPoint(x: blobCenter.x, y: blobCenter.y - blobRadius + topJoinPointDisplacement)
        
        let leftTopControlPoint1 = CGPoint(x: topPoint.x - controlPointsRadius, y: topPoint.y)
        let leftTopControlPoint2 = CGPoint(x: leftPoint.x, y: leftPoint.y - controlPointsRadius)
        
        let leftBottomControlPoint1 = CGPoint(x: leftPoint.x, y: leftPoint.y + controlPointsRadius)
        let leftBottomControlPoint2 = CGPoint(x: bottomPoint.x - controlPointsRadius, y: bottomPoint.y)
        
        let rigthBottomControlPoint1 = CGPoint(x: bottomPoint.x + controlPointsRadius, y: bottomPoint.y)
        let rigthBottomControlPoint2 = CGPoint(x: rightPoint.x, y: rightPoint.y + controlPointsRadius)
        
        let rigthTopControlPoint1 = CGPoint(x: rightPoint.x, y: rightPoint.y - controlPointsRadius)
        let rigthTopControlPoint2 = CGPoint(x: topPoint.x + controlPointsRadius, y: topPoint.y)
        
        let leftTopCurve = BezierCurve(topPoint, leftPoint, leftTopControlPoint1, leftTopControlPoint2)
        let leftBottomCurve = BezierCurve(leftPoint, bottomPoint, leftBottomControlPoint1, leftBottomControlPoint2)
        let rightTopCurve = BezierCurve(rightPoint, topPoint, rigthTopControlPoint1, rigthTopControlPoint2)
        let rightBottomCurve = BezierCurve(bottomPoint, rightPoint, rigthBottomControlPoint1, rigthBottomControlPoint2)
        return BlobCurves(leftTopCurve, leftBottomCurve, rightTopCurve, rightBottomCurve)
    }
    
    
    private func updateMassivePath(inRect rect: CGRect) -> UIBezierPath {
        let liquidHeight = liquidDepletionHeight(inRect: rect)
        return massiveWavePath(inRect:rect, liquidHeight:liquidHeight, waveHeight:0, recessing:false)
    }
    
    private func compressionPrecontactBlobPath(inRect rect: CGRect) -> UIBezierPath {
        let liquidHeight = liquidDepletionHeight(inRect: rect)
        let blobCenterX = rect.width / 2
        let blobCenterY = liquidHeight + blobRadius
        let blobCenter = CGPoint(x: blobCenterX, y: blobCenterY)
        return blobWavePath(inRect: rect, blobCenter: blobCenter, waveYForce: compressingBlobTension, twoDirection:false)
    }
    
    private func compressionStabilisationInitialPath(inRect rect: CGRect)  -> UIBezierPath {
        let liquidHeight = liquidDepletionHeight(inRect: rect)
        let blobCenterY = liquidHeight + blobRadius
        let blobCenterX = rect.width / 2
        
        let blobCenter = CGPoint(x: blobCenterX, y: blobCenterY)
        
        let blobCurves = self.blobCurves(inRect: rect,
                                         blobCenter: blobCenter,
                                         verticalDeformation: compressingBlobTension,
                                         twoDirection: false)
        var leftOuterCurve = blobCurves.leftTop
        leftOuterCurve.start = CGPoint(x: leftOuterCurve.end.x * 2 - leftOuterCurve.start.x, y: leftOuterCurve.start.y)
        var rightOuterCurve = blobCurves.rightTop
        rightOuterCurve.end = CGPoint(x: rightOuterCurve.start.x * 2 - rightOuterCurve.end.x, y: rightOuterCurve.end.y)
        
        let resultPath = UIBezierPath()
        resultPath.move(to: CGPoint.zero)
        
        resultPath.addLine(to: CGPoint(x:0, y:liquidHeight))
        resultPath.addLine(to: leftOuterCurve.start)
        
        resultPath.addCurve(to: leftOuterCurve.end,
                            controlPoint1: leftOuterCurve.control1,
                            controlPoint2: leftOuterCurve.control2)
        
        resultPath.addCurve(to: blobCurves.leftBottom.end,
                            controlPoint1: blobCurves.leftBottom.control1,
                            controlPoint2: blobCurves.leftBottom.control2)
        
        // Right curve calculates semetrically to left, but draws from left to right instead semetrically right to left
        // By this reason control points should be swiped
        
        resultPath.addCurve(to: blobCurves.rightBottom.end,
                            controlPoint1: blobCurves.rightBottom.control1,
                            controlPoint2: blobCurves.rightBottom.control2)
        
        resultPath.addCurve(to: rightOuterCurve.end,
                            controlPoint1: rightOuterCurve.control1,
                            controlPoint2: rightOuterCurve.control2)
        
        resultPath.addLine(to: CGPoint(x:rect.width, y:liquidHeight))
        resultPath.addLine(to: CGPoint(x:rect.width, y:0))
        
        resultPath.close()
        return resultPath
    }
    
    private func compressionStabilisationPrewavePath(inRect rect: CGRect)  -> UIBezierPath {
        let waveCurves = massiveWaveCurves(inRect: rect,
                                           liquidHeight: rect.height,
                                           waveHeight: compressingInitialWaveForce,
                                           recessing: true)
        
        let leftCorner = CGPoint(x:0, y:rect.height)
        let rightCorner = CGPoint(x:rect.width, y:rect.height)
        
        let leftInnerPoint1X = waveCurves.left.end.x + blobRadius
        let leftInnerPoint1 = CGPoint(x: leftInnerPoint1X, y: waveCurves.left.end.y)
        let rightInnerPoint1X = waveCurves.right.start.x - blobRadius
        let rightInnerPoint1 = CGPoint(x: rightInnerPoint1X, y: waveCurves.right.start.y)

        let resultPath = UIBezierPath()
        resultPath.move(to: CGPoint.zero)
        
        resultPath.addLine(to: leftCorner)
        resultPath.addLine(to: waveCurves.left.start)
        
        resultPath.addCurve(to: waveCurves.left.end,
                            controlPoint1: waveCurves.left.control1,
                            controlPoint2: waveCurves.left.control2)
        
        resultPath.addCurve(to: waveCurves.left.end,
                            controlPoint1: leftInnerPoint1,
                            controlPoint2: waveCurves.left.end)
        
        // Right curve calculates semetrically to left, but draws from left to right instead semetrically right to left
        // By this reason control points should be swiped
        
        resultPath.addCurve(to: waveCurves.right.start,
                            controlPoint1: waveCurves.right.start,
                            controlPoint2: rightInnerPoint1)
        
        resultPath.addCurve(to: waveCurves.right.end,
                            controlPoint1: waveCurves.right.control2,
                            controlPoint2: waveCurves.right.control1)
        
        
        resultPath.addLine(to: rightCorner)
        resultPath.addLine(to: CGPoint(x:rect.width, y:0))
        
        resultPath.close()
        return resultPath
    }
    
//MARK: Utils methods
    
    private func heightDeprivation(inRect rect: CGRect) -> CGFloat {
        let blobBulk = CGFloat(M_PI) * blobRadius * blobRadius
        return blobBulk * blobBulkCoeffectient / rect.width
    }
    
    private func liquidDepletionHeight(inRect rect: CGRect) -> CGFloat {
        return rect.height - heightDeprivation(inRect: rect)
    }
    
    private func updateBlobCenter(inRect rect: CGRect) -> CGPoint {
        let heightDeprivation = self.heightDeprivation(inRect: rect)
        let blobDistance = blobRadius * blobDestinationCoeffecient
        let blobCenterY = rect.height - heightDeprivation + blobDistance
        let blobCenterX = rect.width / 2
        
        return CGPoint(x:blobCenterX, y:blobCenterY)
    }
    
    private func animationGroupForWavesPathes(pathes:Array<UIBezierPath>, groupDuration:CFTimeInterval) -> CAAnimationGroup {
        var animations = Array<CABasicAnimation>()
        
        var tactsAmount:Int = 0
        for iterator in 1...pathes.count - 1 {
            tactsAmount += iterator
        }
        let tactDuration = CGFloat(groupDuration) / CGFloat(tactsAmount)
        
        for iterator in 1...(pathes.count - 1) {
            let animationDuration = CGFloat(pathes.count - iterator) * tactDuration
            let animation = CABasicAnimation(keyPath: "path")
            animation.beginTime = animations.last != nil ? animations.last!.beginTime + animations.last!.duration : 0
            animation.duration = CFTimeInterval(animationDuration)
            animation.fromValue = pathes[iterator - 1].cgPath
            animation.toValue = pathes[iterator].cgPath
            animations.append(animation)
        }
        
        let group = CAAnimationGroup()
        group.animations = animations
        group.duration = CFTimeInterval(groupDuration)
        return group
    }
    
    private func showPhaseLayer (layer:CALayer) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        pullLayer.isHidden = true
        updateLayer.isHidden = true
        compressingLayer.isHidden = true
        
        layer.isHidden = false
        CATransaction.commit()
    }
    
    private func restartLayerAnimation (layer:CALayer) {
        layer.speed = 1.0
        layer.timeOffset = 0.0
        layer.beginTime = 0.0
        layer.beginTime = layer.convertTime(CACurrentMediaTime(), to: nil)
    }
    
//MARK: Phases layers initialisation
    private func initPullLayer () {
        let pullInitialPath = self.pullInitialPath(bounds)
        let pullFinalPath = self.pullFinalPath(bounds)
        let wavesDuration = pullReleaseDuration - pullReleasePrewaveDuration
        let releaseWavesAnimationGroup = massiveWaves(rect: bounds,
                                                      amount: pullReleaseWavesAmount,
                                                      initialForce: pullReleaseInitialWaveForce,
                                                      initialRecessin: true,
                                                      duration: wavesDuration,
                                                      liquidHeight: bounds.height)
        
        pullTensionLayer = CAShapeLayer()
        pullTensionLayer.path = pullInitialPath.cgPath
        pullTensionLayer.fillColor = fillColor?.cgColor
        pullTensionLayer.strokeColor = strokeColor?.cgColor
        pullLayer.addSublayer(pullTensionLayer)
        
        let pullTensionAnimation = CABasicAnimation(keyPath: "path")
        pullTensionAnimation.duration = 1.0
        pullTensionAnimation.fromValue = pullInitialPath.cgPath
        pullTensionAnimation.toValue = pullFinalPath.cgPath
        pullTensionLayer.add(pullTensionAnimation, forKey:nil)
        
        pullReleaseLayer = CAShapeLayer()
        pullReleaseLayer.path = pullInitialPath.cgPath
        pullReleaseLayer.fillColor = fillColor?.cgColor
        pullReleaseLayer.strokeColor = strokeColor?.cgColor
        pullLayer.addSublayer(pullReleaseLayer)
        
        let releasePrewaveAnimation = CABasicAnimation(keyPath: "path")
        releasePrewaveAnimation.duration = pullReleasePrewaveDuration
        releasePrewaveAnimation.isRemovedOnCompletion = false
        releasePrewaveAnimation.fromValue = pullFinalPath.cgPath
        releasePrewaveAnimation.toValue = pullInitialPath.cgPath
        
        releaseWavesAnimationGroup.beginTime = pullReleasePrewaveDuration
        
        let releaseAnimationGroup = CAAnimationGroup()
        releaseAnimationGroup.animations = [releasePrewaveAnimation,releaseWavesAnimationGroup]
        releaseAnimationGroup.duration = pullReleaseDuration
        releaseAnimationGroup.isRemovedOnCompletion = false
        pullReleaseLayer.add(releaseAnimationGroup, forKey:nil)
        pullReleaseLayer.isHidden = true
        
        pullTensionLayer.speed = 0
        pullReleaseLayer.speed = 0
        
        layer.addSublayer(pullLayer)
    }
    
    private func initUpdateLayer () {
        
        let stabilisationDuration = preparationPhaseDuration - preparationPrewaveDuration
        
        // Upper massive configuration
        let massiveInitialPath = self.preparationMassiveInitialPath(bounds)
        let massiveWavesGroup = self.massiveWaves(rect: bounds,
                                                  amount: preparationWavesAmount,
                                                  initialForce: blobRadius / 2,
                                                  initialRecessin: true,
                                                  duration: stabilisationDuration)
        
        let massiveLayer = CAShapeLayer()
        massiveLayer.fillColor = fillColor?.cgColor
        massiveLayer.strokeColor = strokeColor?.cgColor
        updateLayer.addSublayer(massiveLayer)
        
        let massiveRecessingAnimation = CABasicAnimation(keyPath: "path")
        massiveRecessingAnimation.duration = preparationPrewaveDuration
        massiveRecessingAnimation.fromValue = massiveInitialPath.cgPath
        let firstMassiveWave = massiveWavesGroup.animations!.first as! CABasicAnimation
        massiveRecessingAnimation.toValue = firstMassiveWave.fromValue
        
        massiveWavesGroup.beginTime = massiveRecessingAnimation.beginTime + massiveRecessingAnimation.duration
        
        let massiveAnimationGroup = CAAnimationGroup()
        massiveAnimationGroup.animations = [massiveRecessingAnimation, massiveWavesGroup]
        massiveAnimationGroup.duration = massiveWavesGroup.beginTime + massiveWavesGroup.duration
        massiveAnimationGroup.fillMode = kCAFillModeForwards
        massiveAnimationGroup.isRemovedOnCompletion = false
        massiveLayer.add(massiveAnimationGroup, forKey: nil)
        
        // Blob configuration
        let blobInitialPath = self.preparationBlobPath(inRect: bounds)
        let blobWavesGroup = self.preparationBlobWaves(rect: bounds,
                                                       amount: preparationWavesAmount,
                                                       initialForce: blobRadius / 2,
                                                       duration: stabilisationDuration)
        
        updateBlobLayer = CAShapeLayer()
        updateBlobLayer.fillColor = fillColor?.cgColor
        updateBlobLayer.strokeColor = strokeColor?.cgColor
        updateLayer.addSublayer(updateBlobLayer)
        
        let blobDropAnimation = CABasicAnimation(keyPath: "path")
        blobDropAnimation.duration = preparationPrewaveDuration
        blobDropAnimation.fromValue = blobInitialPath.cgPath
        let firstBlobWave = blobWavesGroup.animations!.first as! CABasicAnimation
        blobDropAnimation.toValue = firstBlobWave.fromValue

        blobWavesGroup.beginTime = blobDropAnimation.beginTime + blobDropAnimation.duration
        
        let blobAnimationGroup = CAAnimationGroup()
        blobAnimationGroup.animations = [blobDropAnimation, blobWavesGroup]
        blobAnimationGroup.duration = blobWavesGroup.duration + blobWavesGroup.beginTime
        blobAnimationGroup.fillMode = kCAFillModeForwards
        blobAnimationGroup.isRemovedOnCompletion = false
        
        preparationBlobAnimation = blobAnimationGroup
        
        updateLayer.speed = 0
        layer.addSublayer(updateLayer)
    }
    
    private func liquidPeparationCompletion () {
        let updateBlobCenter = self.updateBlobCenter(inRect: bounds)
        let activityWrapperFrame = CGRect(x: updateBlobCenter.x - blobRadius * activitySizeCoeffecient,
                                   y: updateBlobCenter.y - blobRadius * activitySizeCoeffecient,
                                   width: blobRadius * 2 * activitySizeCoeffecient,
                                   height: blobRadius * 2 * activitySizeCoeffecient)
        activityWrapper.frame = activityWrapperFrame
        
        let activityFrame = CGRect(origin: CGPoint.zero, size: activityWrapperFrame.size)
        activityIndicatorView?.frame = activityFrame
       
        let activityPresentationAnimation = CABasicAnimation(keyPath: "opacity")
        activityPresentationAnimation.duration = preparationActivityPresentationDuration
        activityPresentationAnimation.fromValue = 0
        activityPresentationAnimation.toValue = 1
        activityPresentationAnimation.isRemovedOnCompletion = false
        
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            self.activityWrapper.layer.opacity = 1
            self.delegate?.preparationDidFinish(refreshView: self)
            self.activityIndicatorView?.startAnimating()
        }
        
        activityWrapper.layer.add(activityPresentationAnimation, forKey:nil)
        CATransaction.commit()
    }
    
    private func initCompressingLayer() {
        let liquidDepletionHeight = self.liquidDepletionHeight(inRect: bounds)
        
        // Massive configuration
        let massiveInitialPath = massiveWavePath(inRect: bounds,
                                                 liquidHeight: liquidDepletionHeight,
                                                 waveHeight: 0,
                                                 recessing: false)
        let stabilisationInitialPath = compressionStabilisationInitialPath(inRect: bounds)
        let stabilisationPrevawePath = compressionStabilisationPrewavePath(inRect: bounds)
        let stabilisationDuration = compressingPhaseDuration - compressingPrestabilisationDuration - compressingPrecontactDuration
        let stabilisationGroup = massiveWaves(rect: bounds,
                                              amount: compressingWavesAmount,
                                              initialForce: compressingInitialWaveForce,
                                              initialRecessin: true,
                                              duration: stabilisationDuration,
                                              liquidHeight:frame.height)
        
        compressingMassiveLayer = CAShapeLayer()
        compressingMassiveLayer.path = massiveInitialPath.cgPath
        compressingMassiveLayer.fillColor = fillColor?.cgColor
        compressingMassiveLayer.strokeColor = strokeColor?.cgColor
        compressingLayer.addSublayer(compressingMassiveLayer)
        
        let massiveRecessingAnimation = CABasicAnimation(keyPath: "path")
        massiveRecessingAnimation.beginTime = compressingPrecontactDuration
        massiveRecessingAnimation.duration = compressingPrestabilisationDuration
        massiveRecessingAnimation.fromValue = stabilisationInitialPath.cgPath
        massiveRecessingAnimation.toValue = stabilisationPrevawePath.cgPath
        
        stabilisationGroup.beginTime = massiveRecessingAnimation.beginTime + massiveRecessingAnimation.duration
        
        let massiveAnimationGroup = CAAnimationGroup()
        massiveAnimationGroup.animations = [massiveRecessingAnimation, stabilisationGroup]
        massiveAnimationGroup.duration = stabilisationGroup.beginTime + stabilisationGroup.duration
        massiveAnimationGroup.fillMode = kCAFillModeForwards
        massiveAnimationGroup.isRemovedOnCompletion = false
        compressingMassiveAnimation = massiveAnimationGroup
        
        // Blob configuration
        let blobInitialPath = blobWavePath(inRect: bounds, waveYForce: 0, twoDirection:true)
        let blobPrecontactPath = compressionPrecontactBlobPath(inRect: bounds)
        
        let blobLayer = CAShapeLayer()
        blobLayer.fillColor = fillColor?.cgColor
        blobLayer.strokeColor = strokeColor?.cgColor
        compressingLayer.addSublayer(blobLayer)
        
        let blobDropAnimation = CABasicAnimation(keyPath: "path")
        blobDropAnimation.duration = compressingPrecontactDuration
        blobDropAnimation.fromValue = blobInitialPath.cgPath
        blobDropAnimation.toValue = blobPrecontactPath.cgPath
        blobDropAnimation.isRemovedOnCompletion = false
        blobLayer.add(blobDropAnimation, forKey:nil)
        
        compressingLayer.speed = 0
        
        layer.addSublayer(compressingLayer)
    }
    
    override func layoutSubviews() {
        if !isLayersInit {
            initPullLayer()
            initUpdateLayer()
            initCompressingLayer()
            
            showPhaseLayer(layer: pullLayer)
            isLayersInit = true
        }
        
        if activityWrapper.superview == nil {
            self.addSubview(activityWrapper)
            activityWrapper.layer.opacity = 0
        }

        super.layoutSubviews()
    }
    
// MARK: Control methods
    
    open override func setPullProgress(progress: CGFloat) {
        if pullLayer.isHidden {
            showPhaseLayer(layer: pullLayer)
        }
        
        if pullTensionLayer.isHidden {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            pullTensionLayer.isHidden = false
            pullReleaseLayer.isHidden = true
            CATransaction.commit()
        }
        
        var localisedProgress = progress < 0 ? 0 : progress
        localisedProgress = localisedProgress > 1 ? 1 : localisedProgress
        pullTensionLayer.timeOffset = CFTimeInterval(localisedProgress)
    }
    
    open override func releasePull() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        pullTensionLayer.isHidden = true
        pullReleaseLayer.isHidden = false
        CATransaction.commit()
        
        restartLayerAnimation(layer: pullReleaseLayer)
        let pullProgress = pullTensionLayer.timeOffset
        pullReleaseLayer.timeOffset = pullReleaseDuration * (1 - pullProgress)
    }
    
    open override func startUpdateAnimation() {
        if updateLayer.isHidden {
            showPhaseLayer(layer: updateLayer)
        }
        
        activityIndicatorView?.reset()
        
        updateBlobLayer.removeAllAnimations()
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            if self.activityIndicatorView != nil {
                self.liquidPeparationCompletion()
            }
        }
        
        // Key will not be used for search animation. By this reason key isn't a constant. But animations with nil key removes from layer even with isRemovedOnCompletion seted to false.
        updateBlobLayer.add(preparationBlobAnimation, forKey: "preparationBlobAnimation")
        CATransaction.commit()
        
        restartLayerAnimation(layer: updateLayer)
    }
    
    open override func startCompressingAnimation() {
        if compressingLayer.isHidden {
            showPhaseLayer(layer: compressingLayer)
        }
        
        activityIndicatorView?.stopAnimating()
        
        let activityHidingAnimation = CABasicAnimation(keyPath: "opacity")
        activityHidingAnimation.duration = compressingActivityHidingDuration
        activityHidingAnimation.fromValue = 1
        activityHidingAnimation.toValue = 0
        activityHidingAnimation.isRemovedOnCompletion = false
        
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            self.compressingActivityHidenCompleted()
        }
        
        // Key will not be used for search animation. By this reason key isn't a constant. But animations with nil key removes from layer even with isRemovedOnCompletion seted to false.
        activityWrapper.layer.add(activityHidingAnimation, forKey: "activityHidingAnimation")
        CATransaction.commit()
        
        restartLayerAnimation(layer: compressingLayer)
        compressingLayer.speed = 0
    }
    
    private func compressingActivityHidenCompleted () {
        activityWrapper.layer.opacity = 0
        
        compressingMassiveLayer.removeAllAnimations()
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            self.delegate?.compressingDidFinish(refreshView: self)
        }
        
        // Key will not be used for search animation. By this reason key isn't a constant. But animations with nil key removes from layer even with isRemovedOnCompletion seted to false.
        compressingMassiveLayer.add(compressingMassiveAnimation, forKey: "compressingMassiveAnimation")
        CATransaction.commit()
        
        restartLayerAnimation(layer: compressingLayer)
    }
}
