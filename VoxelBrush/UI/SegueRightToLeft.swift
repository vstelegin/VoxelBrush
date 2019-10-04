//
//  SegueFromRight.swift
//  VoxelBrush
//
//  Created by Chase on 30/09/2019.
//  Copyright © 2019 ViatcheslavTelegin. All rights reserved.
//

import Foundation
import UIKit
class SegueRightToLeft: UIStoryboardSegue{

    override func perform() {
        let src = self.source
        let dst = self.destination

        src.view.superview?.insertSubview(dst.view, aboveSubview: src.view)
        dst.view.transform = CGAffineTransform(translationX: -src.view.frame.size.width, y: 0)

        UIView.animate(withDuration: 0.5, delay: 0.0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
            dst.view.transform = CGAffineTransform(translationX: 0, y: 0)
        }) { (finished) in
            src.present(dst, animated: false, completion: nil)
        }
    }
}
