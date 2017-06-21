//
//  HTTPFetcher.swift
//  cnBetaReader
//
//  Created by Shilei Tian on 05/03/2017.
//  Copyright © 2017 TSL. All rights reserved.
//

import Kanna

class HTTPFetcher {
    
    static var loadMoreToken: String? = nil
    static var loadMoreParam: String? = nil
    
    // MARK: - APIs
    
    // Fetch home page
    func fetchHomePage(completionHandler: @escaping ()->Void, errorHandler: @escaping (_: String)->Void) {
        let urlString = "http://www.cnbeta.com"
        
        if let url = URL(string: urlString) {
            let task = URLSession.shared.dataTask(with: url) {
                (data, response, error) in
                if let error = error {
                    errorHandler("Error: \(error)")
                } else if let data = data {
                    if let html = String(data: data, encoding: .utf8), let doc = HTML(html: html, encoding: .utf8) {
                        // Set the load more token and param
                        let loadMoreTokenElement = doc.at_xpath("//meta[@name='csrf-token']")
                        if let homeMoreTokenElement = loadMoreTokenElement {
                            HTTPFetcher.loadMoreToken = homeMoreTokenElement["content"]!
                        } else {
                            errorHandler("Fatal error: fail to parse csrf-token.")
                            return
                        }
                        let loadMoreParamElement = doc.at_xpath("//meta[@name='csrf-param']")
                        if let loadMoreParamElement = loadMoreParamElement {
                            HTTPFetcher.loadMoreParam = loadMoreParamElement["content"]!
                        } else {
                            errorHandler("Fatal error: fail to parse csrf-param.")
                            return
                        }
                        
                        // Process the downloaded item div
                        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                            for itemDiv in doc.xpath("//div[@class='items-area']/div[@class='item']") {
                                // Parse the title and url
                                let article = ArticleMO(context: appDelegate.persistentContainer.viewContext)
                                let urlElement = itemDiv.at_xpath(".//dl/dt/a")
                                if let urlElement = urlElement {
                                    let url = urlElement["href"]!
                                    article.url = url
                                    article.title = urlElement.content!
                                    if let range = url.range(of: "\\d+(?=\\.htm)", options: .regularExpression) {
                                        article.id = url.substring(with: range)
                                    } else {
                                        errorHandler("Fatal error occurred when parsing the article id.")
                                        return
                                    }
                                } else {
                                    errorHandler("Fatal error occurred when parsing the article url.")
                                    return
                                }
                                // Parse the submitted time and the comment number
                                if let statusElement = itemDiv.at_xpath(".//ul[@class='status']/li") {
                                    let statusString = statusElement.content!
                                    if let range = statusString.range(of: "\\d\\d-\\d\\d \\d\\d:\\d\\d", options: .regularExpression) {
                                        article.time = statusString.substring(with: range)
                                    } else {
                                        errorHandler("Fatal error occurred when parsing the article time.")
                                        return
                                    }
                                    if let range = statusString.range(of: "\\d+(?=个意见)", options: .regularExpression) {
                                        article.commentCount = statusString.substring(with: range)
                                    } else {
                                        errorHandler("Fatal error occurred when parsing the article comment count.")
                                        return
                                    }
                                } else {
                                    errorHandler("Fatal error occurred when parsing the status.")
                                    return
                                }
                                // Parse the thumb url
                                if let thumbDiv = itemDiv.at_xpath(".//img") {
                                    article.thumbURL = thumbDiv["src"]!
                                } else {
                                    errorHandler("Fatal error occurred when parsing the thumb.")
                                    return
                                }
                                // Save to the Core Data
                                // Note: This step prones to errors.
                                appDelegate.saveContext()
                            }
                            // Call the out completion handler
                            completionHandler()
                        } else {
                            errorHandler("Failed to get the app delegate.")
                        }
                    }
                }
            }
            task.resume()
        }
    }
    
    // Fetch article content
    func fetchContent(id: String, articleURL: String, completionHandler: @escaping ()->Void) {
        if let url = URL(string: articleURL) {
            let task = URLSession.shared.dataTask(with: url) {
                (data, response, error) in
                if let error = error {
                    print("Fatal error: \(error)")
                    return;
                } else if let data = data {
                    if let html = String(data: data, encoding: .utf8), let doc = HTML(html: html, encoding: .utf8) {
                        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                            let articleContent = ArticleContentMO(context: appDelegate.persistentContainer.viewContext)
                            articleContent.id = id
                            if let summary = doc.at_xpath("//div[@class='article-summary']//p") {
                                articleContent.summary = String()
                                articleContent.summary = summary.toHTML!
                            } else {
                                print("Failed to parse the summary…")
                                return
                            }
                            articleContent.content = String()
                            let paras = doc.xpath("//div[@class='article-content']")
                            for para in paras {
                                articleContent.content!.append(para.toHTML!)
                            }
                            appDelegate.saveContext()
                            completionHandler()
                        }
                    }
                }
            }
            task.resume()
        }
    }
    
    // Load more article
    func loadMore() {
        // Set the query items
        let epochTime = Int(NSDate().timeIntervalSince1970 * 1000)
        let urlComponents = NSURLComponents(string: "http://www.cnbeta.com/home/more")
        urlComponents?.queryItems = [
            URLQueryItem(name: HTTPFetcher.loadMoreParam!, value: HTTPFetcher.loadMoreToken!),
            URLQueryItem(name: "type", value: "all"),
            URLQueryItem(name: "page", value: "2"),
            URLQueryItem(name: "_", value: "\(epochTime)")
        ]
        let url = urlComponents?.url
        if let url = url {
            // Set the request header, otherwise the app cannot get the right more data.
            var request = URLRequest(url: url)
            // Important: The return json will be empty without the referer header.
            request.setValue("http://www.cnbeta.com/", forHTTPHeaderField: "Referer")
            let task = URLSession.shared.dataTask(with: request) {
                (data, response, error) in
                if let error = error {
                    print("Error: \(error)")
                } else if let data = data {
                    do {
                        let resJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                        let moreArticlesList = (resJSON?["result"] as? [String: Any])?["list"] as? [Any]
                        if let moreArticlesList = moreArticlesList {
                            for article in moreArticlesList {
                                let _article = article as? [String: Any]
                                let title = _article?["title"] as! String
                                let articleURL = _article?["url_show"] as! String
                                let id = _article?["sid"] as! String
                                let comments = _article?["comments"] as! String
                                let thumbURL = _article?["thumb"] as! String
                                print("Title: \(title), url: \(articleURL), sid: \(id), comments: \(comments)")
                            }
                        }
                    } catch {
                        print("error")
                    }
                }
            }
            task.resume()
        }
    }
}
