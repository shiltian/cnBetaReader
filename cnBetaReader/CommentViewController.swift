//
//  CommentViewController.swift
//  cnBetaReader
//
//  Created by Shilei Tian on 22/06/2017.
//  Copyright © 2017 TSL. All rights reserved.
//

import UIKit

class CommentViewController: UIViewController {
    
    var article: ArticleMO!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        fetchComments()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - User defined functions
    
    func fetchComments() {
        let httpFetcher = HTTPFetcher()
        httpFetcher.fetchCommentsOfArticle(article: article, completionHandler: updateView, errorHandler: errorHandler)
    }
    
    func updateView() {
        if let comments = article.comments {
            print("length: \(comments.count)")
            for comment in comments {
                if let comment = comment as? CommentMO {
                    print(comment.content)
                }
            }
        }
    }
    
    func errorHandler(errorMessage: String) {
        print(errorMessage)
        let alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

}
