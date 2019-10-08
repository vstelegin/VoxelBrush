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
import CoreData
import MultipeerConnectivity

class BrushViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, NSFetchedResultsControllerDelegate {
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var blurView: UIVisualEffectView!
    @IBOutlet var saveButton : RoundedButton!
    @IBOutlet var drawButton : ScrollableButton!
    @IBOutlet var eraseButton : RoundedButton!
    @IBOutlet var symmetryButton : RoundedButton!
    @IBOutlet var undoButton : RoundedButton!
    @IBOutlet var snapButton : RoundedButton!
    @IBOutlet var restoreButton : UIButton!
    @IBOutlet var plusButton : RoundedButton!
    @IBOutlet var minusButton : RoundedButton!
    @IBOutlet var resetButton : RoundedButton!
    @IBOutlet var multiUserButton : UIButton!
    @IBOutlet var trackingIndicatorView : UIView!
    var trackingStateIsNormal = false {
        didSet {
            guard self.trackingStateIsNormal != oldValue else{
                return
            }
            if self.trackingStateIsNormal {
                animateUIAlpha(show: true)
            }
            else {
                animateUIAlpha(show: false)
            }
        }
    }
    var cameraInfo = (pos : simd_float3(), dir : simd_float3())
    var currentVoxelBrushPreset = [vector_int3]()
    var voxelMaterial = SCNMaterial()
    var brushMaterial = SCNMaterial()
    var deleteBrushMaterial = SCNMaterial()
    var voxelMesh = MDLMesh()
    var voxelArray = MDLVoxelArray()
    var voxelArrayForMeshing = MDLVoxelArray()
    var voxelArrayHistory : [MDLVoxelArray] = [MDLVoxelArray()]
    let voxelSphere = SCNSphere(radius: 0.06)
    let voxelEraseSphere = SCNSphere(radius: 0.06)
    var isDrawing = false
    var isErasing = false
    var isMeshing = false
    var isWritingVoxels = false
    var symmetryMode = false
    var symmetryPlaneMoving = false
    var symmetryTimer : Timer?
    var snapping = false
    var snappingTimer : Timer?
    var voxelPositionChanged = false
    var voxelCursorDistance : Float = 0.5 {
        didSet{
            //print("Cursor distance: \(voxelCursorDistance)")
            //voxelCursorDistance = Float.lerp (voxelCursorDistance, oldValue, 0.05)
        }
    }
    var drawButtonAnimator : UIViewPropertyAnimator?
    var root : SCNNode?
    var voxelPosition = simd_float3(){
        didSet{
            let difference = voxelPosition - oldValue
            if dot(difference, difference) > 0.0002 {
                voxelPositionChanged = true
            } else {
                voxelPositionChanged = false
                voxelPosition = oldValue
            }
        }
    }
    
    struct PlaceholderNode {
        var node : SCNNode?
        var placed = false
    }
    
    var voxelGridLocator = PlaceholderNode()
    var symmetryPlane = PlaceholderNode()
    let scaleFactor : Float = 0.02
    
    var multipeerSession : MultipeerSession!
    @IBAction func tap(_ sender: UITapGestureRecognizer){
//        if trackingStateIsNormal {
//            voxelGridLocator.placed = !voxelGridLocator.placed
//        }
//        root!.childNodes[3].isHidden = !root!.childNodes[3].isHidden
    }
    
