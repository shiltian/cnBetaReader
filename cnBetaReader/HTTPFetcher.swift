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
    static var nextPage: Int = 2
    static let homePageURL = "http://www.cnbeta.com"
    static let loadMoreURL = "\(HTTPFetcher.homePageURL)/home/more"
    static let fetchCommentsURL = "\(HTTPFetcher.homePageURL)/comment/read"
    static let dateFormatter = DateFormatter()
    
    init() {
        HTTPFetcher.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
    }
    
    // MARK: - APIs
    
    // Fetch home page
    func fetchHomePage(completionHandler: @escaping ()->Void, errorHandler: @escaping (_: String)->Void) {
        if let url = URL(string: HTTPFetcher.homePageURL) {
            let task = URLSession.shared.dataTask(with: url) {
                (data, response, error) in
                if let error = error {
                    errorHandler("Error: \(error)")
                } else if let data = data {
                    if let html = String(data: data, encoding: .utf8), let doc = HTML(html: html, encoding: .utf8) {
                        // Set the load more token and param
                        HTTPFetcher.nextPage = 2
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
                                    if let range = statusString.range(of: "\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}", options: .regularExpression) {
                                        let date = HTTPFetcher.dateFormatter.date(from: statusString.substring(with: range))
                                        if let date = date {
                                            article.time = date as NSDate
                                        } else {
                                            errorHandler("Error when converting the date.")
                                        }
                                    } else {
                                        errorHandler("Fatal error occurred when parsing the article time.")
                                        return
                                    }
                                    if let range = statusString.range(of: "\\d+(?=个意见)", options: .regularExpression) {
                                        article.commentCount = Int16(statusString.substring(with: range))!
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
    func loadMore(completionHandler: @escaping ()->Void, errorHandler: @escaping (_: String)->Void) {
        // Set the query items
        let epochTime = Int(NSDate().timeIntervalSince1970 * 1000)
        let urlComponents = NSURLComponents(string: HTTPFetcher.loadMoreURL)
        urlComponents?.queryItems = [
            URLQueryItem(name: HTTPFetcher.loadMoreParam!, value: HTTPFetcher.loadMoreToken!),
            URLQueryItem(name: "type", value: "all"),
            URLQueryItem(name: "page", value: "\(HTTPFetcher.nextPage)"),
            URLQueryItem(name: "_", value: "\(epochTime)")
        ]
        let url = urlComponents?.url
        if let url = url {
            // Set the request header, otherwise the app cannot get the right more data.
            var request = URLRequest(url: url)
            // Important: The return json will be empty without the referer header.
            request.setValue("\(HTTPFetcher.homePageURL)/", forHTTPHeaderField: "Referer")
            let task = URLSession.shared.dataTask(with: request) {
                (data, response, error) in
                if let error = error {
                    print("Error: \(error)")
                } else if let data = data {
                    do {
                        let resJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                        let moreArticlesList = (resJSON?["result"] as? [String: Any])?["list"] as? [Any]
                        if let moreArticlesList = moreArticlesList {
                            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                                for entity in moreArticlesList {
                                    let _article = entity as? [String: Any]
                                    let article = ArticleMO(context: appDelegate.persistentContainer.viewContext)
                                    article.id = _article?["sid"] as? String
                                    article.url = _article?["url_show"] as? String
                                    article.title = _article?["title"] as? String
                                    article.commentCount = Int16((_article?["comments"] as? String)!)!
                                    article.thumbURL = _article?["thumb"] as? String
                                    article.time = HTTPFetcher.dateFormatter.date(from: _article?["inputtime"] as! String)! as NSDate
                                    appDelegate.saveContext()
                                }
                            } else {
                                errorHandler("Failed to get the app delegate.")
                                return
                            }
                        }
                    } catch {
                        let nserror = error as NSError
                        errorHandler("Failed to serialize the JSON when load more.\nError: \(nserror), detail: \(nserror.userInfo)")
                        return
                    }
                    completionHandler()
                    HTTPFetcher.nextPage += 1
                }
            }
            task.resume()
        }
    }
    
    // Fetch the comments of the article
    func fetchCommentsOfArticle(articleSID sid: String, articleSN sn: String, errorHandler: @escaping (_: String)->Void) {
        let urlComponents = NSURLComponents(string: HTTPFetcher.loadMoreURL)
        urlComponents?.queryItems = [
            URLQueryItem(name: "op", value: "1,\(sid),\(sn)")
        ]
        let url = urlComponents?.url
        if let url = url {
            let task = URLSession.shared.dataTask(with: url) {
                (data, response, error) in
                if let error = error {
                    errorHandler("Error: \(error)")
                } else if let data = data {
                    do {
                        let resJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                        let results = resJSON?["result"] as? [String: Any]
                    } catch {
                        let nserror = error as NSError
                        errorHandler("Failed to serialize the JSON when fetch comments.\nError: \(nserror), detail: \(nserror.userInfo)")
                        return
                    }
                    
                }
            }
            task.resume()
        }
    }
}
