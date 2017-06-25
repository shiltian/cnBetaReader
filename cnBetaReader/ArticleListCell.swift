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
    
    func configureForArticleListCell(_ article: ArticleMO) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd HH:mm"
        titleLabel.text = article.title
        timeLabel.text = dateFormatter.string(from: article.time! as Date)
        commentsCountLabel.text = "\(article.commentCount)"
        if let thumb = article.thumb {
            thumbnailView.image = UIImage(data: thumb as Data)
        } else {
            if let url = URL(string: article.thumbURL!) {
                let session = URLSession.shared
                let downloadTask = session.downloadTask(with: url, completionHandler: {
                    url, response, error in
                    if let error = error {
                        print("Error occurred: \(error)")
                        return
                    }
                    if let url = url, let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            article.thumb = NSData(data: data)
                            self.thumbnailView.image = image
                            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                                appDelegate.saveContext()
                            }
                        }
                    }
                })
                downloadTask.resume()
                self.downloadTask = downloadTask
            }
        }
    }
    
}
