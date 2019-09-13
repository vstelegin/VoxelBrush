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
    init (_ v : Float) {
        self.init (simd_float3(v, v, v))
    }
    func toVectorInt_3() -> vector_int3 {
        return vector_int3(Int32(self.x),Int32(self.y),Int32(self.z))
    }
}

extension vector_int3{
    static func + (left: vector_int3, right: vector_int3) -> vector_int3 {
        return vector_int3(left.x + right.x, left.y + right.y, left.z + right.z)
    }
}
extension SCNVector3{
    static func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3(x: left.x+right.x, y: left.y+right.y, z: left.z+right.z)
    }
    static func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3(x: left.x-right.x, y: left.y-right.y, z: left.z-right.z)
    }
    
    static func * (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3(x: left.x*right.x, y: left.y*right.y, z: left.z*right.z)
    }
    
    static func lerp(_ a : SCNVector3, _ b : SCNVector3, _ t: Float) -> SCNVector3{
        return SCNVector3(Float.lerp(a.x, b.x, t), Float.lerp(a.y, b.y, t), Float.lerp(a.z, b.z, t))
    }
    init (_ v : simd_float3) {
        self.init (x: v.x, y: v.y, z: v.z)
    }
    init (_ f : Float) {
        self.init (x: f, y: f, z: f)
    }
}

extension Int32{
    func evenToSignedOne() -> Int32 {
        return self%2 == 0 ? -1 : 1
    }
}
extension CGPoint {
    static func + (left: CGPoint, rigth: CGPoint) -> CGPoint {
        return CGPoint(x: left.x + rigth.x, y: left.y + rigth.y)
    }
    
    static func - (left: CGPoint, rigth: CGPoint) -> CGPoint {
        return CGPoint(x: left.x - rigth.x, y: left.y - rigth.y)
    }
    
    init (_ v : CGFloat) {
        self.init (x: v, y: v)
    }
}

extension MDLVoxelIndex {
    init (_ position: vector_int3, _ shell: Int32) {
        self.init (position.x, position.y, position.z, shell)
    }
}