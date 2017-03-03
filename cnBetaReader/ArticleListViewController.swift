//
//  ChecklistViewController.swift
//  Checklists
//
//  Created by Shilei Tian on 1/19/16.
//  Copyright © 2016 TSL. All rights reserved.
//

import UIKit
import Kanna

class ArticleListViewController: UITableViewController {
  
  var articlesList: [Article]
    var isLoading = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // 添加下拉刷新
    refreshControl = UIRefreshControl()
    refreshControl?.addTarget(self, action: #selector(ArticleListViewController.getData), for: UIControlEvents.valueChanged)
    tableView.addSubview(refreshControl!)
    
    refreshControl?.beginRefreshing()
    getData()
    
//    let cellNib = UINib(nibName: "ArticleListCell", bundle: nil)
//    tableView.register(cellNib, forCellReuseIdentifier: "ArticleListCell")
    
    //    cellNib = UINib(nibName: "LoadingCell", bundle: nil)
    //    tableView.registerNib(cellNib, forCellReuseIdentifier: "LoadingCell")
  }
  
  // MARK: Init
  
  required init?(coder aDecoder: NSCoder) {
    articlesList = [Article]()
    super.init(coder: aDecoder)
  }
  
  // MARK: Data Source
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    //    if isLoading {
    //      return 1
    //    } else {
    return articlesList.count
    //    }
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    //    if isLoading {
    //      let cell = tableView.dequeueReusableCellWithIdentifier("LoadingCell", forIndexPath: indexPath)
    //      let spinner = cell.viewWithTag(100) as! UIActivityIndicatorView
    //      spinner.startAnimating()
    //      return cell
    //    } else {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ArticleListCell", for: indexPath) as! ArticleListCell
    let item = articlesList[indexPath.row]
    configureDetailsForCell(cell, withArticleListItem: item)
    return cell
    //    }
  }
  
  // MARK: Delegate
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let article = articlesList[indexPath.row]
    performSegue(withIdentifier: "ShowArticle", sender: article)
    tableView.deselectRow(at: indexPath, animated: true)
  }
  
  // MARK: - Navigation delegate
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "ShowArticle" {
      let controller = segue.destination as! ArticleViewController
      controller.article = sender as! Article
    }
  }
  
  // MARK: Custom Function
  
  func configureDetailsForCell(_ cell: ArticleListCell, withArticleListItem item: Article) {
    cell.configureForArticleListCell(item)
  }
  
  func getData() {
    //    isLoading = true
    tableView.reloadData()
    
    let urlString = "http://www.cnbeta.com"
    
    if let url = URL(string: urlString) {
      let task = URLSession.shared.dataTask(with: url) {
        (data, response, error) in
        if let error = error {
          print("Error: \(error)")
        } else if let response = response {
          let html = String(data: data!, encoding: .utf8)
          if let html = html {
            self.parseArticleList(html)
          }
        }
      }
      task.resume()
    }
  }
  
  func parseArticleList(_ data: String?) {
    if let data = data {
      if let doc = HTML(html: data, encoding: .utf8) {
        let articleList = doc.xpath("//div[@class='items-area']/div[@class='item']")
        let regexID: NSRegularExpression?
        do {
          regexID = try NSRegularExpression(pattern: "\\d+", options: [.caseInsensitive])
        } catch {
          regexID = nil
        }
        let regexTime: NSRegularExpression?
        do {
          regexTime = try NSRegularExpression(pattern: "\\d\\d-\\d\\d \\d\\d:\\d\\d", options: [.caseInsensitive])
        } catch {
          regexTime = nil
        }
        let regexCommentCount: NSRegularExpression?
        do {
          regexCommentCount = try NSRegularExpression(pattern: "\\d+次阅读", options: [.caseInsensitive])
        } catch {
          regexCommentCount = nil
        }
        for articleItem in articleList {
          let urlAndTitle = articleItem.at_xpath(".//dl/dt/a")
          let url: String?, title: String?, time: String?, commentCount: String?, id: String?
          if let urlAndTitle = urlAndTitle {
            url = urlAndTitle["href"]!
            title = urlAndTitle.content!
            if  let matchID = regexID?.firstMatch(in: url!, options: [], range: NSMakeRange(0, url!.characters.count)) {
              id = (url! as NSString).substring(with: matchID.range)
            } else {
              id = nil
            }
          } else {
            url = nil
            title = nil
            id = nil
          }
          
          let status = articleItem.at_xpath(".//ul[@class='status']/li")?.content
          if let status = status,
            let matchTime = regexTime?.firstMatch(in: status, options: [], range: NSMakeRange(0, status.characters.count)),
            let matchCommentCount = regexCommentCount?.firstMatch(in: status, options: [], range: NSMakeRange(0, status.characters.count)) {
            time = (status as NSString).substring(with: matchTime.range)
            let commentCountString = (status as NSString).substring(with: matchCommentCount.range)
            commentCount = commentCountString.substring(to: commentCountString.index(commentCountString.endIndex, offsetBy: -3))
          } else {
            time = nil
            commentCount = nil
          }
          
          let thumbURL = articleItem.at_xpath(".//img")?["src"]
          if let id = id, let title = title, let time = time, let commentCount = commentCount, let thumbURL = thumbURL {
            let article = Article()
            article.id = id
            article.thumbURL = thumbURL
            article.time = time
            article.commentsCount = commentCount
            article.title = title
            articlesList.append(article)
          }
          print("ID: \(id)")
          print("Title: \(title)")
          print("Time: \(time)")
          print("Comment count: \(commentCount)")
          print("Thumb URL: \(thumbURL)")
          print("-----------------------------")
          DispatchQueue.main.async {
            self.isLoading = false
            self.refreshControl?.endRefreshing()
            self.tableView.reloadData()
          }
        }
      }
    }
  }
  
}

