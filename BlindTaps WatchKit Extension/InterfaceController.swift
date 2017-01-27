//
//  InterfaceController.swift
//  BlindTaps WatchKit Extension
//
//  Created by Brian Buck on 1/27/17.
//  Copyright © 2017 Brian Buck. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {
    
    var penWidth: CGFloat = 7
    var previousPoint1: CGPoint!
    var previousPoint2: CGPoint!
    var savedImage: UIImage?
    
    @IBOutlet var canvasGroup: WKInterfaceGroup!
    
    func midPoint(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
        return CGPoint(x: (a.x + b.x) * 0.5, y: (a.y + b.y) * 0.5)
    }
    
    func exponentialScale(_ a: CGFloat) -> CGFloat {
        return a >= 0 ? sqrt(a) : -sqrt(abs(a))
    }
    
    func curveThrough(a: CGPoint, b: CGPoint, c: CGPoint, in rect: CGRect, with alphaComponent: CGFloat = 1) -> UIImage {
        let mid2 = midPoint(b, a)
        let mid1 = midPoint(c, b)
        
        UIGraphicsBeginImageContextWithOptions(rect.size, true, 0)
        savedImage?.draw(in: rect)
        let linePath = UIBezierPath()
        linePath.move(to: mid2)
        linePath.addQuadCurve(to: mid1, controlPoint: b)
        UIColor.red.withAlphaComponent(alphaComponent).setStroke()
        linePath.lineWidth = penWidth
        linePath.lineCapStyle = .round
        linePath.stroke()
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    @IBAction func panRecognized(_ sender: AnyObject) {
        guard let panGesture = sender as? WKPanGestureRecognizer else {
            return
        }
        
        let rect = panGesture.objectBounds()
        switch panGesture.state {
        case .began:
            previousPoint1 = panGesture.locationInObject()
            let velocity = panGesture.velocityInObject()
            let multiplier: CGFloat = 1.75
            previousPoint2 = CGPoint(x: previousPoint1.x - exponentialScale(velocity.x) * multiplier,
                                     y: previousPoint1.y - exponentialScale(velocity.y) * multiplier)
            
        case .changed:
            let currentPoint = panGesture.locationInObject()
            let actualImage = curveThrough(a: previousPoint2, b: previousPoint1, c: currentPoint, in: rect)
            savedImage = actualImage
            
            let velocity = panGesture.velocityInObject()
            let projectedPoint = CGPoint(x: currentPoint.x + exponentialScale(velocity.x), y: currentPoint.y + exponentialScale(velocity.y))
            let projectedImage = curveThrough(a: previousPoint1,
                                              b: currentPoint,
                                              c: midPoint(currentPoint, projectedPoint),
                                              in: rect,
                                              with: 0.5)

            canvasGroup.setBackgroundImage(projectedImage)
            
            previousPoint2 = previousPoint1
            previousPoint1 = currentPoint
            
        case .ended:
            let currentPoint = panGesture.locationInObject()
            let image = curveThrough(a: previousPoint2, b: previousPoint1, c: currentPoint, in: rect)
            canvasGroup.setBackgroundImage(image)
            savedImage = image
            playTap()
        default:
            break
        }
    }
    
    @IBAction func resetButtonPressed() {
        savedImage = nil
        canvasGroup.setBackgroundImage(nil)
    }

    func playTap() {
        let interfaceDevice = WKInterfaceDevice.current()
        let dispatchTime: DispatchTime = .now()
        interfaceDevice.play(.start)
        DispatchQueue.main.asyncAfter(deadline: dispatchTime+2.0, execute: {
            interfaceDevice.play(.start)
        })
        DispatchQueue.main.asyncAfter(deadline: dispatchTime+4.0, execute: {
            interfaceDevice.play(.retry)
        })
        DispatchQueue.main.asyncAfter(deadline: dispatchTime+5.0, execute: {
            self.resetButtonPressed()
        })
    }
}
