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
  
  weak var article: ArticleMO!
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
  
  func configureForArticleListCell(_ article: ArticleMO) {
    self.article = article
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MM-dd HH:mm"
    titleLabel.text = article.title
    if article.read {
      titleLabel.textColor = UIColor.gray
    } else {
      titleLabel.textColor = UIColor.black
    }
    timeLabel.text = dateFormatter.string(from: article.time! as Date)
    commentsCountLabel.text = "\(article.commentCount)"
    
    setThumbnail()
  }
  
  private func setThumbnail() {
    if let thumb = article.thumb {
      thumbnailView.image = UIImage(data: thumb)
    } else {
      let httpFetcher = HTTPFetcher()
      downloadTask = httpFetcher.fetchThumbnail(article: article, handler: fetchDataHandler)
    }
  }
  
  private func fetchDataHandler(result: AsyncResult) {
    switch result {
    case .Success:
      setThumbnail()
    case .Failure(let error):
      // debug info
      debugPrint(error)
    }
  }
}
