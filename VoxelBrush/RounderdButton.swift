//
//  CustomButton.swift
//  VoxelBrush
//
//  Created by Chase on 03/09/2019.
//  Copyright © 2019 ViatcheslavTelegin. All rights reserved.
//

import UIKit

@IBDesignable
class RounderdButton: UIButton {
    
    @IBInspectable public var cornerRadius: CGFloat = 8 {
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
        setup()
    }
    
    func setup() {
        backgroundColor = tintColor
        layer.cornerRadius = cornerRadius
        clipsToBounds = true
    }
    
    override var isEnabled: Bool {
        didSet {
            backgroundColor = isEnabled ? tintColor : .gray
        }
    }
}
