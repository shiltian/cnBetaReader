//
//  ChecklistViewController.swift
//  Checklists
//
//  Created by Shilei Tian on 1/19/16.
//  Copyright © 2016 TSL. All rights reserved.
//

import UIKit
import CoreData

class ArticleListViewController: UITableViewController, NSFetchedResultsControllerDelegate {
  
  private var fetchResultController: NSFetchedResultsController<ArticleMO>!
  private var articlesList: [ArticleMO] = []
  private let fetchRequest: NSFetchRequest<ArticleMO> = ArticleMO.fetchRequest()
  private let httpFetcher = HTTPFetcher()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Init the fetch result controller
    initFetchResultController()
    
    // Add the refresh control
    refreshControl = UIRefreshControl()
    if let refreshControl = refreshControl {
      refreshControl.addTarget(self, action: #selector(ArticleListViewController.updateTimeline),
                               for: .valueChanged)
      refreshControl.attributedTitle = NSAttributedString.init(string: "下拉更新")
      tableView.addSubview(refreshControl)
    }
    tableView.setContentOffset(CGPoint(x: 0, y: -44), animated: true)
    refreshControl?.beginRefreshing()
    refreshControl?.sendActions(for: .valueChanged)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    tableView.reloadData()
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
  
  override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if scrollView == tableView,
      (scrollView.contentOffset.y + scrollView.frame.size.height) >= scrollView.contentSize.height {
      debugPrint("load more")
      loadMoreTimeline()
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
  
  private func configureDetailsForCell(_ cell: ArticleListCell, withArticleListItem item: ArticleMO) {
    cell.configureForArticleListCell(item)
  }
  
  private func fetchDataFromLocalStorage() {
    let limit = articlesList.count + 30
    fetchRequest.fetchLimit = limit
    do {
      try fetchResultController.performFetch()
      if let fetchedObjects = fetchResultController.fetchedObjects {
        articlesList = fetchedObjects
        tableView.reloadData()
      }
    } catch {
      presentAlertView(message: error.localizedDescription, present: present)
    }
    // End freshing if needed
    endRefreshControl()
  }
  
  private func endRefreshControl() {
    if let refreshControl = refreshControl, refreshControl.isRefreshing {
      refreshControl.endRefreshing()
    }
  }
  
  private func initFetchResultController() {
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "time", ascending: false)]
    if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
      let context = appDelegate.persistentContainer.viewContext
      fetchResultController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                         managedObjectContext: context, sectionNameKeyPath: nil,
                                                         cacheName: nil)
      fetchResultController.delegate = self
    }
  }
  
  private func loadMoreTimeline() {
    httpFetcher.fetchTimeline(loadMore: true, handler: fetchDataHandler(result:))
  }
  
  @objc private func updateTimeline() {
    httpFetcher.fetchTimeline(loadMore: false, handler: fetchDataHandler(result:))
  }
  
  // MARK: - Error handler
  
  private func fetchDataHandler(result: AsyncResult) {
    switch result {
    case .Success:
      fetchDataFromLocalStorage()
    case .Failure(let error):
      // debug info
      debugPrint(error)
      // End freshing if needed
      endRefreshControl()
      // present alert pop up view
      presentAlertView(message: error.localizedDescription, present: present)
    }
  }
}
