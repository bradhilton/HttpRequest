//
//  HttpError.swift
//  HttpRequest
//
//  Created by Bradley Hilton on 7/2/15.
//  Copyright © 2015 Skyvive. All rights reserved.
//

import Foundation

/// Common framework errors; implements CustomStringConvertible
public enum HttpError : ErrorType, CustomStringConvertible {
    
    case InvalidPath(String)
    case HttpError(response: NSHTTPURLResponse, data: NSData)
    case UnknownError
    
    public var description: String {
        return "HttpError: " + errorDescription
    }
    
    var errorDescription: String {
        switch self {
        case .InvalidPath(let path): return "\(path) is an invalid path"
        case .HttpError(response: let response, data: _): return "\(response.statusCode) - \(NSHTTPURLResponse.localizedStringForStatusCode(response.statusCode))"
        case .UnknownError: return "Unknown error"
        }
    }
    
}
