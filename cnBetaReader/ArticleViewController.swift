//
//  File.swift
//  cnBetaReader
//
//  Created by Shilei Tian on 2/17/16.
//  Copyright © 2016 TSL. All rights reserved.
//

import UIKit
import Kanna

class ArticleViewController: UIViewController {
  
  @IBOutlet weak var webView: UIWebView!
  @IBOutlet weak var commentButton: UIBarButtonItem!
  
  var article: Article!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if article.content == nil {
      retrieveArticle(articleURL: article.url)
    } else {
      updateWebView()
    }

    // Set the comment button appearance
    commentButton.title = article.commentsCount + "评论"
    commentButton.setTitleTextAttributes([NSFontAttributeName: UIFont.systemFont(ofSize: 15)], for: .normal)
    let barButtonImage = UIImage(named: "bar_button")?.resizableImage(withCapInsets: UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10))
    commentButton.setBackgroundImage(barButtonImage, for: .normal, barMetrics: .default)
  }

  func retrieveArticle(articleURL: String) {
    if let url = URL(string: articleURL) {
      let task = URLSession.shared.dataTask(with: url) {
        (data, response, error) in
        if let error = error {
          print("Error: \(error)")
        } else if response != nil {
          let html = String(data: data!, encoding: .utf8)
          if let html = html {
            var content = self.parseArticle(data: html)
            self.article.summary = content[0]
            self.article.content = String()
            for i in 1..<content.count {
              self.article.content! += content[i]
            }
            self.updateWebView()
          }
        }
      }
      task.resume()
    }
  }

  func parseArticle(data: String) -> [String] {
    var content = [String]()
    if let doc = HTML(html: data, encoding: .utf8) {
      let summary = doc.at_xpath("//div[@class='article-summary']//p")
      if let summary = summary {
        content.append(summary.toHTML!)
      }
      let paras = doc.xpath("//div[@class='article-content']")
      for para in paras {
        content.append(para.toHTML!)
      }
    }
    return content
  }
  
  func updateWebView() {
    let htmlURL = Bundle.main.url(forResource: "article", withExtension: "html")!
    var htmlTemplate: String?
    do {
      htmlTemplate = try String(contentsOf: htmlURL, encoding: .utf8)
    } catch {
      htmlTemplate = nil
    }
    if var htmlTemplate = htmlTemplate {
      htmlTemplate = htmlTemplate.replacingOccurrences(of: "<!-- title -->", with: article.title)
      htmlTemplate = htmlTemplate.replacingOccurrences(of: "<!-- time -->", with: article.time)
      htmlTemplate = htmlTemplate.replacingOccurrences(of: "<!-- summary -->", with: article.summary!)
      htmlTemplate = htmlTemplate.replacingOccurrences(of: "<!-- content -->", with: article.content!)
      webView.loadHTMLString(htmlTemplate, baseURL: Bundle.main.bundleURL)
    }
  }
  
}
