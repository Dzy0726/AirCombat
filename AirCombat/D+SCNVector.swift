//
//  RB+SCNVector.swift
//  SCNVector3 extension
//
//  Created by 董震宇 on 2020/12/3.
//

import SceneKit

extension SCNVector3 {

    func distance(to destination: SCNVector3) -> CGFloat {
        let dx = destination.x - x
        let dy = destination.y - y
        let dz = destination.z - z
        
        return CGFloat(sqrt(dx*dx + dy*dy + dz*dz))
    }

}
