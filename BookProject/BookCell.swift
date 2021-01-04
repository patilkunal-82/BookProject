//
//  BookCell.swift
//  BookProject
//
//  Created by Kunal Patil on 1/3/21.
//

import UIKit

class BookCell: UICollectionViewCell {
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var cover: UIImageView!
    var bookKey: String = ""
}
