//
//  ModelCell.swift
//  VoxelBrush
//
//  Created by Chase on 02/10/2019.
//  Copyright © 2019 ViatcheslavTelegin. All rights reserved.
//

import Foundation
import UIKit

class ModelCell : UICollectionViewCell {
    @IBOutlet weak var label : UILabel!
    @IBOutlet weak var cellView : RoundedView!
    var fileURL : URL?
    var collectionViewController : CollectionViewController?
    @IBAction func shareButtonPressed(){
        let activityViewController = UIActivityViewController(activityItems: [fileURL!], applicationActivities: nil)
        collectionViewController?.present(activityViewController, animated: true, completion: nil)
    }
}
