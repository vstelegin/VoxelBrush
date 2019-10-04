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
    var voxelDataStored : VoxelData?
    
    var fetchedResultsController : NSFetchedResultsController<VoxelData>!
    var id : Int32 = 1
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
    
    func fetch(_ fecthID: Int32 = -1){
        let fetchRequest : NSFetchRequest<VoxelData> = VoxelData.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        if fecthID != -1 {
            let predicate = NSPredicate(format: "id == %@", DataController.shared.id)
            fetchRequest.predicate = predicate
        }
        fetchedResultsController = NSFetchedResultsController(fetchRequest : fetchRequest, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print ("Fetch request coulnd't be performed")
            return
        }
        guard let voxelDataObjects = fetchedResultsController.fetchedObjects else {
            print ("No Voxel Data objects found")
            return
        }

        guard let voxelDataObject = voxelDataObjects.first else { return }
        
        voxelDataStored = voxelDataObject
    }
    
    func setNewID(){
        if let newID = fetchedResultsController.fetchedObjects?.count {
            id = Int32(newID)
            debugPrint(newID)
        }
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
