//
//  ArticleListCell.swift
//  cnBetaReader
//
//  Created by Shilei Tian on 2/1/16.
//  Copyright © 2016 Shilei Tian. All rights reserved.
//

import UIKit

class ArticleListCell: UITableViewCell {
  
  @IBOutlet weak var thumbnailView: UIImageView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var timeLabel: UILabel!
  @IBOutlet weak var commentsCountLabel: UILabel!
  
  var downloadTask: URLSessionDownloadTask?
  
  override func prepareForReuse() {
    downloadTask?.cancel()
    downloadTask = nil
    
    thumbnailView.image = nil
    titleLabel.text = nil
    timeLabel.text = nil
    commentsCountLabel.text = nil
  }
  
  // MARK: - User Function
  
  func configureForArticleListCell(_ article: Article) {
    titleLabel.text = article.title
    timeLabel.text = article.time
    commentsCountLabel.text = article.commentsCount
    if article.image == nil {
      if let url = URL(string: article.thumbURL) {
        let session = URLSession.shared
        let downloadTask = session.downloadTask(with: url, completionHandler: { url, response, error in
          if error == nil, let url = url, let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
            DispatchQueue.main.async {
              article.image = image
              self.thumbnailView.image = article.image
            }
          }
        })
        downloadTask.resume()
        self.downloadTask = downloadTask
      }
    } else {
      thumbnailView.image = article.image
    }
  }
  
}
