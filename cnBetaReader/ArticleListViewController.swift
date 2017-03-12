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
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Add the refresh control
    refreshControl = UIRefreshControl()
    refreshControl?.addTarget(self, action: #selector(ArticleListViewController.getData), for: UIControlEvents.valueChanged)
    tableView.addSubview(refreshControl!)
    
    refreshControl?.beginRefreshing()
    
    fetchDataFromLocalStorage()
  }
  
  // MARK: - Init
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
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
  
  // MARK: - Navigation delegate
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "ShowArticle" {
      let controller = segue.destination as! ArticleViewController
      controller.article = sender as! ArticleMO
    }
  }
  
  // MARK: - Custom Function
  
  func configureDetailsForCell(_ cell: ArticleListCell, withArticleListItem item: ArticleMO) {
    cell.configureForArticleListCell(item)
  }
  
  func fetchDataFromLocalStorage() {
    let fetchRequest: NSFetchRequest<ArticleMO>! = ArticleMO.fetchRequest()
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "time", ascending: false)]
    if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
      let context = appDelegate.persistentContainer.viewContext
      fetchResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
      fetchResultController.delegate = self
      
      do {
        try fetchResultController.performFetch()
        if let fetchedObjects = fetchResultController.fetchedObjects {
          articlesList = fetchedObjects
          tableView.reloadData()
        }
      } catch {
        print(error)
      }
      refreshControl?.endRefreshing()
    }
  }
  
  func getData() {
    let httpFetcher = HTTPFetcher()
    httpFetcher.fetchHomePage(completionHandler: fetchDataFromLocalStorage)
  }
  
}

