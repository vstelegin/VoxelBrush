//
//  VoxelCursor.swift
//  VoxelBrush
//
//  Created by Chase on 06/09/2019.
//  Copyright © 2019 ViatcheslavTelegin. All rights reserved.
//

import Foundation
import SceneKit

class VoxelCursor{
    
    class func createModel() -> SCNNode{
        guard let cursorScene = SCNScene(named: "3DModels.scnassets/cursor.scn") else {
            print ("Couldn't load cursor scene")
            return SCNNode()
        }
        
        let node = SCNNode()
        node.addChildNode(cursorScene.rootNode.childNodes[0])
        node.scale = SCNVector3(0.1)
        return node
    }
}
