//
//  File.swift
//  cnBetaReader
//
//  Created by Shilei Tian on 2/17/16.
//  Copyright © 2016 TSL. All rights reserved.
//

import UIKit
import Kanna
import CoreData

class ArticleViewController: UIViewController {
    
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var commentButton: UIBarButtonItem!
    
    var article: ArticleMO!
    var articleContent: ArticleContentMO?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the comment button appearance
        commentButton.title = "\(article.commentCount)评论"
        commentButton.setTitleTextAttributes([NSFontAttributeName: UIFont.systemFont(ofSize: 15)], for: .normal)
        let barButtonImage = UIImage(named: "bar_button")?.resizableImage(withCapInsets: UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10))
        commentButton.setBackgroundImage(barButtonImage, for: .normal, barMetrics: .default)
        
        loadArticleContent()
        article.read = true
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showComments" {
            let controller = segue.destination as! CommentViewController
            controller.article = article
        }
    }
    
    // MARK: - User defined functions
    
    func loadArticleContent() {
        if let content = article.content {
            articleContent = content
            updateWebView()
        } else {
            let httpFetcher = HTTPFetcher()
            httpFetcher.fetchContent(article: article, articleURL: article.url!, completionHandler: loadArticleContent, errorHandler: fetchDataError)
        }
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
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM-dd HH:mm"
            htmlTemplate = htmlTemplate.replacingOccurrences(of: "<!-- title -->", with: article.title!)
            htmlTemplate = htmlTemplate.replacingOccurrences(of: "<!-- time -->", with: dateFormatter.string(from: article.time! as Date))
            htmlTemplate = htmlTemplate.replacingOccurrences(of: "<!-- summary -->", with: articleContent!.summary!)
            htmlTemplate = htmlTemplate.replacingOccurrences(of: "<!-- content -->", with: articleContent!.content!)
            webView.loadHTMLString(htmlTemplate, baseURL: Bundle.main.bundleURL)
        }
    }
    
    func fetchDataError(errorMessage error: String) {
        print(error)
        let alert = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
}
