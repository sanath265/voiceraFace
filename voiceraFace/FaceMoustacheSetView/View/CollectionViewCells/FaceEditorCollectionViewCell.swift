//
//  FaceEditorCollectionViewCell.swift
//  voicera
//
//  Created by sanath kavatooru on 30/12/24.
//

import UIKit

class FaceEditorCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var moustacheImage: UIImageView!
    @IBOutlet weak var moustacheTitle: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setup(imageName: String?, imageTitle: String?) {
        
        if let imageName {
            moustacheImage.image = UIImage(named: "imageName")
        }
        
        if let imageTitle {
            moustacheTitle.text = imageTitle
        }
        
    }

}
