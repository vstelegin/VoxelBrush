//
//  CustomButton.swift
//  VoxelBrush
//
//  Created by Chase on 03/09/2019.
//  Copyright © 2019 ViatcheslavTelegin. All rights reserved.
//

import UIKit

@IBDesignable
class RoundedButton: UIButton {
    
    var size : CGPoint?
    @IBInspectable public var cornerRadius: CGFloat = 8 {
        didSet {
            self.setNeedsLayout()
            setup()
        }
    }
    
    @IBInspectable public var regularBorderWidth: CGFloat = 0 {
        didSet {
            self.setNeedsLayout()
            setup()
        }
    }
    
    @IBInspectable public var highlightedBorderWidth: CGFloat = 2
    
    @IBInspectable public var highlightedScale : CGPoint = CGPoint(x: 10,y: 10)
    
    @IBInspectable public var borderColor : UIColor = UIColor.white{
        didSet {
            self.setNeedsLayout()
            setup()
        }
    }
    
    @IBInspectable public var highlightColor : UIColor? {
        didSet {
            self.setNeedsLayout()
            setup()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        size = CGPoint(x: frame.size.width, y: frame.size.height)
        setup()
    }
    
    func setup() {
        backgroundColor = tintColor
        layer.cornerRadius = cornerRadius
        
        layer.borderColor = UIColor.white.cgColor
        clipsToBounds = false
        layer.borderColor = borderColor.cgColor
        layer.borderWidth = regularBorderWidth
    }
    
    func highlightTint(_ on : Bool = false) {
        
        if let highlightColor = self.highlightColor?.cgColor {
            let tintAnimator = UIViewPropertyAnimator(duration: 0.25, curve: .easeInOut, animations: {
                self.layer.backgroundColor = on ? highlightColor : self.tintColor.cgColor
            })
            tintAnimator.startAnimation()
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            guard isHighlighted != oldValue else {return}
            
            if isHighlighted {
                highlightTint(true)
            }
            
            let sizeAnimator = UIViewPropertyAnimator(duration: 0.1, curve: .easeInOut) {
                let newSize = self.isHighlighted ? self.size! + self.highlightedScale : self.size!
                self.layer.bounds = CGRect(x: 0,y: 40, width: newSize.x, height: newSize.y)
                self.updateConstraints()
            }

            let borderWidthAnimation = CABasicAnimation(keyPath: "borderWidth")
            borderWidthAnimation.fromValue = self.isHighlighted ? regularBorderWidth : highlightedBorderWidth
            borderWidthAnimation.toValue = self.isHighlighted ? highlightedBorderWidth : regularBorderWidth
            borderWidthAnimation.duration = 0.1
            layer.borderWidth = self.isHighlighted ? highlightedBorderWidth : regularBorderWidth
            layer.add(borderWidthAnimation, forKey: "borderWidth")
            
            sizeAnimator.startAnimation()
            
        }
    }
    
}
