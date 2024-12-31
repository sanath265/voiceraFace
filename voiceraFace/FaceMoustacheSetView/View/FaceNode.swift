//
//  FaceNode.swift
//  voiceraFace
//
//  Created by sanath kavatooru on 31/12/24.
//
import SceneKit

class FaceNode: SCNNode {
    
    var options: [String]
    var index = 0
    
    init(with options: [String], width: CGFloat = 0.08, height: CGFloat = 0.08) {
        self.options = options
        
        super.init()
        
        let plane = SCNPlane(width: width, height: height)
        plane.firstMaterial?.diffuse.contents =  UIImage(named: options.first!)
        plane.firstMaterial?.isDoubleSided = true
        
        geometry = plane
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Custom functions

extension FaceNode {
    
    func updatePosition(for vectors: [vector_float3]) {
        let newPos = vectors.reduce(vector_float3(), +) / Float(vectors.count)
        position = SCNVector3(newPos)
    }
    
    func next(index: Int) {
        
        if let plane = geometry as? SCNPlane {
            plane.firstMaterial?.diffuse.contents = UIImage(named: options[index])
            plane.firstMaterial?.isDoubleSided = true
        }
    }
}
