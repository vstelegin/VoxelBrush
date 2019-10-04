//
//  BrushViewController+Extensions.swift
//  VoxelBrush
//
//  Created by Chase on 04/10/2019.
//  Copyright © 2019 ViatcheslavTelegin. All rights reserved.
//

import Foundation
import SceneKit


extension BrushViewController {
    func sceneSetup(){
        
        let scene = SCNScene()
        scene.rootNode.addChildNode(SCNNode()) // Mesh Placeholder [0]
        scene.rootNode.addChildNode(SCNNode()) // Cursor Voxel Spheres Placeholder [1]
        
        let plane = SCNNode(geometry: SCNPlane(width: 0.4, height: 0.4))
        plane.eulerAngles = SCNVector3(-CGFloat.pi*0.5,0,0)
        
        voxelGridLocator.node = plane
        
        let brushUImaterial = SCNMaterial()
        brushUImaterial.lightingModel = .constant
        brushUImaterial.transparency = 0.2
        brushUImaterial.diffuse.contents = UIColor.white
        plane.geometry!.firstMaterial = brushUImaterial
        
        plane.addChildNode(SCNNode())
        plane.isHidden = true
        scene.rootNode.addChildNode(plane) // Model Transform Placeholder [2]
        
        voxelMaterial = SCNMaterial()
        voxelMaterial.lightingModel = .physicallyBased
        voxelMaterial.diffuse.contents = UIColor.white
        voxelMaterial.roughness.contents = 0.3
        voxelMaterial.metalness.contents = 1
        brushMaterial = voxelMaterial.copy() as! SCNMaterial
        deleteBrushMaterial = voxelMaterial.copy() as! SCNMaterial
        deleteBrushMaterial.diffuse.contents = UIColor.red
        voxelSphere.firstMaterial = brushMaterial
        voxelEraseSphere.firstMaterial = deleteBrushMaterial
        
        let cursorNode = VoxelCursor.createModel()
        cursorNode.childNodes[0].geometry!.firstMaterial = voxelMaterial
        scene.rootNode.addChildNode(SCNNode()) // Add cursor placeholder [3]
        scene.rootNode.childNodes[3].addChildNode(cursorNode)//Add cursor
        scene.rootNode.childNodes[3].addChildNode(SCNNode(geometry: voxelSphere)) //Add cursor sphere
        scene.rootNode.childNodes[3].childNodes[1].scale = SCNVector3(0)
        
        let symmetryPlane = SCNNode(geometry: SCNPlane(width: 0.004, height: 20.0))
        symmetryPlane.geometry!.firstMaterial = brushUImaterial
        scene.rootNode.addChildNode(SCNNode()) // Symmetry plane placeholder [4]
        scene.rootNode.childNodes[4].isHidden = true
        scene.rootNode.childNodes[4].addChildNode(symmetryPlane)
        scene.rootNode.childNodes[4].childNodes[0].eulerAngles = SCNVector3(0,CGFloat.pi,0)
        scene.rootNode.addChildNode(SCNNode()) // Feauture points node [5]
        scene.rootNode.childNodes[5].isHidden = true
        sceneView.scene = scene
        root = sceneView.scene.rootNode
        
        animateUIAlpha(show: false, 0.0)
        
        SCNTransaction.animationDuration = 0.25
        currentVoxelBrushPreset = VoxelBrushPeresets.shared.spherical()
    }
}
