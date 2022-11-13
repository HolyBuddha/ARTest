//
//  ViewController.swift
//  ARTest
//
//  Created by Vladimir Izmaylov on 07.11.2022.
//

import UIKit
import RealityKit
import ARKit

class ViewController: UIViewController, ARSessionDelegate {
    
    // MARK: IBOutlets
    
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var buttonsStack: UIStackView!
    @IBOutlet var arView: ARView!
    
    // MARK: Internal properties
    
    private let arImageUrl = URL(string: "https://mix-ar.ru/content/ios/marker.jpg")
    private let cubeModelName = "Cube"
    private var arImageSet: Set<ARReferenceImage> = []
    private var animationDuration: Double = 1
    private var modelsCount = 0 {
        didSet {
            showButtons()
        }
    }
    // MARK: IBActions
    
    @IBAction func leftButtonPressed(_ sender: Any) {
        arView.scene.anchors.forEach { anchor in
            moveEntity(anchor: anchor,
                       entityName: cubeModelName,
                       direction: .left
            )
        }
    }
    @IBAction func forwardButtonPressed(_ sender: Any) {
        arView.scene.anchors.forEach { anchor in
            moveEntity(anchor: anchor,
                       entityName: cubeModelName,
                       direction: .forward
            )
        }
    }
    @IBAction func rightButtonPressed(_ sender: Any) {
        arView.scene.anchors.forEach { anchor in
            moveEntity(anchor: anchor,
                       entityName: cubeModelName,
                       direction: .right
            )
        }
    }
    
    @IBAction func downButtonPressed(_ sender: Any) {
        arView.scene.anchors.forEach { anchor in
            moveEntity(anchor: anchor,
                       entityName: cubeModelName,
                       direction: .backward
            )
        }
    }
    
    // MARK: Override methods
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadARImages()
        setupARView()
        setupCoachingOverlay()
    }
    
    // MARK: Internal methods
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        anchors.compactMap { $0 as? ARImageAnchor }.forEach { anchor in
            guard let entity = try? Entity.load(named: "Crystal") else {
                print("No entity found")
                return
            }
            placeEntityOnImage(entity: entity, at: anchor)
            
            print("ARImageAnchor founded")
            speedLabel.isHidden = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.speedLabel.isHidden = true
                }
            animationDuration = 0.5
        }
    }
    
    // MARK: Setup Methods
    
    private func setupARView() {
        arView.session.delegate = self
        enableObjectRemoval()
        enableObjectAdding()
    }
    
    private func configARSession(detectionImages: Set<ARReferenceImage>) {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.detectionImages = detectionImages
        configuration.maximumNumberOfTrackedImages = 1
        arView.session.run(configuration)
    }
    
    private func loadARImages() {
        NetworkManager.shared.loadImageFrom(url: arImageUrl!) { image in
            let arImage = ARReferenceImage(image.cgImage!, orientation: CGImagePropertyOrientation.up, physicalWidth: 0.1)
            self.arImageSet.insert(arImage)
            self.configARSession(detectionImages: self.arImageSet)
        }
    }
    
    private func showButtons() {
        if modelsCount > 0 {
            buttonsStack.isHidden = false
        } else {
            buttonsStack.isHidden = true
        }
    }
}

extension ViewController {
    
    // MARK: Object placement
    
    func enableObjectAdding() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        arView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        let tapLocation = recognizer.location(in: arView)
        
        guard let rayResult = arView.ray(through: tapLocation) else { return }
        let results = arView.scene.raycast(origin: rayResult.origin, direction: rayResult.direction)
        
        if results.first != nil {
            if let entity = arView.entity(at: tapLocation) as? BoxEntity {
                entity.model?.materials = [SimpleMaterial(color: .random, isMetallic: true)]
            }
        } else {
            let results = arView.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal)
            
            if let firstResult = results.first {
                let position = simd_make_float3(firstResult.worldTransform.columns.3)
                placeCube(at: position)
                modelsCount += 1
            } else {
                print("Object placement failed - couldn't find surface.")
            }
        }
    }
    
    func placeCube(at position: SIMD3<Float>) {
        let entity = BoxEntity(color: .red)
        let anchorEntity = AnchorEntity(world: position)
        anchorEntity.name = "Cube"
        anchorEntity.addChild(entity)
        arView.scene.addAnchor(anchorEntity)
    }
    
    func enableObjectRemoval() {
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(recognizer:)))
        arView.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    @objc func handleLongPress(recognizer: UILongPressGestureRecognizer) {
        let tapLocation = recognizer.location(in: arView)
        if let entity = arView.entity(at: tapLocation) {
            if let anchorEntity = entity.anchor, anchorEntity.name == "Cube" {
                anchorEntity.removeFromParent()
                modelsCount -= 1
            }
        }
    }
    
    func placeEntityOnImage(entity: Entity, at anchor: ARImageAnchor) {
        let anchorEntity = AnchorEntity(anchor: anchor)
        anchorEntity.addChild(entity)
        arView.scene.addAnchor(anchorEntity)
    }
}

extension ViewController {
    
    // MARK: Object moving
    
    func moveEntity(anchor: Scene.AnchorCollection.Element, entityName: String, direction: MoveDirections) {
        
        let sIMD3Position: SIMD3<Float>
        
        switch direction {
        case .left:
            sIMD3Position = SIMD3( x: -0.3, y: 0, z: 0)
        case .right:
            sIMD3Position = SIMD3( x: 0.3, y: 0, z: 0)
        case .forward:
            sIMD3Position = SIMD3( x: 0, y: 0, z: -0.3)
        case .backward:
            sIMD3Position = SIMD3( x: 0, y: 0, z: 0.3)
        }
        
        let transformPosition = Transform(translation: sIMD3Position)
        
        if anchor.findEntity(named: entityName) != nil {
            anchor.move(to: transformPosition, relativeTo: anchor.findEntity(named: entityName), duration: animationDuration)
        }
    }
}
