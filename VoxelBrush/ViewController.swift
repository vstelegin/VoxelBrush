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
    @IBOutlet var saveButton : RoundedButton!
    @IBOutlet var drawButton : ScrollableButton!
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
    var currentVoxelBrushPreset = [vector_int3]()
    var blurUIAnimator : UIViewPropertyAnimator?
    var voxelMaterial = SCNMaterial()
    var brushMaterial = SCNMaterial()
    var voxelMesh = MDLMesh()
    var voxelArray = MDLVoxelArray()
    let voxelSphere = SCNSphere(radius: 0.02)
    var isDrawing = false
    var isErasing = false
    var isMeshing = false
    var voxelPositionChanged = false
    var drawButtonAnimator : UIViewPropertyAnimator?
    var root : SCNNode?
    var voxelPosition = simd_float3(){
        didSet{
            let difference = voxelPosition - oldValue
            if simd_float3.dot (difference, difference) > 0.00002 {
                voxelPositionChanged = true
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
        root!.childNodes[3].isHidden = !root!.childNodes[3].isHidden
    }
    
    @IBAction func reset(){
        //let tempArray = MDLVoxelArray()
        voxelArray.difference(with: voxelArray)
        voxelsToMesh {
            self.isMeshing = false
        }
    }
    @IBAction func saveMesh(){
        let asset = MDLAsset()
        asset.add(voxelMesh)
        let saveQueue = DispatchQueue(label: "File export")
        saveQueue.async {
            let path = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            
            let now = Date()
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US")
            formatter.dateFormat = "YYYY-MMMM-dd-HH-mm"
            
            let filePath = path.appendingPathComponent("\(formatter.string(from: now))").appendingPathExtension("usdc")
            let fileManager = FileManager.default
            do {
                try fileManager.removeItem(at: filePath)
            } catch {
                print ("No file to delete")
            }
            do {
                try asset.export(to: filePath)
                DispatchQueue.main.async {
                    self.saveButton.backgroundColor = UIColor(red: 0, green: 1, blue: 0, alpha: 0.25)
                }
                
                print ("File saved")
            } catch {
                print ("Couldn't save the file")
            }
        }
        
    }
    @IBAction func drawButtonPressed(){
        isDrawing = true
        drawButtonAnimator?.startAnimation()
        SCNTransaction.animationDuration = 0.25
        root!.childNodes[3].childNodes[1].scale = SCNVector3(1)
    }
    @IBAction func drawButtonReleased(){
        SCNTransaction.animationDuration = 0.5
        root!.childNodes[3].childNodes[1].scale = SCNVector3(0)
        isDrawing = false
    }
    
    @IBAction func eraseButtonPressed(){
        isErasing = true
        brushMaterial.diffuse.contents = UIColor.red
    }
    
    @IBAction func eraseButtonReleased(){
        isErasing = false
        brushMaterial.diffuse.contents = UIColor.white
    }
    
    @IBAction func plusButtonPressed(){
        VoxelBrushPeresets.shared.size += 1
        currentVoxelBrushPreset = VoxelBrushPeresets.shared.spherical()
    }
    
    @IBAction func minusButtonPressed(){
        VoxelBrushPeresets.shared.size -= 1
        currentVoxelBrushPreset = VoxelBrushPeresets.shared.spherical()
        
    }
    
    @IBAction func brushSizeChange(){
        if drawButton.locationDifference != 0 {
            
            VoxelBrushPeresets.shared.size += drawButton.locationDifference
            currentVoxelBrushPreset = VoxelBrushPeresets.shared.spherical()
            
            let scaleAdjust : Float = Float(VoxelBrushPeresets.shared.size) / Float(VoxelBrushPeresets.shared.sizeRange.last!)
            root!.childNodes[3].scale = SCNVector3(scaleAdjust)
            
            
        }
    }
    func voxelsToMesh (completion : @escaping () -> () ) {
        self.isMeshing = true
        guard let voxelMesh = voxelArray.mesh(using: voxelMesh.allocator) else {
            print ("Couldn't create a mesh")
            return
        }
        completion()
        let node = SCNNode(mdlObject: voxelMesh)
        node.geometry?.firstMaterial = voxelMaterial
        
        let scene = sceneView.scene
        scene.rootNode.childNodes[0].scale = SCNVector3(0.01)
        let voxelArrayMinBounds = voxelArray.boundingBox.minBounds*0.01 - 50
        scene.rootNode.childNodes[0].position = SCNVector3(voxelArrayMinBounds - simd_float3(0.02 , 0.02, 0.02))

        root!.childNodes[0].geometry = node.geometry
        for child in scene.rootNode.childNodes[1].childNodes {
            child.removeFromParentNode()
        }
        self.voxelMesh = voxelMesh
        DispatchQueue.main.async {
            self.saveButton.backgroundColor = self.saveButton.tintColor
        }
    }
    
    func voxelBrushArray(_ voxelPosition : simd_float3) -> MDLVoxelArray{
        let voxelIndexPosition = ((voxelPosition + simd_float3(50,50,50)) * 100).toVectorInt_3()
        let tempVoxelArray = MDLVoxelArray()
        let tempVoxelIndices = currentVoxelBrushPreset
        for brushPosition in tempVoxelIndices {
            let index = MDLVoxelIndex(brushPosition + voxelIndexPosition,0)
            tempVoxelArray.setVoxelAtIndex(index)
        }
        return tempVoxelArray
    }
    
    func drawVoxel(delete : Bool = false){
        
        voxelPosition = cameraInfo.pos + cameraInfo.dir * 0.4 + simd_float3(0,0.04,0)
        
        if voxelPositionChanged {
            let voxelNode = SCNNode(geometry: voxelSphere)
            
       
            let tempVoxelArray = voxelBrushArray(voxelPosition)
 
            if delete {
                voxelArray.difference(with: tempVoxelArray)
            } else {
                voxelArray.union(with: tempVoxelArray)
            }
            
            
            voxelNode.position = SCNVector3(voxelPosition)
            root!.childNodes[1].addChildNode(voxelNode)
            
            
            if !isMeshing {
                isMeshing = true
                let meshingQueue = DispatchQueue(label: "Meshing")
                meshingQueue.asyncAfter(deadline: .now() + 0.05) {
                    self.voxelsToMesh{
                        self.isMeshing = false
                    }
                }
            }
            
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
    
    // MARK: VIEWDIDLOAD
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        
        sceneView.showsStatistics = true
   
        let scene = SCNScene()
        scene.rootNode.addChildNode(SCNNode()) // Mesh Placeholder
        scene.rootNode.addChildNode(SCNNode()) // Voxel Spheres Placeholder
        
        let plane = SCNNode(geometry: SCNPlane(width: 0.4, height: 0.4))
        plane.eulerAngles = SCNVector3(-CGFloat.pi*0.5,0,0)
        
        voxelGridLocator.node = plane
        
        let brushUImaterial = SCNMaterial()
        brushUImaterial.lightingModel = .constant
        brushUImaterial.transparency = 0.5
        brushUImaterial.diffuse.contents = UIColor.blue
        plane.geometry!.firstMaterial = brushUImaterial
        
        plane.addChildNode(SCNNode())
        plane.isHidden = true
        scene.rootNode.addChildNode(plane) // Model Transform Placeholder
        
        voxelMaterial = SCNMaterial()
        voxelMaterial.lightingModel = .physicallyBased
        voxelMaterial.diffuse.contents = UIColor.white
        voxelMaterial.roughness.contents = 0.3
        voxelMaterial.metalness.contents = 1
        brushMaterial = voxelMaterial.copy() as! SCNMaterial
        voxelSphere.firstMaterial = brushMaterial
        
        
        let cursorNode = VoxelCursor.shared.createModel()
        cursorNode.childNodes[0].geometry!.firstMaterial = voxelMaterial
        scene.rootNode.addChildNode(SCNNode()) // Add cursor placeholder
        scene.rootNode.childNodes[3].addChildNode(cursorNode)//Add cursor
        scene.rootNode.childNodes[3].addChildNode(SCNNode(geometry: voxelSphere))
        scene.rootNode.childNodes[3].childNodes[1].scale = SCNVector3(0)
        scene.rootNode.addChildNode(SCNNode()) // Symmetry plane placeholder
        
        sceneView.scene = scene
        root = sceneView.scene.rootNode
        
        currentVoxelBrushPreset = VoxelBrushPeresets.shared.spherical()
        
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
        if trackingStateIsNormal {
            
            root!.childNodes[3].position = SCNVector3(cameraInfo.pos + cameraInfo.dir*0.4 + simd_float3(0,0.04,0))
            
            if isDrawing {
                drawVoxel()
            }
            if isErasing {
                drawVoxel(delete: true)
            }
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
