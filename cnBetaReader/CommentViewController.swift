//
//  CommentViewController.swift
//  cnBetaReader
//
//  Created by Shilei Tian on 22/06/2017.
//  Copyright © 2017 TSL. All rights reserved.
//

import UIKit

class CommentViewController: UITableViewController {
    
    var article: ArticleMO!
    var comments: [CommentMO]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 150
        
        // Do any additional setup after loading the view.
        fetchComments()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Data Source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let comments = comments, comments.count != 0 {
            return comments.count
        } else {
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let comments = comments, comments.count != 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath) as! CommentCell
            let item = comments[indexPath.row]
            configureDetailsForCell(cell: cell, withArticleListItem: item)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "NoCommentCell", for: indexPath)
            return cell
        }
    }
    
    // MARK: - User defined functions
    
    private func fetchComments() {
        let httpFetcher = HTTPFetcher()
        httpFetcher.fetchComments(article: article, handler: fetchDataHandler)
    }
    
    private func updateView() {
        comments = article.comments?.allObjects as? [CommentMO]
        comments?.sort { $0.time!.timeIntervalSinceReferenceDate > $1.time!.timeIntervalSinceReferenceDate }
        tableView.reloadData()
    }
    
    // MARK: - Error handler
    
    private func fetchDataHandler(result: AsyncResult) {
        switch result {
        case .Success:
            updateView()
        case .Failure(let error):
            // debug info
            print(error)
            // present alert pop up view
            presentAlertView(message: error.localizedDescription, present: present)
        }
    }
    
    private func configureDetailsForCell(cell: CommentCell, withArticleListItem item: CommentMO) {
        cell.configureForCell(comment: item)
    }
    
}
