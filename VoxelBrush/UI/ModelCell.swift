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
    @IBOutlet weak var progressView : UIProgressView!
    @IBOutlet weak var uploadButton : UIButton!
    @IBOutlet weak var activityIndicator : UIActivityIndicatorView!
    var fileURL : URL?
    var collectionViewController : CollectionViewController?
    @IBAction func shareButtonPressed(){
        let activityViewController = UIActivityViewController(activityItems: [fileURL!], applicationActivities: nil)
        collectionViewController?.present(activityViewController, animated: true, completion: nil)
    }
    
    @IBAction func uploadButtonPressed(){
        AWSS3Manager.shared.uploadWithUniqueName(fileUrl: fileURL!, contentType: "", progress: {[weak self](uploadProgress) in
            
            self!.uploadButton.isHidden = true
            self!.activityIndicator.startAnimating()
            self!.progressView.progress = Float(uploadProgress)},
            
            completion: {[weak self](uploadedFileUrl, error) in
                
                //guard let strongSelf = self else { return }
                if let finalPath = uploadedFileUrl as? String {
                    let pasteboard = UIPasteboard.general
                    pasteboard.string = finalPath
                    self!.activityIndicator.stopAnimating()
                    let alert = UIAlertController(title: "Uploaded", message: "Link to the uploaded file copied to the clipboard", preferredStyle: .alert)

                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

                    self!.collectionViewController!.present(alert, animated: true)
                    
                } else {
                    let alert = UIAlertController(title: "Failed to upload", message: "", preferredStyle: .alert)

                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

                    debugPrint("\(String(describing: error?.localizedDescription))")
                }
            }
        )
    }
}
