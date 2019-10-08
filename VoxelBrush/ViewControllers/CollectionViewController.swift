//
//  BrowseViewController.swift
//  VoxelBrush
//
//  Created by Chase on 30/09/2019.
//  Copyright © 2019 ViatcheslavTelegin. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import CoreData

class CollectionViewController : UIViewController {
    var needsReset : Bool = false
    var isDeleting : Bool = false{
        didSet{
            for cell in collectionView.visibleCells {
                cell.contentView.backgroundColor = isDeleting ? .red : .lightGray
            }
        }
    }
    
    var insertedIndexPaths : [IndexPath]!
    var deletedIndexPaths : [IndexPath]!
    var updatedIndexPaths : [IndexPath]!
    
    @IBOutlet weak var collectionView : UICollectionView!
    @IBOutlet weak var deleteButton : UIButton!
    @IBAction func addNewModel(){
        DataController.shared.setNewID()
        needsReset = true
        backToDrawing()
    }
    
    @IBAction func deleteModels(){
        isDeleting = !isDeleting
        if isDeleting {
            deleteButton.setBackgroundImage(nil, for: .normal)
            deleteButton.setTitle("OK", for: .normal)
            
        } else {
            let image = UIImage(systemName: "trash")
            deleteButton.setBackgroundImage(image, for: .normal)
            deleteButton.setTitle("", for: .normal)
        }
        
    }
    
    func backToDrawing(){
        performSegue(withIdentifier: "unwindToDrawing", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let brushViewController = segue.destination as? BrushViewController {
            if needsReset {
                needsReset = false
                brushViewController.reset()
            } else{
                brushViewController.loadFromStoredVoxelData()   
            }
        }
    }
}

   
extension CollectionViewController : UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return DataController.shared.fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let sections = DataController.shared.fetchedResultsController.sections else {
            return 0
        }
        return sections[section].numberOfObjects
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ModelCell", for: indexPath) as! ModelCell
        let fetchedObject = DataController.shared.fetchedResultsController.object(at: indexPath)
        print ("IndexPath: \(indexPath)")
        cell.collectionViewController = self
        cell.label.text = fetchedObject.title
        cell.fileURL = fetchedObject.url
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let voxelData = DataController.shared.fetchedResultsController.object(at: indexPath)
        if isDeleting {
            DataController.shared.viewContext.delete(voxelData)
            DataController.shared.save()
            
        } else {
            DataController.shared.voxelDataStored = voxelData
            backToDrawing()
        }
    }
}

extension CollectionViewController : NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexPaths = [IndexPath]()
        deletedIndexPaths = [IndexPath]()
        updatedIndexPaths = [IndexPath]()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch (type) {
        case .insert:
            insertedIndexPaths.append(newIndexPath!)
            break
        case .delete:
            deletedIndexPaths.append(indexPath!)
            break
        case .update:
            updatedIndexPaths.append(indexPath!)
            break
            
        default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.performBatchUpdates({() -> Void in
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItems(at: [indexPath])
            }
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItems(at: [indexPath])
            }
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItems(at: [indexPath])
            }
            
        }, completion: nil)
    }
}
