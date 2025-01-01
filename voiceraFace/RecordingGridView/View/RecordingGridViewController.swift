//
//  RecordingGridViewController.swift
//  voiceraFace
//
//  Created by sanath kavatooru on 01/01/25.
//

import UIKit
import CoreData
import AVKit

class RecordingGridViewController: UIViewController {

    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width / 2 - 15, height: 200)
        return UICollectionView(frame: .zero, collectionViewLayout: layout)
    }()
    
    private var recordings: [Recording] {
        return fetchRecordings() ?? []
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Recordings"

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(RecordingGridCollectionViewCell.self, forCellWithReuseIdentifier: RecordingGridCollectionViewCell.reuseIdentifier)
        collectionView.backgroundColor = .white

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        collectionView.reloadData()
    }
}

extension RecordingGridViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return recordings.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RecordingGridCollectionViewCell.reuseIdentifier,
                                                            for: indexPath) as? RecordingGridCollectionViewCell else {
            return UICollectionViewCell()
        }
        let recording = recordings[indexPath.item]
        cell.configure(with: recording)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Selected recording: \(recordings[indexPath.item].tag)")
    }
    
    func fetchRecordings() -> [Recording]? {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Recordings")

        do {
            let results = try context.fetch(fetchRequest)
            var recordings = [Recording]()

            for result in results {
                if let videoPathString = result.value(forKey: "videoPath") as? String,
                   let thumbnailData = result.value(forKey: "thumbnail") as? Data,
                   let duration = result.value(forKey: "duration") as? String,
                   let tag = result.value(forKey: "tag") as? String {
                    
                    let videoPath = URL(string: videoPathString)!
                    let thumbnail = UIImage(data: thumbnailData)!
                    let recording = Recording(videoPath: videoPath, thumbnail: thumbnail, duration: duration, tag: tag)
                    recordings.append(recording)
                }
            }
            return recordings
        } catch {
            print("Failed fetching recordings: \(error)")
            return nil
        }
    }

}
