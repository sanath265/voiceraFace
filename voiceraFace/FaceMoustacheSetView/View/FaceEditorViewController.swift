import UIKit
import ARKit
import ARVideoKit
import CoreData

class FaceEditorViewController: UIViewController {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    private var mustacheImages: [String] = [ "mustache1",
                                             "mustache2",
                                             "mustache3" ]
    let features = ["mustache"]
    var featureIndices = [[6]]
    private var selectedMustacheIndex = 0
    private var isRecording = false
    private var isUsingFrontCamera = true
    private var recordingTimer: Timer?
    private var recordingDuration: Int = 0
    private var arSession: ARSession!
    private var arAnchor: ARFaceAnchor!
    private var mustacheNode: SCNNode?
    private var recordAR: RecordAR?
    
    
    @IBOutlet weak private var sceneView: ARSCNView!
    @IBOutlet weak private var collectionView: UICollectionView! {
        didSet {
            let nib = UINib(nibName: "FaceEditorCollectionViewCell", bundle: nil)
            collectionView.register(nib, forCellWithReuseIdentifier: "FaceEditorCollectionViewCell")
            collectionView.dataSource = self
            collectionView.delegate = self
        }
    }
    
    @IBOutlet weak private var recordImage: UIImageView! {
        didSet {
            recordImage.image = UIImage(systemName: "record.circle.fill")?.withRenderingMode(.alwaysTemplate)
            recordImage.tintColor = .white
            recordImage.isUserInteractionEnabled = true
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(startRecording(_:)))
            recordImage.addGestureRecognizer(tapGesture)
        }
    }
    
    @IBOutlet weak private var rotateCameraImage: UIImageView! {
        didSet {
            rotateCameraImage.image = UIImage(named: "rotate")
            rotateCameraImage.isUserInteractionEnabled = true
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleCamera(_:)))
            rotateCameraImage.addGestureRecognizer(tapGesture)
        }
    }
    
    @IBOutlet weak private var timeLabel: UILabel! {
        didSet {
            timeLabel.layer.cornerRadius = timeLabel.frame.height / 2
            timeLabel.layoutIfNeeded()
            timeLabel.layer.borderColor = UIColor.clear.cgColor
            timeLabel.text = "00:00"
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        sceneView.delegate = self
        recordAR = RecordAR(ARSceneKit: sceneView)
        recordAR?.enableAudio = true
        let configuration = ARWorldTrackingConfiguration()
        recordAR?.prepare(configuration)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFaceTracking()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    private func setupUI() {
        recordImage.isHidden = false
    }
}

extension FaceEditorViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedMustacheIndex = indexPath.item
        if let faceNode = sceneView.scene.rootNode.childNode(withName: "mustache", recursively: true) as? FaceNode {
            faceNode.next(index: selectedMustacheIndex)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 50, height: 75)
    }
}

extension FaceEditorViewController: AVCaptureFileOutputRecordingDelegate {
    
    @objc private func startRecording(_ sender: UITapGestureRecognizer) {
        if isRecording {
            stopRecording()
        } else {
            DispatchQueue.main.async {
                self.recordAR?.record()
                self.isRecording = true
                self.recordingDuration = 0
                self.startTimer()
                self.updateUIForRecording()
            }
        }
    }
    
    private func stopRecording() {
        recordAR?.stopAndExport { [weak self] videoPath, permissionStatus, exported in
            guard let self = self else { return }
            
            if exported {
                self.generateThumbnail(for: videoPath) { thumbnail in
                    self.showTagPopup(for: videoPath, thumbnail: thumbnail)
                }
            } else {
                print("Failed to export video")
            }
        }
        self.isRecording = false
        self.stopTimer()
        self.updateUIForStopped()
    }

    private func generateThumbnail(for videoPath: URL, completion: @escaping (UIImage) -> Void) {
        let url = videoPath
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        DispatchQueue.global().async {
            if let cgImage = try? imageGenerator.copyCGImage(at: CMTime(seconds: 1, preferredTimescale: 600), actualTime: nil) {
                let thumbnail = UIImage(cgImage: cgImage)
                DispatchQueue.main.async {
                    completion(thumbnail)
                }
            } else {
                DispatchQueue.main.async {
                    completion(UIImage(systemName: "video") ?? UIImage())
                }
            }
        }
    }