    @IBAction func snapButtonPressed(){
        if !snapping {
            snappingTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: {_ in
                self.snapping = true
                self.snapButton.regularBorderWidth = 1
                self.root!.childNodes[5].isHidden = false
                let feedback = UIImpactFeedbackGenerator()
                feedback.impactOccurred()
                
            })
        } else {
            snapping = false
            root!.childNodes[5].isHidden = true
            self.snapButton.regularBorderWidth = 0
        }
        updateCursorDistance()
    }
    @IBAction func snapButtonReleased(){
        if let timer = snappingTimer {
            timer.invalidate()
        }
        
        
    }
    
    @IBAction func reset(){
        voxelArrayHistory.removeAll()
        voxelArray = MDLVoxelArray()
        meshingToQueue()
        undoButton.isEnabled = false
    }
    
    @IBAction func saveMesh(){
        let voxelData = VoxelData(context: DataController.shared.viewContext)
        voxelData.id = DataController.shared.id
        voxelData.voxelArrayIndices = voxelArray.voxelIndices()
        
        voxelData.bboxMinX = voxelArray.boundingBox.minBounds.x
        voxelData.bboxMinY = voxelArray.boundingBox.minBounds.y
        voxelData.bboxMinZ = voxelArray.boundingBox.minBounds.z
        
        voxelData.bboxMaxX = voxelArray.boundingBox.maxBounds.x
        voxelData.bboxMaxY = voxelArray.boundingBox.maxBounds.y
        voxelData.bboxMaxZ = voxelArray.boundingBox.maxBounds.z
        
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "YYYYMMdd-HHmm"
        //let now = Date()
        //let date = "\(formatter.string(from: now))"
        let fileName = "VoxelBrush\(voxelData.id)"
        print ("ID : \(voxelData.id)")
        voxelData.title = fileName
        //voxelData.url = path.appendingPathComponent("\(fileName)").appendingPathExtension("usdz")
            
        let fileManager = FileManager.default
        let path = try! fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let filePath = path.appendingPathComponent("\(fileName)").appendingPathExtension("usd")
        
        let asset = MDLAsset()
        let exportMesh = voxelMesh
        let subMesh = exportMesh.submeshes!.firstObject as! MDLSubmesh
        subMesh.material = MDLMaterial(scnMaterial: voxelMaterial)
        asset.add(exportMesh)
//        print("Can export: \(MDLAsset.canExportFileExtension("usd"))")
        let saveQueue = DispatchQueue(label: "File export")
        saveQueue.async {
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
            
            let newFilePath = path.appendingPathComponent("\(fileName)").appendingPathExtension("usd")
            
//            do {
//                try fileManager.moveItem(at: filePath, to: newFilePath)
//            } catch {
//                print ("Couldn't rename to .usdz")
//            }
            
            voxelData.url = newFilePath
            DataController.shared.save()
            DataController.shared.fetch()
            DispatchQueue.main.async {
                self.restoreButton.isEnabled = true
            }
            
        }
    }
    @IBAction func drawButtonPressed(){
        isDrawing = true
        drawButtonAnimator?.startAnimation()
        SCNTransaction.animationDuration = 0.25
        root!.childNodes[3].childNodes[1].scale = SCNVector3(1)
        resetSaveButton()
    }
    @IBAction func drawButtonReleased(){
        SCNTransaction.animationDuration = 0.5
        root!.childNodes[3].childNodes[1].scale = SCNVector3(0)
        isDrawing = false
        updateHistory()
        if let meshWorkingItem = GCD.shared.meshingWorkItem {
            meshWorkingItem.cancel()
        }
        meshingToQueue()
    }
    
    @IBAction func eraseButtonPressed(){
        voxelSphere.firstMaterial = deleteBrushMaterial
        isErasing = true
        resetSaveButton()
    }
    
    @IBAction func eraseButtonReleased(){
        voxelSphere.firstMaterial = brushMaterial
        isErasing = false
        updateHistory()
        GCD.shared.meshingWorkItem!.cancel()
        meshingToQueue()
    }
    
    @IBAction func plusButtonPressed(){
        brushSizeChange(1)
    }
    
    @IBAction func minusButtonPressed(){
        brushSizeChange(-1)
        
    }
    
    @IBAction func drawButtonDrag(){
        if drawButton.locationDifference != 0 {
            brushSizeChange(drawButton.locationDifference)
        }
    }
    
    @IBAction func symmetryButtonPressed(){
        if symmetryMode {
            symmetryTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: {_ in
                let feedback = UIImpactFeedbackGenerator()
                feedback.impactOccurred()
                self.symmetryPlaneMoving = true
                self.recenterSymmetryPlane()
            })
        }
        
    }
    
    @IBAction func symmetryButtonReleased(){
        if !symmetryPlaneMoving{
            symmetryMode = !symmetryMode
            if symmetryMode {
                symmetryButton.setTitle("👐", for: .normal)
                symmetryButton.titleLabel?.font = UIFont.systemFont(ofSize: 32)
                SCNTransaction.animationDuration = 0.0
                root!.childNodes[4].isHidden = false
                if abs(root!.childNodes[4].position.x) < 0.0001 {
                    recenterSymmetryPlane()
                }
            } else {
                symmetryButton.setTitle("🤚", for: .normal)
                symmetryButton.titleLabel?.font = UIFont.systemFont(ofSize: 24)
                SCNTransaction.animationDuration = 0.0
                root!.childNodes[4].isHidden = true
            }
        }
        if let symmetryTimer = symmetryTimer{
            symmetryTimer.invalidate()
        }
        
        symmetryPlaneMoving = false
    }
    
    @IBAction func undoButtonPressed(){
        if voxelArrayHistory.count > 1 {
            voxelArrayHistory.removeLast()
            voxelArray.difference(with: voxelArray)
            voxelArray.union(with: voxelArrayHistory.last!)
            meshingToQueue()
        }
        if voxelArrayHistory.count <= 1
        {
            undoButton.isEnabled = false
        }
    }
    
    @IBAction func restore(){
        resetSaveButton()
        performSegue(withIdentifier: "showSavedFiles", sender: self)
    }
    
    @IBAction func unwindToDrawing(segue: SegueRightToLeft){}
    
    @IBAction func shareSession(_ button: UIButton) {
        sceneView.session.getCurrentWorldMap { worldMap, error in
            guard let map = worldMap
                else { print("Error: \(error!.localizedDescription)"); return }
            guard let data = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                else { fatalError("can't encode map") }
            self.multipeerSession.sendToAllPeers(data)
        }
        
    }
    
    var mapProvider: MCPeerID?
    func receivedData(_ data: Data, from peer: MCPeerID){
        do {
            if let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data) {
                // Run the session with the received world map.
                let configuration = ARWorldTrackingConfiguration()
                configuration.planeDetection = .horizontal
                configuration.environmentTexturing = .automatic
                configuration.initialWorldMap = worldMap
                sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
                // Remember who provided the map for showing UI feedback.
                mapProvider = peer
                return
            }
            
            if let receivedVoxelIndices = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? Data {
                DataReceiver.shared.receivedVoxelIndices = receivedVoxelIndices
                return
            }
        } catch {
            print("can't decode data received from \(peer)")
        }
        var delete = false
        do {
            let decoder = JSONDecoder()
            debugPrint("Data: \(data)")
            let receivedBounds = try decoder.decode(Bounds.self, from: data)
            DataReceiver.shared.receivedBounds = receivedBounds
            delete = receivedBounds.delete! > 0
        } catch {
            print ("can't decode JSON")
        }
        
        if let receivedVoxelArray = DataReceiver.shared.voxelArrayFromReceivedData() {
            if delete {
                self.voxelArray.difference(with: receivedVoxelArray)
            } else {
                self.voxelArray.union(with: receivedVoxelArray)
            }
            meshingToQueue()
        }
        
    }
    
    func shareVoxelArray(voxelIndices : Data, voxelArrayBBox :MDLAxisAlignedBoundingBox, _ delete : Int? = 0){
        guard !multipeerSession.connectedPeers.isEmpty else {return}
        guard let voxelIndicesForSending = try? NSKeyedArchiver.archivedData(withRootObject: voxelIndices, requiringSecureCoding: false)
            else { fatalError("can't encode data") }
        self.multipeerSession.sendToAllPeers(voxelIndicesForSending)
        
        var voxelArrayBounds = Bounds()
        let encoder = JSONEncoder()
        voxelArrayBounds.minBound?.append(Double(voxelArrayBBox.minBounds.x))
        voxelArrayBounds.minBound?.append(Double(voxelArrayBBox.minBounds.y))
        voxelArrayBounds.minBound?.append(Double(voxelArrayBBox.minBounds.z))
        
        voxelArrayBounds.maxBound?.append(Double(voxelArrayBBox.maxBounds.x))
        voxelArrayBounds.maxBound?.append(Double(voxelArrayBBox.maxBounds.y))
        voxelArrayBounds.maxBound?.append(Double(voxelArrayBBox.maxBounds.z))
        voxelArrayBounds.delete = delete
        guard let voxelArrayBoundsForSending = try? encoder.encode(voxelArrayBounds)
        else { fatalError("can't encode data") }
        self.multipeerSession.sendToAllPeers(voxelArrayBoundsForSending)
    }
    // MARK: View Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.showsStatistics = true
  
        sceneSetup()
        brushSizeChange()
        
        DataController.shared.fetch()
        DataController.shared.setNewID()
        
        if let _ = DataController.shared.voxelDataStored {
            restoreButton.isEnabled = true
        }
        
        multipeerSession = MultipeerSession(receivedDataHandler: receivedData)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.environmentTexturing = .automatic
        configuration.planeDetection = .horizontal
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
            if snapping {
                updateCursorDistance()
            }
            root!.childNodes[3].position = SCNVector3(cameraInfo.pos + cameraInfo.dir * voxelCursorDistance + simd_float3(0,0.04,0))
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
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if snapping {
            guard let featurePoints = frame.rawFeaturePoints else { return }
            let featurePointsGeometry = PointCloudGeometry.pointCloudGeometry(for: featurePoints.points)
            root!.childNodes[5].geometry = featurePointsGeometry
        }
        
        switch frame.worldMappingStatus {
        case .notAvailable, .limited:
            multiUserButton.isHidden = true
        case .extending:
            multiUserButton.isHidden = multipeerSession.connectedPeers.isEmpty
        case .mapped:
            multiUserButton.isHidden = multipeerSession.connectedPeers.isEmpty
        default:
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let collectionViewController = segue.destination
        DataController.shared.fetchedResultsController.delegate = collectionViewController as? NSFetchedResultsControllerDelegate
    }
    
    func loadFromStoredVoxelData(){
        guard let voxelDataObject = DataController.shared.voxelDataStored else {return}
        guard let voxelData = voxelDataObject.voxelArrayIndices else {
             print ("Couldn't load data from the voxel data object")
             return
        }
         
        let bboxMin = vector_float3(voxelDataObject.bboxMinX, voxelDataObject.bboxMinY, voxelDataObject.bboxMinZ)
        let bboxMax = vector_float3(voxelDataObject.bboxMaxX, voxelDataObject.bboxMaxY, voxelDataObject.bboxMaxZ)
        let boundingBox = MDLAxisAlignedBoundingBox(maxBounds: bboxMax, minBounds: bboxMin)

        voxelArray = MDLVoxelArray(data: voxelData, boundingBox: boundingBox, voxelExtent: 1)
        meshingToQueue()
    }
    
    func brushSizeChange(_ difference : Int32 = 0){
        VoxelBrushPeresets.shared.size += difference
        currentVoxelBrushPreset = VoxelBrushPeresets.shared.spherical()
        let scaleAdjust : Float = Float(VoxelBrushPeresets.shared.size) / Float(VoxelBrushPeresets.shared.sizeRange.last!)
        root!.childNodes[3].scale = SCNVector3(scaleAdjust)
    }
    
    func meshingToQueue(){
        GCD.shared.voxelQueue.async(flags: .barrier){
            self.voxelArrayForMeshing = MDLVoxelArray()
            self.voxelArrayForMeshing.union(with: self.voxelArray)
            
            
            var cursorNodes = [SCNNode]()
            for node in self.root!.childNodes[1].childNodes {
                cursorNodes.append(node)
            }
            GCD.shared.meshingWorkItem = DispatchWorkItem {
                self.voxelsToMesh(self.voxelArrayForMeshing, cursorNodes)
            }
            GCD.shared.meshingQueue.async (execute: GCD.shared.meshingWorkItem!)
        }
    }
    
    func voxelsToMesh (_ voxelArray : MDLVoxelArray = MDLVoxelArray(), _ cursorNodes : [SCNNode] = [SCNNode]()) {
        
        guard let voxelMesh = voxelArray.mesh(using: nil) else {
            print ("Couldn't create a mesh")
            return
        }
        
        let node = SCNNode(mdlObject: voxelMesh)
        node.geometry?.firstMaterial = voxelMaterial
        
        let scene = sceneView.scene
        scene.rootNode.childNodes[0].scale = SCNVector3(scaleFactor)
        let voxelArrayMinBounds = voxelArray.boundingBox.minBounds * scaleFactor - 50
        SCNTransaction.animationDuration = 0.0
        scene.rootNode.childNodes[0].position = SCNVector3(voxelArrayMinBounds - simd_float3(0.02 , 0.02, 0.02))

        root!.childNodes[0].geometry = node.geometry
        
        self.voxelMesh = voxelMesh
        for child in cursorNodes {
            child.removeFromParentNode()
        }
        isMeshing = false
    }
    
    func voxelBrushArray(_ voxelPosition : simd_float3) -> MDLVoxelArray{
        let voxelIndexPosition = ((voxelPosition + simd_float3(50,50,50)) / scaleFactor).toVectorInt_3()
        let tempVoxelArray = MDLVoxelArray()
        let tempVoxelIndices = currentVoxelBrushPreset
        for brushPosition in tempVoxelIndices {
            let index = MDLVoxelIndex(brushPosition + voxelIndexPosition,0)
            tempVoxelArray.setVoxelAtIndex(index)
        }
        return tempVoxelArray
    }
    
    func drawVoxel(delete : Bool = false){
        
        voxelPosition = simd_float3(root!.childNodes[3].position)
        
        if voxelPositionChanged {
            
            // Draw the brush stroke
            let voxelNode = SCNNode(geometry: delete ? voxelEraseSphere : voxelSphere)
            voxelNode.scale = root!.childNodes[3].scale
            voxelNode.position = SCNVector3(voxelPosition)
            root!.childNodes[1].addChildNode(voxelNode)
            
            // Update voxel array
            let tempVoxelArray = voxelBrushArray(voxelPosition)
            
            // MARK: Symmetry mode
            if symmetryMode{
                let mirroredVoxedNode = SCNNode(geometry: voxelSphere)
                let mirroredVoxelPosition = mirrorPoint(planeNode: root!.childNodes[4], pointPosition: voxelPosition)
                mirroredVoxedNode.scale = root!.childNodes[3].scale
                mirroredVoxedNode.position = SCNVector3(mirroredVoxelPosition)
                root!.childNodes[1].addChildNode(mirroredVoxedNode)
                let tempVoxelArrayMirrored = voxelBrushArray(mirroredVoxelPosition)
                tempVoxelArray.union(with: tempVoxelArrayMirrored)
            }
            
            if delete {
                GCD.shared.voxelQueue.async(flags: .barrier) {
                    self.voxelArray.difference(with: tempVoxelArray)
                    self.shareVoxelArray(voxelIndices: tempVoxelArray.voxelIndices()!, voxelArrayBBox: tempVoxelArray.boundingBox, 1)
                }
            } else {
                GCD.shared.voxelQueue.async(flags: .barrier) {
                    self.voxelArray.union(with: tempVoxelArray)
                    self.shareVoxelArray(voxelIndices: tempVoxelArray.voxelIndices()!, voxelArrayBBox: tempVoxelArray.boundingBox, 0)
                }
            }
            
            if !isMeshing {
                isMeshing = true
                meshingToQueue()
            }
        }
    }
    
    func updateHistory(){
        if voxelArrayHistory.count > 10 {
            voxelArrayHistory.removeFirst()
        }
        voxelArrayHistory.append(MDLVoxelArray())
        voxelArrayHistory.last?.union(with: voxelArray)
        undoButton.isEnabled = true
    }
    func updateCameraInfo(){
        guard let pointOfView = self.sceneView.pointOfView else{
            print ("No point of view")
            return
        }
        let orientation = simd_quatf(pointOfView.orientation)
        let direction = orientation.act(simd_float3(0,0,-1))
        cameraInfo.dir = direction
        cameraInfo.pos = simd_float3(pointOfView.position.x, pointOfView.position.y, pointOfView.position.z)
    }
    
    func mirrorPoint(planeNode: SCNNode, pointPosition: simd_float3) -> simd_float3{
        let planePosition = simd_float3(planeNode.position)
        let orientation = simd_quatf(planeNode.orientation)
        let normal = orientation.act(simd_float3(1,0,0))
        let v = pointPosition - planePosition
        let length = dot(normal, v)
        let mirroredPoint = pointPosition - 2 * length * normal
        return mirroredPoint
    }
    
    func recenterSymmetryPlane() {
        print("recentering")
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1.0
        root!.childNodes[4].position = root!.childNodes[3].position
        root!.childNodes[4].look(at: SCNVector3(cameraInfo.pos.x, root!.childNodes[4].position.y, cameraInfo.pos.z))
        SCNTransaction.commit()
    }
    func resetSaveButton() {
        self.saveButton.backgroundColor = self.saveButton.tintColor
    }
    
    func updateCursorDistance(){
        let hitDistance = pointCloudRayCast()
        if hitDistance > 0 {
            voxelCursorDistance = hitDistance
        }
    }
    
    func pointCloudRayCast() -> Float{
        guard let arFrame = sceneView.session.currentFrame else {return 0}
        guard let pointCloud = arFrame.rawFeaturePoints else {return 0}
        let points = pointCloud.points
        return rayAdvance(points, 0.3)
    }
    
    func rayAdvance(_ points : [vector_float3], _ rayDistance : Float) -> Float{

        if rayDistance > 3.0 {
            return 0
        }
        
        let rayPosition = cameraInfo.pos + cameraInfo.dir * rayDistance
        var distanceToPoint : Float = 100.0
        for point in points {
            distanceToPoint = min (distanceToPoint, length(rayPosition - point))
            if distanceToPoint < 0.04 {
                return rayDistance + distanceToPoint
            }
        }
        return rayAdvance(points, rayDistance + distanceToPoint)
    }
    
    func animateUIAlpha(show : Bool, _ duration: Float = 0.5){
        let duration = TimeInterval(duration)
        let uiAlphaAnimator = UIViewPropertyAnimator(duration: duration, curve: .easeInOut){
            let alpha : CGFloat = show ? 1.0 : 0.0
            self.saveButton.alpha = alpha
            self.drawButton.alpha = alpha
            self.eraseButton.alpha = alpha
            self.symmetryButton.alpha = alpha
            self.undoButton.alpha = alpha
            self.snapButton.alpha = alpha
            self.plusButton.alpha = alpha
            self.minusButton.alpha = alpha
            self.resetButton.alpha = alpha
            self.voxelMaterial.transparency = alpha
            self.trackingIndicatorView.alpha = 1 - alpha
        }
        uiAlphaAnimator.startAnimation()
    }
}

