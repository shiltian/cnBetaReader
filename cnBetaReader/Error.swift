//
//  Error.swift
//  cnBetaReader
//
//  Created by Shilei Tian on 2018/6/6.
//  Copyright © 2018 TSL. All rights reserved.
//

import Foundation

enum AsyncResult {
  case Success, Failure(Error)
}

struct HTTPFetcherError : Error {
  enum ErrorKind {
    case networkError
    case parserError
    case internalError
    case dataError
  }
  
  let message: String
  let kind: ErrorKind
}
