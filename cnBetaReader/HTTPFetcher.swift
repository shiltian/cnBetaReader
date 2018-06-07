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
                    handler(.Success)
                } catch {
                    handler(.Failure(error))
                }
            }
        }
        task.resume()
    }
    
    // Fetch the comments of the article
    func fetchComments(article: ArticleMO, handler: @escaping (AsyncResult)->Void) {
        guard let urlComponents = NSURLComponents(string: HTTPFetcher.fetchCommentsURL) else {
            // failed to create the NSURLComponents
            handler(.Failure(HTTPFetcherError(message: "failed to create the NSURLComponents", kind: .internalError)))
            return
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "op", value: "1,\(article.id),\(article.sn!)")
        ]
        
        guard let url = urlComponents.url else {
            // failed to get the url from the urlComponents
            handler(.Failure(HTTPFetcherError(message: "failed to get the url from the urlComponents",
                                              kind: .internalError)))
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
                    try self.parseComment(data: data, article: article)
                    handler(.Success)
                } catch {
                    handler(.Failure(error))
                }
            }
        }
        task.resume()
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
        
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<ArticleMO> = ArticleMO.fetchRequest()

        for entry in list {
            guard let articleEntry = entry as? [String: Any] else {
                // failed to parse the json. entry in list
                throw HTTPFetcherError(message: "failed to parse the json. entry in list", kind: .parserError)
            }
            
            var _article: ArticleMO?
            
            guard let id = articleEntry["sid"] as? String else {
                // failed to parse the json. entry: sid
                throw HTTPFetcherError(message: "failed to parse the json. entry: sid", kind: .parserError)
            }
            
            guard let commentCount = articleEntry["comments"] as? String else {
                // failed to parse the json. entry: comments
                throw HTTPFetcherError(message: "failed to parse the json. entry: comments", kind: .parserError)
            }
            
            fetchRequest.predicate = NSPredicate(format: "id = \(id)")
            
            let articles = try context.fetch(fetchRequest)
            
            if articles.count == 0 {
                _article = ArticleMO(context: appDelegate.persistentContainer.viewContext)
            } else if articles.count == 1 {
                // the article exists, just update the comment count, and move to the next one
                _article = articles[0]
                _article!.commentCount = Int16(commentCount)!
                continue
            } else {
                throw HTTPFetcherError(message: "more than one elements with the same id", kind: .internalError)
            }
            
            guard let article = _article else {
                throw HTTPFetcherError(message: "article object is nil", kind: .internalError)
            }
            
            guard let url = articleEntry["url_show"] as? String else {
                // failed to parse the json. entry: url_show
                throw HTTPFetcherError(message: "failed to parse the json. entry: url_show", kind: .parserError)
            }
            
            guard let title = articleEntry["title"] as? String else {
                // failed to parse the json. entry: title
                throw HTTPFetcherError(message: "failed to parse the json. entry: title", kind: .parserError)
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
            let scriptText = try script.html()
            guard let range = scriptText.range(of: "(?<=SN:\")[0-9a-zA-Z]*(?=\")",
                                               options: .regularExpression) else {
                // failed to extract the sn
                throw HTTPFetcherError(message: "failed to extract the sn. \(scriptText)", kind: .parserError)
            }
            article.sn = scriptText.substring(with: range)
        } else {
            // failed to extract the pageFooter's adjacent sibling
        }
        
        // save the article
        appDelegate.saveContext()
    }

    private func parseComment(data: Data, article: ArticleMO) throws {
        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            // failed to convert to [String: Any]
            throw HTTPFetcherError(message: "failed to convert to [String: Any]", kind: .parserError)
        }
        
        guard let result = json["result"] as? [String: Any] else {
            // failed to parse the key: json[result]
            throw HTTPFetcherError(message: "failed to parse the key: json[result]", kind: .parserError)
        }
        
        guard let commentList = result["cmntlist"] as? [[String: Any]] else {
            // failed to parse the key: result[cmntlist]
            throw HTTPFetcherError(message: "failed to parse the key: result[cmntlist]", kind: .parserError)
        }
        
        guard let commentStore = result["cmntstore"] as? [String: Any] else {
            // failed to parse the key: result[cmntstore]
            throw HTTPFetcherError(message: "failed to parse the key: result[cmntstore]", kind: .parserError)
        }
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            // failed to get the shared app delegate
            throw HTTPFetcherError(message: "failed to get the shared app delegate", kind: .internalError)
        }
        
        // Update the count of comments
        article.commentCount = Int16(commentList.count)
        
        var commentsDict: [Int64: CommentMO] = [:]
        for elem in commentList {
            guard let tid = elem["tid"] as? String else {
                // failed to parse the key: elem[tid]
                throw HTTPFetcherError(message: "failed to parse the key: elem[tid]", kind: .internalError)
            }
            let commentMO = CommentMO(context: appDelegate.persistentContainer.viewContext)
            let tid_ = Int64(tid)!
            commentMO.tid = tid_
            commentsDict[tid_] = commentMO
        }
        
        for cmnt in commentsDict {
            let comment = cmnt.value, tid = cmnt.key
            
            guard let commentDict = commentStore["\(tid)"] as? [String: Any] else {
                // failed to parse the key: commentStore[tid]
                throw HTTPFetcherError(message: "failed to parse the key: commentStore[tid]", kind: .internalError)
            }
            
            // Set the parent node
            if let parent = commentDict["pid"] as? String, let pid = Int64(parent), pid != 0 {
                comment.parent = commentsDict[pid]
            }
            
            // Set the contents
            comment.content = commentDict["comment"] as? String
            comment.from = commentDict["host_name"] as? String
            comment.name = commentDict["name"] as? String
            
            // Set the date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            if let date = commentDict["date"] as? String, let time = dateFormatter.date(from: date) {
                comment.time = time as NSDate
            }
            
            // Set the like and dislike
            if let score = commentDict["score"] as? String, let like = Int16(score) {
                comment.like = like
            }
            if let reason = commentDict["reason"] as? String, let dislike = Int16(reason) {
                comment.dislike = dislike
            }
            
            comment.article = article
        }
        appDelegate.saveContext()
    }
    
}
