//
//  CommentCell.swift
//  cnBetaReader
//
//  Created by Shilei Tian on 28/06/2017.
//  Copyright © 2017 TSL. All rights reserved.
//

import UIKit

class CommentCell: UITableViewCell {
  
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var timeLabel: UILabel!
  @IBOutlet weak var contentTextView: UITextView!
  @IBOutlet weak var dislikeLabel: UILabel!
  @IBOutlet weak var likeLabel: UILabel!
  
  static let dateFormatter = DateFormatter()
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    
    // Configure the view for the selected state
  }
  
  // MARK: - User defined funtion
  func configureForCell(comment: CommentMO) {
    nameLabel.text = "\(comment.name!)[\(comment.from!)]"
    CommentCell.dateFormatter.dateFormat = "MM-dd HH:mm"
    timeLabel.text = "发表于 \(CommentCell.dateFormatter.string(from: comment.time! as Date))"
    contentTextView.text = comment.content
    likeLabel.text = "\(comment.like)"
    dislikeLabel.text = "\(comment.dislike)"
  }
}
