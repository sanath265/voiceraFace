import UIKit
import AVKit

class RecordingGridCollectionViewCell: UICollectionViewCell {
    
    var buttonAction: ((Int) -> Void)?
    var index: Int?
    
    @IBOutlet private var thumbnailImageView: UIImageView! {
        didSet {
            thumbnailImageView.contentMode = .scaleAspectFill
            thumbnailImageView.clipsToBounds = true
        }
    }

    @IBOutlet private var durationLabel: UILabel! {
        didSet {
            durationLabel.font = UIFont.systemFont(ofSize: 12,
                                                   weight: .bold)
            durationLabel.textColor = .white
            durationLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            durationLabel.textAlignment = .center
            durationLabel.layer.cornerRadius = 5
            durationLabel.clipsToBounds = true
        }
    }

    @IBOutlet private var tagLabel: UILabel! {
        didSet {
            tagLabel.font = UIFont.systemFont(ofSize: 12)
            tagLabel.textColor = .darkGray
            tagLabel.textAlignment = .left
        }
    }

    @IBOutlet private var editButton: UIButton! {
        didSet {
            editButton.setTitle("Edit", for: .normal)
            editButton.layer.cornerRadius = 5
            editButton.clipsToBounds = true
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configure(with recording: Recording,
                   index: Int) {
        thumbnailImageView.image = recording.thumbnail
        durationLabel.text = recording.duration
        tagLabel.text = recording.tag
        self.index = index
    }

    @IBAction func editButtontapped(_ sender: UIButton) {
        if let action  = buttonAction {
            action(index ?? 0)
        }
    }
}
