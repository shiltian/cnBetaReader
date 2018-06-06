//
//  HTTPFetcher.swift
//  cnBetaReader
//
//  Created by Shilei Tian on 05/03/2017.
//  Copyright © 2017 TSL. All rights reserved.
//

import SwiftSoup
import CoreData

class HTTPFetcher {

    static var page: Int8 = 2
    static let timelineURL = "https://m.cnbeta.com/touch/default/timeline.json?page="
    static let fetchCommentsURL = "https://www.cnbeta.com/comment/read"
    static let dateFormatter = DateFormatter()
    
    static var loadMore: LoadMoreMO!
    
    init() {
        HTTPFetcher.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
    }
    
    // MARK: - APIs
    // TODO: - Refine these APIs without the errorHandler

    // Fetch home page
    func fetchTimeline(loadMore: Bool, handler: @escaping (AsyncResult)->Void) {
        var timelineURL: String
        if loadMore {
            timelineURL = "\(HTTPFetcher.timelineURL)\(HTTPFetcher.page)"
        } else {
            timelineURL = "\(HTTPFetcher.timelineURL)1"
        }
        guard let url = URL(string: timelineURL) else {
            // Failed to create URL object
            handler(.Failure(HTTPFetcherError(message: "failed to create URL object", kind: .internalError)))
            return
        }
        let task = URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            if let error = error {
                handler(.Failure(error))
                return
            }
            guard let data = data else {
                // the retrieved data is nil
                handler(.Failure(HTTPFetcherError(message: "retried homepage data is nil", kind: .dataError)))
                return
            }
            DispatchQueue.main.async {
                do {
                    try self.parseArticleList(data: data)
                    if !loadMore {
                        HTTPFetcher.page = 1
                    } else {
                        HTTPFetcher.page += 1
                    }
                    handler(.Success)
                } catch {
                    handler(.Failure(error))
                }
            }
        }
        task.resume()
    }
    
    // Fetch article content
    func fetchContent(article: ArticleMO, articleURL: String, handler: @escaping (AsyncResult)->Void) {
        guard let url = URL(string: articleURL) else {
            // failed to create URL object
            handler(.Failure(HTTPFetcherError(message: "failed to create URL object", kind: .internalError)))
            return
        }
        let task = URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            if let error = error {
                handler(.Failure(error))
                return
            }
            guard let data = data else {
                // the retrieved data is nil
                handler(.Failure(HTTPFetcherError(message: "retried homepage data is nil", kind: .dataError)))
                return
            }
            DispatchQueue.main.async {
                do {
                    try self.parseContent(data: data, article: article)
                } catch {
                    handler(.Failure(error))
                }
            }
        }
        task.resume()
    }
    
    // Fetch the comments of the article
    func fetchCommentsOfArticle(article: ArticleMO, completionHandler: @escaping ()->Void, errorHandler: @escaping (_: String)->Void) {
        let urlComponents = NSURLComponents(string: HTTPFetcher.fetchCommentsURL)
        urlComponents?.queryItems = [
            URLQueryItem(name: "op", value: "1,\(article.id),\(article.sn!)")
        ]
        if let url = urlComponents?.url {
            let task = URLSession.shared.dataTask(with: url) {
                (data, response, error) in
                if let error = error {
                    errorHandler("Error: \(error)")
                } else if let data = data {
                    DispatchQueue.main.async {
                        var resJSON: [String: Any]? = nil
                        do {
                            resJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                        } catch {
                            let nserror = error as NSError
                            errorHandler("Failed to serialize the JSON when fetch comments.\nError: \(nserror), detail: \(nserror.userInfo)")
                            return
                        }
                        
                        if let results = resJSON?["result"] as? [String: Any],
                            let cmntlist = results["cmntlist"] as? [Any],
                            let cmntstore = results["cmntstore"] as? [String: Any] {
                            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                                // Update the count of comments
                                article.commentCount = Int16(cmntlist.count)
                                var commentsDict: [Int64: CommentMO] = [:]
                                for e in cmntlist {
                                    if let cmnt = e as? [String: String], let _tid = cmnt["tid"], let tid = Int64(_tid) {
                                        let comment = CommentMO(context: appDelegate.persistentContainer.viewContext)
                                        comment.tid = tid
                                        commentsDict[tid] = comment
                                    } else {
                                        errorHandler("Error when converting to JSON.")
                                        return
                                    }
                                }
                                for cmnt in commentsDict {
                                    let comment = cmnt.value
                                    let tid = cmnt.key
                                    if let cmntDict = cmntstore["\(tid)"] as? [String: Any] {
                                        // Set the parent node
                                        if let parent = cmntDict["pid"] as? String, let pid = Int64(parent) {
                                            if pid != 0 {
                                                comment.parent = commentsDict[pid]
                                            }
                                        }
                                        // Set the contents
                                        comment.content = cmntDict["comment"] as? String
                                        comment.from = cmntDict["host_name"] as? String
                                        comment.name = cmntDict["name"] as? String
                                        // Set the date
                                        let dateFormatter = DateFormatter()
                                        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                                        if let date = cmntDict["date"] as? String,  let time = dateFormatter.date(from: date) {
                                            comment.time = time as NSDate
                                        }
                                        // Set the like and dislike
                                        if let score = cmntDict["score"] as? String, let like = Int16(score) {
                                            comment.like = like
                                        }
                                        if let reason = cmntDict["reason"] as? String, let dislike = Int16(reason) {
                                            comment.dislike = dislike
                                        }
                                        comment.article = article
                                    } else {
                                        errorHandler("Error when parsing the comment content.")
                                        return
                                    }
                                }
                                appDelegate.saveContext()
                            } else {
                                errorHandler("Error when getting the app delegate.")
                                return
                            }
                        }
                        completionHandler()
                    }
                }
            }
            task.resume()
        } else {
            errorHandler("Error occurred when get the url of load more.")
        }
    }
    
    // MARK: - Private functions
    
    private func parseArticleList(data: Data) throws {
        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            // failed to convert to [String: Any]
            throw HTTPFetcherError(message: "failed to convert to [String: Any]", kind: .parserError)
        }

        guard let result = json["result"] as? [String: Any] else {
            // failed to parse the json. key: result
            throw HTTPFetcherError(message: "failed to parse the json. key: result", kind: .parserError)
        }

        guard let list = result["list"] as? [Any] else {
            // failed to parse the json. key: list
            throw HTTPFetcherError(message: "failed to parse the json. key: list", kind: .parserError)
        }

        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            // failed to get the shared app delegate
            throw HTTPFetcherError(message: "failed to get the shared app delegate", kind: .internalError)
        }

        for entry in list {
            guard let articleEntry = entry as? [String: Any] else {
                // failed to parse the json. entry in list
                throw HTTPFetcherError(message: "failed to parse the json. entry in list", kind: .parserError)
            }
            
            let article = ArticleMO(context: appDelegate.persistentContainer.viewContext)
            
            guard let id = articleEntry["sid"] as? String else {
                // failed to parse the json. entry: sid
                throw HTTPFetcherError(message: "failed to parse the json. entry: sid", kind: .parserError)
            }
            
            guard let url = articleEntry["url_show"] as? String else {
                // failed to parse the json. entry: url_show
                throw HTTPFetcherError(message: "failed to parse the json. entry: url_show", kind: .parserError)
            }
            
            guard let title = articleEntry["title"] as? String else {
                // failed to parse the json. entry: title
                throw HTTPFetcherError(message: "failed to parse the json. entry: title", kind: .parserError)
            }
            
            guard let commentCount = articleEntry["comments"] as? String else {
                // failed to parse the json. entry: comments
                throw HTTPFetcherError(message: "failed to parse the json. entry: comments", kind: .parserError)
            }
            
            guard let thumbURL = articleEntry["thumb"] as? String else {
                // failed to parse the json. entry: thumb
                throw HTTPFetcherError(message: "failed to parse the json. entry: thumb", kind: .parserError)
            }
            
            guard let timeString = articleEntry["inputtime"] as? String else {
                // failed to parse the json. entry: inputtime
                throw HTTPFetcherError(message: "failed to parse the json. entry: inputtime", kind: .parserError)
            }

            article.id = Int64(id)!
            article.url = url
            article.title = title
            article.commentCount = Int16(commentCount)!
            article.thumbURL = thumbURL
            article.time = HTTPFetcher.dateFormatter.date(from: timeString)! as NSDate
        }
        
        // save the context
        appDelegate.saveContext()
    }
    
    private func parseContent(data: Data, article: ArticleMO) throws {
        guard let html = String(data: data, encoding: .utf8) else {
            // failed to decode the string
            throw HTTPFetcherError(message: "failed to decode the string", kind: .dataError)
        }
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            // failed to get the shared app delegate
            throw HTTPFetcherError(message: "failed to get the shared app delegate", kind: .internalError)
        }

        let articleContent = ArticleContentMO(context: appDelegate.persistentContainer.viewContext)
        articleContent.id = article.id
        
        let doc = try SwiftSoup.parse(html)
        
        // parse summary
        if let summary = try doc.select(".article-summary > p").first() {
            articleContent.summary = try summary.html()
        } else {
            // failed to extract the summary
        }
        
        // parse content
        articleContent.content = ""
        let contents = try doc.select(".article-content > p")
        for phrase in contents {
            try articleContent.content?.append(phrase.html())
        }
        article.content = articleContent
        
        // parse sn
        if let script = try doc.select(".pageFooter + script").first() {
            let scriptText = try script.text()
            guard let range = scriptText.range(of: "(?<=SN:\")[0-9a-zA-Z]*(?=\")",
                                               options: .regularExpression) else {
                // failed to extract the sn
                throw HTTPFetcherError(message: "failed to extract the sn", kind: .parserError)
            }
            article.sn = scriptText.substring(with: range)
        } else {
            // failed to extract the pageFooter's adjacent sibling
        }
        
        // save the article
        appDelegate.saveContext()
    }
}