    private func showTagPopup(for videoPath: URL, thumbnail: UIImage) {
        let alertController = UIAlertController(title: "Enter Tag", message: "Add a tag for this recording.", preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "Tag name"
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self,
                  let tag = alertController.textFields?.first?.text,
                  !tag.isEmpty else { return }
            
            let duration = self.formatDuration(self.recordingDuration)
            let newRecording = NSEntityDescription.insertNewObject(forEntityName: "Recordings", into: context)

                // Save videoPath as String
                newRecording.setValue(videoPath.absoluteString, forKey: "videoPath")

                // Save thumbnail as Data
                let imageData = thumbnail.pngData()
                newRecording.setValue(imageData, forKey: "thumbnail")

                // Save duration and tag as String
                newRecording.setValue(duration, forKey: "duration")
                newRecording.setValue(tag, forKey: "tag")
            do {
                try context.save()
                print("Recording saved to Core Data")
            } catch {
                print("Error saving recording: \(error.localizedDescription)")
            }
            print("Recording saved with tag: \(tag)")
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }

    private func formatDuration(_ duration: Int) -> String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    
    private func startTimer() {
        recordingTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateRecordingTime), userInfo: nil, repeats: true)
    }
    
    @objc private func updateRecordingTime() {
        recordingDuration += 1
        let minutes = recordingDuration / 60
        let seconds = recordingDuration % 60
        timeLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func stopTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        timeLabel.text = "00:00"
    }
    
    
    func updateUIForRecording() {
        recordImage.image = UIImage(systemName: "stop.circle.fill")?.withRenderingMode(.alwaysTemplate)
        recordImage.tintColor = .red
        rotateCameraImage.isHidden = true
    }
    
    func updateUIForStopped() {
        DispatchQueue.main.async {
            self.recordImage.image = UIImage(systemName: "record.circle.fill")?.withRenderingMode(.alwaysTemplate)
            self.recordImage.tintColor = .white
            self.rotateCameraImage.isHidden = false
        }
    }
    
    @objc private func toggleCamera(_ sender: UITapGestureRecognizer) {
        let secondViewController = RecordingGridViewController()
        present(secondViewController, animated: true, completion: nil)
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        stopTimer()
        if let error = error {
            print("Error recording: \(error.localizedDescription)")
        } else {
            // Save the recorded video and audio to Photo Library
            UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path, self, #selector(videoSavedToLibrary(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    
    @objc func videoSavedToLibrary(_ videoPath: String?, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("Error saving video: \(error.localizedDescription)")
        } else {
            print("Video saved successfully!")
        }
    }
}

extension FaceEditorViewController {
    func setupFaceTracking() {
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let config = ARFaceTrackingConfiguration()
        sceneView.session.run(config)
    }
    
}

extension FaceEditorViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        
        let device: MTLDevice!
        device = MTLCreateSystemDefaultDevice()
        guard let faceAnchor = anchor as? ARFaceAnchor else {
            return nil
        }
        let faceGeometry = ARSCNFaceGeometry(device: device)
        let node = SCNNode(geometry: faceGeometry)
        node.geometry?.firstMaterial?.fillMode = .lines
        node.geometry?.firstMaterial?.transparency = 0.0
        
        let mustacheNode = FaceNode(with: mustacheImages)
        mustacheNode.name = "mustache"
        node.addChildNode(mustacheNode)
        
        updateFeatures(for: node, using: faceAnchor)
        
        return node
    }
    
    func renderer(
        _ renderer: SCNSceneRenderer,
        didUpdate node: SCNNode,
        for anchor: ARAnchor) {
            guard let faceAnchor = anchor as? ARFaceAnchor,
                  let faceGeometry = node.geometry as? ARSCNFaceGeometry else {
                return
            }
            
            faceGeometry.update(from: faceAnchor.geometry)
            updateFeatures(for: node, using: faceAnchor)
        }
    
    func updateFeatures(for node: SCNNode, using anchor: ARFaceAnchor) {
        print(featureIndices)
        let mustacheIndices = [[3]]
        for (feature, indices) in zip(features, mustacheIndices) {
            let child = node.childNode(withName: feature, recursively: false) as? FaceNode
            let vertices = indices.map { anchor.geometry.vertices[$0] }
            child?.updatePosition(for: vertices)
        }
    }
    
}
