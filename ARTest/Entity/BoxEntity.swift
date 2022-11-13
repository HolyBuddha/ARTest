//
//  BoxEntity.swift
//  ARTest
//
//  Created by Vladimir Izmaylov on 07.11.2022.
//
import ARKit
import RealityKit

class BoxEntity: Entity, HasModel, HasCollision {
    
    required init(color: UIColor) {
        super.init()
        self.model = ModelComponent(
            mesh: .generateBox(size: 0.1),
            materials: [SimpleMaterial(
                color: color,
                isMetallic: true)
            ]
        )
        self.generateCollisionShapes(recursive: true)
    }
    
    required init() {
        fatalError("init() has not been implemented")
    }
}
