//
//  RecordingGridCollectionViewCell.swift
//  voiceraFace
//
//  Created by sanath kavatooru on 01/01/25.
//

import UIKit
import AVKit

class RecordingGridCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "RecordingGridCollectionViewCell"

    private let thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    private let durationLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        label.textAlignment = .center
        label.layer.cornerRadius = 5
        label.clipsToBounds = true
        return label
    }()

    private let tagLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .darkGray
        label.textAlignment = .left
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(durationLabel)
        contentView.addSubview(tagLabel)
        
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        tagLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            thumbnailImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            thumbnailImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            thumbnailImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            thumbnailImageView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.75),

            durationLabel.bottomAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor, constant: -5),
            durationLabel.trailingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: -5),
            durationLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 60),
            
            tagLabel.topAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor, constant: 5),
            tagLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
            tagLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with recording: Recording) {
        thumbnailImageView.image = recording.thumbnail
        durationLabel.text = recording.duration
        tagLabel.text = recording.tag
    }
}
