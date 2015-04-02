//
//  GpsLoadingView.swift
//  capa
//
//  Created by 秦 道平 on 15/3/23.
//  Copyright (c) 2015年 秦 道平. All rights reserved.
//

import UIKit

///GPS 显示状态
class GpsLoadingView: UIView {
    typealias onTouched = ()->()
    var onGpsTouched:onTouched?
    enum State:Int{
        case stop=0,run=1,completed=2
    }
    var state:State!{
        didSet{
            switch state!{
            case .stop:
                if let tapGesture = tapGesture {
                    self.removeGestureRecognizer(tapGesture)
                }
                stop()
            case .run:
                if let tapGesture = tapGesture {
                    self.removeGestureRecognizer(tapGesture)
                }
                run()
            case .completed:
                ///完成之后，清除所有动画，设置动作
                self.layer.sublayers?.removeAll(keepCapacity: false)
                let layer =
                    circularLayerAtCenter(CGPointMake(CGRectGetMidX(self.bounds),CGRectGetMidY(self.bounds)),
                        radius:5.0)
                self.layer.addSublayer(layer)
                tapGesture = UITapGestureRecognizer(target: self, action: "onTapGesture:")
                self.addGestureRecognizer(tapGesture!)
            }
        }
    }
    var tapGesture : UITapGestureRecognizer?
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    private func setup(){
        state = .run
    }
    private func run(){
        let layer_1 = loadingLayerAtCenter(CGPointMake(CGRectGetMidX(self.bounds),CGRectGetMidY(self.bounds)), radius: 5.0)
        let layer_2 = loadingLayerAtCenter(CGPointMake(CGRectGetMidX(self.bounds),CGRectGetMidY(self.bounds)), radius: 3.0)
        let layer_3 = loadingLayerAtCenter(CGPointMake(CGRectGetMidX(self.bounds),CGRectGetMidY(self.bounds)), radius: 1.0)
        self.layer.addSublayer(layer_1)
        self.layer.addSublayer(layer_2)
        self.layer.addSublayer(layer_3)
    }
    private func stop(){
        self.layer.sublayers?.removeAll(keepCapacity: false)
    }
    ///创建一个圆圆的图层
    func circularLayerAtCenter(center:CGPoint,radius:CGFloat)->CAShapeLayer{
        let rect = CGRectMake(center.x - radius, center.y - radius, radius * 2, radius * 2)
        let layer = CAShapeLayer()
        layer.path = CGPathCreateWithEllipseInRect(rect, nil)
        layer.bounds = rect
        layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        layer.position = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect))
        layer.fillColor = UIColor.whiteColor().CGColor
        layer.opacity = 0.6
        return layer
    }
    ///创建一个动画的圆圆的图层
    func loadingLayerAtCenter(center:CGPoint,radius:CGFloat) -> CAShapeLayer{
        let layer = circularLayerAtCenter(center, radius: radius)
        let scale_transform = CATransform3DMakeScale(2.0, 2.0, 2.0)
        
        CATransaction.begin()
        let group = CAAnimationGroup()
        group.duration = 1.0
        group.fillMode = kCAFillModeForwards
        group.beginTime = layer.convertTime(CACurrentMediaTime(), fromLayer: nil)
        group.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        group.removedOnCompletion = false
        group.repeatCount = HUGE
        
        let animation_scale = CABasicAnimation(keyPath: "transform")
        animation_scale.fromValue = NSValue(CATransform3D: CATransform3DIdentity)
        animation_scale.toValue = NSValue(CATransform3D: scale_transform)
        
        let animation_opacity = CABasicAnimation(keyPath: "opacity")
        animation_opacity.fromValue = NSNumber(float: 0.6)
        animation_opacity.toValue = NSNumber(float: 0.0)
        
        group.animations = [animation_scale,animation_opacity]
        layer.addAnimation(group, forKey: "loading-animatiopn")
        CATransaction.commit()
        return layer
    }
    ///只有定位完成后，触摸时才会调用
    func onTapGesture(gesture:UITapGestureRecognizer){
        if let onGpsTouched = onGpsTouched {
            onGpsTouched()
        }
    }
}
