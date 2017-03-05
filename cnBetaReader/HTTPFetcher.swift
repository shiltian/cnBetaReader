//
//  HTTPFetcher.swift
//  cnBetaReader
//
//  Created by Shilei Tian on 05/03/2017.
//  Copyright © 2017 TSL. All rights reserved.
//

import Kanna

var loadMoreToken: String? = nil

class HTTPFetcher {
  
  // MARK: - APIs
  
  func fetchHomePage(completionHandler: @escaping ()->Void) {
    let urlString = "http://www.cnbeta.com"
    
    if let url = URL(string: urlString) {
      let task = URLSession.shared.dataTask(with: url) {
        (data, response, error) in
        if let error = error {
          print("Error: \(error)")
        } else if let data = data {
          if let html = String(data: data, encoding: .utf8), let doc = HTML(html: html, encoding: .utf8) {
            // Set the load more token
            let loadMoreTokenElement = doc.at_xpath("//meta[@name='csrf-token']")
            if let homeMoreTokenElement = loadMoreTokenElement {
              loadMoreToken = homeMoreTokenElement.content!
            } else {
              print("Fatal error: fail to load csrf-token.")
              return;
            }
            
            // Set the regex for id, time and comment count
            var regexID: NSRegularExpression?, regexTime: NSRegularExpression?, regexCommentCount: NSRegularExpression?
            do {
              regexID = try NSRegularExpression(pattern: "\\d+", options: [.caseInsensitive])
              regexTime = try NSRegularExpression(pattern: "\\d\\d-\\d\\d \\d\\d:\\d\\d", options: [.caseInsensitive])
              regexCommentCount = try NSRegularExpression(pattern: "\\d+个意见", options: [.caseInsensitive])
            } catch {
              regexID = nil
              regexTime = nil
              regexCommentCount = nil
            }
            
            // Process the downloaded item div
            for itemDiv in doc.xpath("//div[@class='items-area']/div[@class='item']") {
              var article = Article()
              let urlElement = itemDiv.at_xpath(".//dl/dt/a")
              if let urlElement = urlElement {
                article.url = urlElement.toHTML!
                article.title = urlElement.content!
                if let idMatchResult = regexID?.firstMatch(in: article.url, options: [], range: NSMakeRange(0, article.url.characters.count)) {
                  article.id = (article.url as NSString).substring(with: idMatchResult.range)
                } else {
                  print("Fatal error: the website structure has changed.")
                  return;
                }
              } else {
                print("Fatal error: the website structure has changed.")
                return;
              }
              
              if let statusElement = itemDiv.at_xpath(".//ul[@class='status']/li") {
                let statusString = statusElement.content!
                if let timeMatchResult = regexTime?.firstMatch(in: statusString, options: [], range: NSMakeRange(0, statusString.characters.count)),
                  let commentCountMathResult = regexCommentCount?.firstMatch(in: statusString, options: [], range: NSMakeRange(0, statusString.characters.count)) {
                  article.time = (statusString as NSString).substring(with: timeMatchResult.range)
                  article.commentsCount = (statusString as NSString).substring(with: commentCountMathResult.range)
                }
              } else {
                print("Fatal error: the website structure has changed.")
                return;
              }
              
              if let thumbDiv = itemDiv.at_xpath(".//img") {
                article.thumbURL = thumbDiv["src"]!
              } else {
                print("Fatal error: the website structure has changed.")
                return;
              }
            }
            completionHandler()
          }
        }
      }
      task.resume()
    }
  }
}
