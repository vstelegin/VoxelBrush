//
//  RoundedView.swift
//  VoxelBrush
//
//  Created by Chase on 03/10/2019.
//  Copyright © 2019 ViatcheslavTelegin. All rights reserved.
//

import Foundation
import UIKit

class RoundedView : UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup() 
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        layer.cornerRadius = 18
    }
}
