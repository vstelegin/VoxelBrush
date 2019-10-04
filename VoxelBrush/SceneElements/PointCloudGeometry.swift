//
//  PointCloudGeometry.swift
//  VoxelBrush
//
//  Created by Chase on 24/09/2019.
//
//  Got this method from here:
//  http://dduraz.com/2019/04/04/arkit-custom-feature-points/

import Foundation
import SceneKit

class PointCloudGeometry {
    class func pointCloudGeometry(for points:[vector_float3]) -> SCNGeometry? {
           
        guard !points.isEmpty else { return nil }
        
        let stride = MemoryLayout<vector_float3>.size
        let pointData = Data(bytes: points, count: stride * points.count)
        
        let source = SCNGeometrySource(data: pointData,
                                       semantic: SCNGeometrySource.Semantic.vertex,
                                       vectorCount: points.count,
                                       usesFloatComponents: true,
                                       componentsPerVector: 3,
                                       bytesPerComponent: MemoryLayout<Float>.size,
                                       dataOffset: 0,
                                       dataStride: stride)
        
        //let pointSize : CGFloat = 10
        let element = SCNGeometryElement(data: nil, primitiveType: .point, primitiveCount: points.count, bytesPerIndex: 0)
        element.pointSize = 3
        element.minimumPointScreenSpaceRadius = 4
        element.maximumPointScreenSpaceRadius = 6
        
        let pointsGeometry = SCNGeometry(sources: [source], elements: [element])
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.white
        material.transparency = 0.25
        material.isDoubleSided = true
        material.locksAmbientWithDiffuse = true
        pointsGeometry.firstMaterial = material
        return pointsGeometry
    }

}
