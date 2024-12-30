//
//  FaceEditorCollectionViewCell.swift
//  voicera
//
//  Created by sanath kavatooru on 30/12/24.
//

import UIKit

class FaceEditorCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var moustacheImage: UIImageView! {
        didSet {
            moustacheImage.backgroundColor = .white
            moustacheImage.layer.cornerRadius = moustacheImage.frame.height / 2.0
        }
    }
    @IBOutlet weak var moustacheTitle: UILabel! {
        didSet {
            moustacheTitle.textColor = .white
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setup(imageName: String?, imageTitle: String?) {
        
        if let imageName {
            moustacheImage.image = UIImage(named: imageName)
        }
        
        if let imageTitle {
            moustacheTitle.text = imageTitle
        }
        
    }

}
