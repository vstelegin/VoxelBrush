//
//  TrackingIndicatorView.swift
//  VoxelBrush
//
//  Created by Chase on 07/10/2019.
//  Copyright © 2019 ViatcheslavTelegin. All rights reserved.
//

import Foundation
import UIKit
class TrackingIndicatorView : UIView {
    @IBOutlet var trackingIndicatorCenterConstraint : NSLayoutConstraint!
    let offsetValue : CGFloat = 20
   
    var reverse = false

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        debugPrint(offsetValue)
        _ = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: {_ in
            self.reverse = !self.reverse
            self.trackingIndicatorAnimator(self.reverse).startAnimation()
        })
    }
    
    func trackingIndicatorAnimator(_ reverse : Bool?) -> UIViewPropertyAnimator{
        let offsetValue = reverse! ? -self.offsetValue : self.offsetValue
        let animator = UIViewPropertyAnimator(duration: 0.5, curve: .easeOut)
        
        animator.addAnimations {
            self.trackingIndicatorCenterConstraint.constant = offsetValue
            self.layoutIfNeeded()
        }
        return animator
    }
}
