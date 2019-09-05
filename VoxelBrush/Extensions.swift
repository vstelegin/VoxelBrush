//
//  SCNVector3Extensions.swift
//  VoxelBrush
//
//  Created by Chase on 03/09/2019.
//  Copyright © 2019 ViatcheslavTelegin. All rights reserved.
//

import Foundation
import SceneKit
extension Float {
    static func lerp(_ a: Float, _ b : Float, _ t : Float) -> Float{
        return (a - (a - b)*t)
    }
}
extension simd_float3{
    static func dot(_ a: simd_float3, _ b: simd_float3) -> simd_float1 {
        return a.x * b.x + a.y * b.y + a.z * b.z
    }
    func toVectorInt_3() -> vector_int3 {
        return vector_int3(Int32(self.x),Int32(self.y),Int32(self.z))
    }
}
extension SCNVector3{
    static func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3(x: left.x+right.x, y: left.y+right.y, z: left.z+right.z)
    }
    static func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3(x: left.x-right.x, y: left.y-right.y, z: left.z-right.z)
    }
    static func lerp(_ a : SCNVector3, _ b : SCNVector3, _ t: Float) -> SCNVector3{
        return SCNVector3(Float.lerp(a.x, b.x, t), Float.lerp(a.y, b.y, t), Float.lerp(a.z, b.z, t))
    }
    init (_ v : simd_float3) {
        self.init (x: v.x, y: v.y, z: v.z)
    }
}
