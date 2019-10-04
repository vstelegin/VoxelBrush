//
//  DataReceiver.swift
//  VoxelBrush
//
//  Created by Chase on 04/10/2019.
//  Copyright © 2019 ViatcheslavTelegin. All rights reserved.
//

import Foundation
import SceneKit.ModelIO
class DataReceiver{
    var receivedVoxelIndices : Data?
    var receivedBounds : Bounds?
    static let shared = DataReceiver()
    
    func voxelArrayFromReceivedData() -> MDLVoxelArray?{
        guard let receivedVoxelIndices = self.receivedVoxelIndices else {
            return nil
        }
        guard let receivedBounds = self.receivedBounds else {
            return nil
        }
        self.receivedVoxelIndices = nil
        self.receivedBounds = nil
        let bbox = MDLAxisAlignedBoundingBox(maxBounds: vector_float3(receivedBounds.maxBound!), minBounds: vector_float3(receivedBounds.minBound!))
        let receivedArray = MDLVoxelArray(data: receivedVoxelIndices, boundingBox: bbox, voxelExtent: 1)
        return receivedArray
    }
}
