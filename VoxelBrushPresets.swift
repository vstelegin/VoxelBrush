//
//  VoxelBrushPresets.swift
//  VoxelBrush
//
//  Created by Chase on 10/09/2019.
//  Copyright © 2019 ViatcheslavTelegin. All rights reserved.
//

import Foundation
import SceneKit

class VoxelBrushPeresets {
    
    static let shared = VoxelBrushPeresets()
    let sizeRange = Range<Int32>(1...4)
    var size : Int32 = 1 {
        didSet{
            guard sizeRange ~= self.size else{
                self.size = oldValue
                return
            }
        }
    }
    
    func spherical() -> [vector_int3]{
        var positionsArray = [vector_int3]()
        let size2 = self.size * self.size
        let range = -self.size...self.size
        for i in range{
            for j in range{
                for k in range{
                    if i*i + j*j + k*k <= size2 {
                        let index = vector_int3(i,j,k)
                        positionsArray.append(index)
                    }
                }
            }
        }
        return positionsArray
    }
}
