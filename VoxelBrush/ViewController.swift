//
//  ViewController.swift
//  VoxelBrush
//
//  Created by Chase on 28/08/2019.
//  Copyright © 2019 ViatcheslavTelegin. All rights reserved.
//

import UIKit
import ARKit
import SceneKit
import SceneKit.ModelIO
import ModelIO

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var blurView: UIVisualEffectView!
    var trackingStateIsNormal = false {
        didSet {
            guard self.trackingStateIsNormal != oldValue else{
                return
            }
            
            if self.trackingStateIsNormal {
                blurUIAnimator = UIViewPropertyAnimator(duration: 0.25, curve: .easeInOut){
                    self.blurView.effect = nil
                }
                blurUIAnimator?.startAnimation()
            }
            
            else {
                self.blurView.effect = nil
                blurUIAnimator = UIViewPropertyAnimator(duration: 0.25, curve: .easeInOut){
                    self.blurView.effect = UIBlurEffect(style: .dark)
                }
                blurUIAnimator?.startAnimation()
            }
        }
    }
    var cameraInfo = (pos : simd_float3(), dir : simd_float3())
    var blurUIAnimator : UIViewPropertyAnimator?
    
    var voxelMaterial = SCNMaterial()
    var voxelMesh = MDLMesh()
    let voxelArray = MDLVoxelArray()
    let voxelSphere = SCNSphere(radius: 0.015)
    var isDrawing = false
    
    var voxelPositionChanged = false
    var voxelsCentroid = simd_float3()
    var voxelsMinBound = simd_float3(10,10,10)
    var voxelPosition = simd_float3(){
        didSet{
            let difference = voxelPosition - oldValue
            if simd_float3.dot (difference, difference) > 0.00001 {
                voxelPositionChanged = true
                voxelsCentroid = (voxelsCentroid + (voxelPosition + oldValue) * 0.5) * 0.5
                voxelsMinBound = min (voxelsMinBound, voxelPosition)
            } else {
                voxelPositionChanged = false
                voxelPosition = oldValue
            }
        }
    }
    
    
    struct VoxelGridLocator {
        var node : SCNNode?
        var placed = false
    }
    var voxelGridLocator = VoxelGridLocator()
    @IBAction func tap(){
        if trackingStateIsNormal {
            voxelGridLocator.placed = !voxelGridLocator.placed
        }
    }
    @IBAction func voxelsToMesh(){
        guard let voxelMesh = voxelArray.mesh(using: voxelMesh.allocator) else {
            print ("Couldn't create a mesh")
            return
        }

        let node = SCNNode(mdlObject: voxelMesh)
        node.geometry?.firstMaterial = voxelMaterial
        
        //node.position = node.position - SCNVector3(10,10,10)
        let scene = sceneView.scene
        scene.rootNode.childNodes[0].scale = SCNVector3(0.02,0.02,0.02)
        let minBounds = voxelArray.boundingBox.minBounds
        print (minBounds)
        scene.rootNode.childNodes[0].position = SCNVector3(voxelsMinBound - simd_float3(0.03,0.03,0.03))
        scene.rootNode.childNodes[0].geometry = node.geometry
        for child in scene.rootNode.childNodes[1].childNodes {
            child.removeFromParentNode()
        }
//        voxelGridLocator.node?.childNodes[0].geometry = node.geometry
        
        print(voxelMesh.vertexCount)
    }
    
    @IBAction func saveMesh(){
        let asset = MDLAsset(bufferAllocator: voxelMesh.allocator)
        print (MDLAsset.canExportFileExtension("usdz"))
    }
    @IBAction func drawButtonPressed(){
        isDrawing = true
    }
    @IBAction func drawButtonReleased(){
        isDrawing = false
    }
    
    func drawVoxel(){
        
       
        voxelPosition = cameraInfo.pos + cameraInfo.dir*0.4
        
        if voxelPositionChanged {
            let voxelNode = SCNNode(geometry: voxelSphere)
            
            let voxelIndexPosition = ((voxelPosition + simd_float3(50,50,50)) * 50).toVectorInt_3()
            
            let voxelIndex1 = MDLVoxelIndex(voxelIndexPosition.x, voxelIndexPosition.y,voxelIndexPosition.z,0)
            let voxelIndex2 = MDLVoxelIndex(voxelIndexPosition.x + 1, voxelIndexPosition.y,voxelIndexPosition.z,0)
            let voxelIndex3 = MDLVoxelIndex(voxelIndexPosition.x - 1, voxelIndexPosition.y,voxelIndexPosition.z,0)
            let voxelIndex4 = MDLVoxelIndex(voxelIndexPosition.x, voxelIndexPosition.y + 1,voxelIndexPosition.z,0)
            let voxelIndex5 = MDLVoxelIndex(voxelIndexPosition.x, voxelIndexPosition.y - 1,voxelIndexPosition.z,0)
            let voxelIndex6 = MDLVoxelIndex(voxelIndexPosition.x, voxelIndexPosition.y,voxelIndexPosition.z + 1,0)
            let voxelIndex7 = MDLVoxelIndex(voxelIndexPosition.x, voxelIndexPosition.y,voxelIndexPosition.z - 1,0)
            voxelArray.setVoxelAtIndex(voxelIndex1)
            voxelArray.setVoxelAtIndex(voxelIndex2)
            voxelArray.setVoxelAtIndex(voxelIndex3)
            voxelArray.setVoxelAtIndex(voxelIndex4)
            voxelArray.setVoxelAtIndex(voxelIndex5)
            voxelArray.setVoxelAtIndex(voxelIndex6)
            voxelArray.setVoxelAtIndex(voxelIndex7)
            voxelNode.position = SCNVector3(voxelPosition.x, voxelPosition.y, voxelPosition.z)
            let scene = sceneView.scene.rootNode
            scene.childNodes[1].addChildNode(voxelNode)
        }
    }
    
    func updateCameraInfo(){
        guard let pointOfView = self.sceneView.pointOfView else{
            print ("No point of view")
            return
        }
        let orientation = simd_quaternion(pointOfView.orientation.x, pointOfView.orientation.y, pointOfView.orientation.z, pointOfView.orientation.w)
        let direction = orientation.act(simd_float3(0,0,-1))
        cameraInfo.dir = direction
        cameraInfo.pos = simd_float3(pointOfView.position.x, pointOfView.position.y, pointOfView.position.z)
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        //sceneView.debugOptions = [ .showFeaturePoints, .showWorldOrigin ]

        //let timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(debugOutput), userInfo: nil, repeats: true)
        //timer.tolerance = 0.1
        let scene = SCNScene()
        //let light = SCNLight()
        scene.rootNode.addChildNode(SCNNode()) //Mesh Placeholder
        scene.rootNode.addChildNode(SCNNode()) //Voxel Spheres Placeholder
        //scene.rootNode.light = light
        let plane = SCNNode(geometry: SCNPlane(width: 0.4, height: 0.4))
        plane.eulerAngles = SCNVector3(-CGFloat.pi*0.5,0,0)
        
        voxelGridLocator.node = plane
        
        let brushUImaterial = SCNMaterial()
        brushUImaterial.lightingModel = .constant
        brushUImaterial.transparency = 0.5
        brushUImaterial.diffuse.contents = UIColor.blue
        plane.geometry!.firstMaterial = brushUImaterial
        
        plane.addChildNode(SCNNode())
        scene.rootNode.addChildNode(plane)
        
        voxelMaterial = SCNMaterial()
        voxelMaterial.lightingModel = .physicallyBased
        voxelMaterial.diffuse.contents = UIColor.white
        voxelMaterial.roughness.contents = 0.3
        voxelMaterial.metalness.contents = 1
        voxelSphere.firstMaterial = voxelMaterial
        
        sceneView.scene = scene
        //sceneView.autoenablesDefaultLighting = true
        
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.environmentTexturing = .automatic
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        updateCameraInfo()
        let locatorPosition = cameraInfo.pos + cameraInfo.dir * simd_float3(1,0,1)
        if !voxelGridLocator.placed {
            let newPosition = SCNVector3(locatorPosition.x, locatorPosition.y - 0.5, locatorPosition.z)
            voxelGridLocator.node!.position = SCNVector3.lerp(voxelGridLocator.node!.position, newPosition, 0.1)
        }
        if trackingStateIsNormal && isDrawing {
            drawVoxel()
        }
    }
    
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        print("Tracking state: \(camera.trackingState)")
        
        switch camera.trackingState{
        case .normal :
            trackingStateIsNormal = true
            break
        default :
            trackingStateIsNormal = false
            break
        }
    }
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
