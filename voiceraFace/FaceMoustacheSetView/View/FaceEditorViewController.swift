//
//  FaceEditorViewController.swift
//  voicera
//
//  Created by sanath kavatooru on 30/12/24.
//

import UIKit
import ARKit
import AVFoundation

class FaceEditorViewController: UIViewController, ARSCNViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

   @IBOutlet weak private var sceneView: ARSCNView!
    private var mustacheImages: [String] = [ "mustache1", "mustache2", "mustache3" ]
    private var selectedMustacheIndex = 0
    @IBOutlet weak private var collectionView: UICollectionView! {
        didSet {
            let nib = UINib(nibName: "FaceEditorCollectionViewCell", bundle: nil)
            collectionView.register(nib, forCellWithReuseIdentifier: "FaceEditorCollectionViewCell")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startARSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    private func startARSession() {
        guard ARFaceTrackingConfiguration.isSupported else {
            print("Face tracking is not supported on this device.")
            return
        }

        let configuration = ARFaceTrackingConfiguration()
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return nil }
        
        let node = SCNNode()

        let mustacheImage = mustacheImages[selectedMustacheIndex]
        let plane = SCNPlane(width: 0.1, height: 0.05)
        plane.firstMaterial?.diffuse.contents = mustacheImage
        plane.firstMaterial?.isDoubleSided = true

        let mustacheNode = SCNNode(geometry: plane)
        mustacheNode.position = SCNVector3(faceAnchor.geometry.vertices[12].x, faceAnchor.geometry.vertices[12].y - 0.02, faceAnchor.geometry.vertices[12].z)
        mustacheNode.eulerAngles.x = -.pi / 2

        node.addChildNode(mustacheNode)
        return node
    }

    // MARK: - UICollectionView DataSource

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return mustacheImages.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FaceEditorCollectionViewCell",
                                                      for: indexPath) as? FaceEditorCollectionViewCell
        cell?.setup(imageName: mustacheImages[indexPath.row],
                    imageTitle: mustacheImages[indexPath.row])
        return cell ?? UICollectionViewCell()
    }

    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        selectedMustacheIndex = indexPath.item
        collectionView.reloadData()
        restartARSession()
    }

    private func restartARSession() {
        sceneView.session.pause()
        startARSession()
    }
}

