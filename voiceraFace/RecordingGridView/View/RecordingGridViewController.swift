import UIKit
import CoreData
import AVKit

class RecordingGridViewController: UIViewController {
    
    var buttonAction: (() -> Void)?
    
    @IBOutlet private var titleLabel: UILabel! {
        didSet {
            titleLabel.textColor = .black
        }
    }
    
    @IBOutlet private var collectionView: UICollectionView! {
        didSet {
            let nib = UINib(nibName: "RecordingGridCollectionViewCell",
                            bundle: nil)
            collectionView.register(nib,
                                    forCellWithReuseIdentifier: "RecordingGridCollectionViewCell")
            collectionView.dataSource = self
            collectionView.delegate = self
            collectionView.backgroundColor = .white
        }
    }
    
    @IBOutlet private var recordNewVideoButton: UIButton! {
        didSet {
            recordNewVideoButton.layer.cornerRadius = 5
            recordNewVideoButton.clipsToBounds = true
            recordNewVideoButton.layer.borderColor = UIColor.red.cgColor
            recordNewVideoButton.layer.borderWidth = 1
        }
    }
    
    @IBOutlet private var closeButton: UIButton! {
        didSet {
            closeButton.layer.cornerRadius = 5
            closeButton.clipsToBounds = true
        }
    }
    
    private var recordings: [Recording] {
        return fetchRecordings() ?? []
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Recordings"
        DispatchQueue.main.async { [weak self] in
            self?.collectionView.reloadData()
        }
    }
    
    @IBAction func recordNewVideoButtontapped(_ sender: UIButton) {
        if let action  = buttonAction {
            action()
            dismiss(animated: true)
        }
    }
    
    @IBAction func closeButtontapped(_ sender: UIButton) {
        dismiss(animated: true)
    }
}

extension RecordingGridViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return recordings.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RecordingGridCollectionViewCell",
                                                            for: indexPath) as? RecordingGridCollectionViewCell else { return UICollectionViewCell() }
        let recording = recordings[indexPath.item]
        cell.configure(with: recording,
                       index: indexPath.item)
        cell.buttonAction = { [weak self] index in
            guard let self else { return }
            self.editButtonTapped(selectedIndexPath: index)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        debugPrint("Selected recording: \(recordings[indexPath.item].videoPath)")
        let selectedVideoURL = recordings[indexPath.item].videoPath
        playVideo(url: selectedVideoURL)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width / 2 - 15,
                      height: 200)
    }
    
    func fetchRecordings() -> [Recording]? {
        let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Recordings")
        
        do {
            guard let results = try context?.fetch(fetchRequest) else { return nil }
            var recordings = [Recording]()
            
            for result in results {
                if let videoPathString = result.value(forKey: "videoPath") as? String,
                   let thumbnailData = result.value(forKey: "thumbnail") as? Data,
                   let duration = result.value(forKey: "duration") as? String,
                   let tag = result.value(forKey: "tag") as? String,
                   let videoPath = URL(string: videoPathString),
                   let thumbnail = UIImage(data: thumbnailData) {
                    
                    let recording = Recording(videoPath: videoPath,
                                              thumbnail: thumbnail,
                                              duration: duration,
                                              tag: tag)
                    recordings.append(recording)
                }
            }
            return recordings
        } catch {
            debugPrint("Failed fetching recordings: \(error)")
            return nil
        }
    }
    
    private func editButtonTapped(selectedIndexPath: Int) {
        let recording = recordings[selectedIndexPath]
        
        let alert = UIAlertController(title: "Edit Tag",
                                      message: "Enter a new tag for the recording.",
                                      preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = recording.tag
            textField.placeholder = "New tag"
        }
        alert.addAction(UIAlertAction(title: "Cancel",
                                      style: .cancel,
                                      handler: nil))
        alert.addAction(UIAlertAction(title: "Save",
                                      style: .default,
                                      handler: { [weak self] _ in
            guard let self = self, let newTag = alert.textFields?.first?.text, !newTag.isEmpty else { return }
            self.updateTag(for: recording,
                           newTag: newTag,
                           index: selectedIndexPath)
        }))
        
        present(alert,
                animated: true,
                completion: nil)
    }
    
    private func updateTag(for recording: Recording,
                           newTag: String,
                           index: Int) {
        let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Recordings")
        fetchRequest.predicate = NSPredicate(format: "videoPath == %@", recording.videoPath.absoluteString)
        
        do {
            guard let results = try context?.fetch(fetchRequest),
                  let result = results.first else { return }
            result.setValue(newTag, forKey: "tag")
            try context?.save()
            DispatchQueue.main.async { [weak self] in
                self?.collectionView.reloadData()
                self?.showAlert(title: "Success", message: "Tag updated successfully.")
            }
        } catch {
            debugPrint("Failed updating tag: \(error)")
            DispatchQueue.main.async { [weak self] in
                self?.showAlert(title: "Error", message: "Failed to update the tag.")
            }
        }
    }
    
    private func showAlert(title: String,
                           message: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let alert = UIAlertController(title: title,
                                          message: message,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK",
                                          style: .default,
                                          handler: nil))
            self.present(alert,
                         animated: true,
                         completion: nil)
        }
    }
    
    func playVideo(url: URL) {
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        DispatchQueue.main.async { [weak self] in
            self?.present(playerViewController, animated: true) {
                player.play()
            }
        }
    }
}
