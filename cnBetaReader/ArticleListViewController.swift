//
//  ChecklistViewController.swift
//  Checklists
//
//  Created by Shilei Tian on 1/19/16.
//  Copyright © 2016 TSL. All rights reserved.
//

import UIKit
import Kanna
import CoreData

class ArticleListViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    var fetchResultController: NSFetchedResultsController<ArticleMO>!
    var articlesList: [ArticleMO] = []
    let fetchRequest: NSFetchRequest<ArticleMO> = ArticleMO.fetchRequest()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Init the fetch result controller
        initFetchResultController()
        
        // Add the refresh control
        refreshControl = UIRefreshControl()
        if let refreshControl = refreshControl {
            refreshControl.addTarget(self, action: #selector(ArticleListViewController.getData), for: UIControlEvents.valueChanged)
            tableView.addSubview(refreshControl)
            refreshControl.beginRefreshing()
        }
        
        fetchDataFromLocalStorage()
    }
    
    // MARK: - Init
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func initFetchResultController() {
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "time", ascending: false)]
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            let context = appDelegate.persistentContainer.viewContext
            fetchResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
            fetchResultController.delegate = self
        }
    }
    
    // MARK: - Data Source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return articlesList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ArticleListCell", for: indexPath) as! ArticleListCell
        let item = articlesList[indexPath.row]
        configureDetailsForCell(cell, withArticleListItem: item)
        return cell
    }
    
    // MARK: - Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let article = articlesList[indexPath.row]
        performSegue(withIdentifier: "ShowArticle", sender: article)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView == tableView {
            if ((scrollView.contentOffset.y + scrollView.frame.size.height) >= scrollView.contentSize.height + 40) {
                print("Ready to load more...")
                loadMore()
            }
        }
        
    }
    
    // MARK: - Navigation delegate
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowArticle" {
            let controller = segue.destination as! ArticleViewController
            controller.article = sender as! ArticleMO
        }
    }
    
    // MARK: - User defined function
    
    func configureDetailsForCell(_ cell: ArticleListCell, withArticleListItem item: ArticleMO) {
        cell.configureForArticleListCell(item)
    }
    
    func fetchDataFromLocalStorage() {
        var limit = 30
        if articlesList.count != 0 {
            limit += 30
        }
        fetchRequest.fetchLimit = limit
        do {
            try fetchResultController.performFetch()
            if let fetchedObjects = fetchResultController.fetchedObjects {
                articlesList = fetchedObjects
                tableView.reloadData()
            }
        } catch {
            print(error)
        }
        // End freshing if needed
        if refreshControl != nil && refreshControl!.isRefreshing {
            refreshControl!.endRefreshing()
        }
    }
    
    func getData() {
        let httpFetcher = HTTPFetcher()
        httpFetcher.fetchHomePage(completionHandler: fetchDataFromLocalStorage, errorHandler: fetchDataError)
    }
    
    func loadMore() {
        let httpFetcher = HTTPFetcher()
//        httpFetcher.loadMore(completionHandler: fetchDataFromLocalStorage, errorHandler: fetchDataError)
    }
    
    // MARK: - Error handler
    
    func fetchDataError(errorMessage error: String) {
        print(error)
        // End freshing if needed
        if refreshControl != nil && refreshControl!.isRefreshing {
            refreshControl!.endRefreshing()
        }
        let alert = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
}

