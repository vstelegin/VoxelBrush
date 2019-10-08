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
    let offsetValue : CGFloat = 20
    @IBOutlet var trackingIndicatorCenterConstraint : NSLayoutConstraint!
    var reverse = false
    required init?(coder: NSCoder) {
        super.init(coder: coder)
//        let timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true, block: {_ in
//            self.trackingIndicatorAnimator()
//        })
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            self.trackingIndicatorAnimator()
            //timer.fire()
        })
        
    }
    
    func trackingIndicatorAnimator(){
        //let offsetValue = reverse! ? -self.offsetValue : self.offsetValue
        let animator1 = UIViewPropertyAnimator(duration: 0.75, curve: .easeInOut){
            self.trackingIndicatorCenterConstraint.constant = self.offsetValue
            self.layoutIfNeeded()
        }
        let animator2 = UIViewPropertyAnimator(duration: 0.75, curve: .easeInOut){
            self.trackingIndicatorCenterConstraint.constant = -self.offsetValue
            self.layoutIfNeeded()
        }
        
        animator1.addCompletion({_ in
            animator2.startAnimation()
        })
        animator2.addCompletion({_ in
            self.trackingIndicatorAnimator()
        })
        animator1.startAnimation()
    }
}


