//
//  GCD.swift
//  VoxelBrush
//
//  Created by Chase on 18/09/2019.
//  Copyright © 2019 ViatcheslavTelegin. All rights reserved.
//

import Foundation

class GCD{
    let voxelQueue = DispatchQueue(label:"voxel queue", qos: .background , attributes: .concurrent)
    let meshingQueue = DispatchQueue(label: "meshing queue", qos: .background)
    var meshingWorkItem : DispatchWorkItem?
    static let shared = GCD()
}
