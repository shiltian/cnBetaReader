//
//  File.swift
//  cnBetaReader
//
//  Created by Shilei Tian on 2/17/16.
//  Copyright © 2016 TSL. All rights reserved.
//

import UIKit

class ArticleViewController: UIViewController {
  
  @IBOutlet weak var webView: UIWebView!
  @IBOutlet weak var commentButton: UIBarButtonItem!
  
  var article: Article!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let htmlURL = Bundle.main.url(forResource: "article", withExtension: "html")!
    var htmlTemplate: NSString?
    do {
      htmlTemplate = try NSString(contentsOf: htmlURL, encoding: String.Encoding.utf8.rawValue)
    } catch {
      htmlTemplate = nil
    }
    
    htmlTemplate = htmlTemplate?.replacingOccurrences(of: "<!-- title -->", with: article.title) as NSString?
    htmlTemplate = htmlTemplate?.replacingOccurrences(of: "<!-- time -->", with: article.time) as NSString?
    webView.loadHTMLString((htmlTemplate as? String)!, baseURL: Bundle.main.bundleURL)
    
    commentButton.title = article.commentsCount
  }
  
}
