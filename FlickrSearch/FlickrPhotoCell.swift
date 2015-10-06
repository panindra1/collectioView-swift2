//
//  FlickrPhotoCell.swift
//  FlickrSearch
//
//  Created by panindra Ts on 9/29/15.
//  Copyright © 2015 panindra Ts. All rights reserved.
//

import UIKit

class FlickrPhotoCell: UICollectionViewCell {
    let themeColor = UIColor(red: 0.01, green: 0.41, blue: 0.22, alpha: 1.0)

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selected = false
    }
    
    override var selected : Bool {
        didSet {
            self.backgroundColor = selected ? themeColor : UIColor.blackColor()
        }
    }
}
