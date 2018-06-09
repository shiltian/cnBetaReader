//
//  File.swift
//  cnBetaReader
//
//  Created by Shilei Tian on 2/17/16.
//  Copyright © 2016 TSL. All rights reserved.
//

import CoreData
import UIKit
import WebKit

class ArticleViewController: UIViewController {
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var commentButton: UIBarButtonItem!
    
    var article: ArticleMO!
    var articleContent: ArticleContentMO?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the comment button appearance
        commentButton.title = "\(article.commentCount)评论"
        commentButton.setTitleTextAttributes([NSAttributedStringKey.font: UIFont.systemFont(ofSize: 15)], for: .normal)
        let barButtonImage = UIImage(named: "bar_button")?.resizableImage(withCapInsets: UIEdgeInsets(top: 0, left: 10,
                                                                                                      bottom: 0,
                                                                                                      right: 10))
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
    
    private func loadArticleContent() {
        if let content = article.content {
            articleContent = content
            updateWebView()
        } else {
            guard let _ = article.url else {
                // present alert pop up view
                presentAlertView(message: "the article url is nil", present: present)
                return
            }
            let httpFetcher = HTTPFetcher()
            httpFetcher.fetchContent(article: article, handler: fetchDataHandler(result:))
        }
    }
    
    private func updateWebView() {
        guard let articleContent = articleContent else {
            presentAlertView(message: "ariticleContent is nil", present: present)
            return
        }
        guard let htmlURL = Bundle.main.url(forResource: "article", withExtension: "html") else {
            presentAlertView(message: "htmlURL is nil", present: present)
            return
        }
        do {
            var htmlTemplate = try String(contentsOf: htmlURL, encoding: .utf8)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM-dd HH:mm"
            htmlTemplate = htmlTemplate.replacingOccurrences(of: "<!-- title -->", with: article.title!)
            htmlTemplate = htmlTemplate.replacingOccurrences(of: "<!-- time -->",
                                                             with: dateFormatter.string(from: article.time! as Date))
            htmlTemplate = htmlTemplate.replacingOccurrences(of: "<!-- summary -->", with: articleContent.summary!)
            htmlTemplate = htmlTemplate.replacingOccurrences(of: "<!-- content -->", with: articleContent.content!)
            webView.loadHTMLString(htmlTemplate, baseURL: Bundle.main.bundleURL)
        } catch {
            // present alert pop up view
            presentAlertView(message: error.localizedDescription, present: present)
        }
    }
    
    // MARK: - Error handler

    private func fetchDataHandler(result: AsyncResult) {
        switch result {
        case .Success:
            loadArticleContent()
        case .Failure(let error):
            // debug info
            print(error)
            // present alert pop up view
            presentAlertView(message: error.localizedDescription, present: present)
        }
    }
    
}
