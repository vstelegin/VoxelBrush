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
    let persistentContainer : NSPersistentContainer
    var viewContext : NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    var backgroundContext : NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
    var voxelDataStored : VoxelData!
    static let shared = DataController(modelName: "VoxelData")
    
    init (modelName: String) {
        persistentContainer = NSPersistentContainer(name: modelName)
    }
    
    func configureContexts(){
        viewContext.automaticallyMergesChangesFromParent = true
        backgroundContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }
    
    func load() {
        persistentContainer.loadPersistentStores(completionHandler: {storeDescription, error in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
        })
    }
    
    func save(){
        viewContext.performAndWait {
            if self.viewContext.hasChanges{
                do {
                    try viewContext.save()
                    print ("Data saved")
                } catch {
                    print("Failed to save context")
                }
            }
        }
    }
}
