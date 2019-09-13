//
//  ScrollableButton.swift
//  VoxelBrush
//
//  Created by Chase on 11/09/2019.
//  Copyright © 2019 ViatcheslavTelegin. All rights reserved.
//

import UIKit

@IBDesignable
class ScrollableButton: RoundedButton {
    var location = CGPoint()
    var locationDifference = Int32()
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {

        let touchLocation = touch.location(in: self)
        let scaleFactor = frame.height * 0.25
        let difference = (location - touchLocation).y / scaleFactor
        locationDifference = Int32(difference)
        if locationDifference != 0 {
            location = touchLocation
        }
        return true
    }
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        location = touch.location(in: self)
        return true
    }
    
}
