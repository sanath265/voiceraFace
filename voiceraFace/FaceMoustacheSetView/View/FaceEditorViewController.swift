import UIKit
import AVFoundation
import ARKit

class FaceEditorViewController: UIViewController {
    
    private var mustacheImages: [String] = [ "mustache1",
                                             "mustache2",
                                             "mustache3" ]
    let features = ["mustache"]
    var featureIndices = [[6]]
    private var selectedMustacheIndex = 0
    private var captureSession: AVCaptureSession!
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    private var movieOutput: AVCaptureMovieFileOutput!
    private var isRecording = false
    private var isUsingFrontCamera = true
    private var recordingTimer: Timer?
    private var recordingDuration: Int = 0
    private var arSession: ARSession!
    private var arAnchor: ARFaceAnchor!
    private var mustacheNode: SCNNode?
    
    
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
//        setupRecordingSession()
        setupUI()
        sceneView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        DispatchQueue.global(qos: .background).async { [weak self] in
//            
//            if let self,
//               let captureSession = self.captureSession,
//               captureSession.isRunning == false {
//                self.captureSession.startRunning()
//            }
//        }
        setupFaceTracking()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning()
        sceneView.session.pause()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        videoPreviewLayer?.frame = sceneView.bounds
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
    
    private func setupRecordingSession() {
        captureSession = AVCaptureSession()
        
        // Camera input
        guard let videoDevice = AVCaptureDevice.default(for: .video) else { return }
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            }
        } catch {
            print("Failed to create video input: \(error)")
            return
        }
        
        // Audio input
        guard let audioDevice = AVCaptureDevice.default(for: .audio) else { return }
        do {
            let audioInput = try AVCaptureDeviceInput(device: audioDevice)
            if captureSession.canAddInput(audioInput) {
                captureSession.addInput(audioInput)
            }
        } catch {
            print("Failed to create audio input: \(error)")
            return
        }
        
        // Video and Audio outputs
        movieOutput = AVCaptureMovieFileOutput()
        if captureSession.canAddOutput(movieOutput) {
            captureSession.addOutput(movieOutput)
        }
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        if let videoPreviewLayer {
            videoPreviewLayer.frame = sceneView.frame
            videoPreviewLayer.videoGravity = .resizeAspectFill
            sceneView.layer.addSublayer(videoPreviewLayer)
        }
    }
    
    @objc private func startRecording(_ sender: UITapGestureRecognizer) {
        if isRecording {
            stopRecording()
        } else {
            let filePath = NSTemporaryDirectory().appending("video-\(Date()).mov")
            let outputURL = URL(fileURLWithPath: filePath)
            
            DispatchQueue.global(qos: .background).async {
                if !self.captureSession.isRunning {
                    self.captureSession.startRunning()
                }
                
                DispatchQueue.main.async {
                    self.movieOutput.startRecording(to: outputURL, recordingDelegate: self)
                    self.isRecording = true
                    self.recordingDuration = 0 // Reset the duration
                    self.startTimer()
                    self.updateUIForRecording()
                }
            }
        }
    }
    
    private func stopRecording() {
        movieOutput.stopRecording()
        isRecording = false
        stopTimer()
        updateUIForStopped()
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
        recordImage.image = UIImage(systemName: "record.circle.fill")?.withRenderingMode(.alwaysTemplate)
        recordImage.tintColor = .white
        rotateCameraImage.isHidden = false
    }
    
    @objc private func toggleCamera(_ sender: UITapGestureRecognizer) {
        guard let currentInput = captureSession.inputs.first as? AVCaptureDeviceInput else { return }
        
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        
        captureSession.removeInput(currentInput)
        
        let newCameraDevice: AVCaptureDevice?
        if currentInput.device.position == .back {
            newCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        } else {
            newCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        }
        
        guard let newDevice = newCameraDevice,
              let newInput = try? AVCaptureDeviceInput(device: newDevice),
              captureSession.canAddInput(newInput) else { return }
        
        captureSession.addInput(newInput)
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
