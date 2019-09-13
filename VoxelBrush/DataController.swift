//
//  DataController.swift
//  VoxelBrush
//
//  Created by Chase on 04/09/2019.
//  Copyright © 2019 ViatcheslavTelegin. All rights reserved.
//

import Foundation
import CoreData

class DataController {
    let persistentContainer = NSPersistentContainer(name: "VoxelData")
    
    static let shared = DataController()
    
}
