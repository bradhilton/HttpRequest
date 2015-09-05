//
//  HttpResponse.swift
//  HttpRequest
//
//  Created by Bradley Hilton on 7/2/15.
//  Copyright © 2015 Skyvive. All rights reserved.
//

import Foundation
import Convertible

/// An HttpResponse object is always returned by a successful request
public struct HttpResponse<T : DataInitializable> {
    
    /// Can be of any type that implements DataInitializable
    public let body: T
    /// Response headers
    public let headers: [String : String]
    /// Response HTTP status code
    public let statusCode: Int
    /// Response time
    public let responseTime: NSTimeInterval
    /// The call's NSURLRequest
    public let urlRequest: NSURLRequest
    /// The call's NSHTTPURLResponse
    public let urlResponse: NSHTTPURLResponse
    
    init(body: T, responseTime: NSTimeInterval, request: NSURLRequest, urlResponse: NSHTTPURLResponse) {
        self.body = body
        self.headers = HttpResponse.headersFromUrlResponse(urlResponse)
        self.statusCode = urlResponse.statusCode
        self.responseTime = responseTime
        self.urlRequest = request
        self.urlResponse = urlResponse
    }
    
    static func headersFromUrlResponse(urlResponse: NSHTTPURLResponse) -> [String : String] {
        var headers = [String : String]()
        for (key, value) in urlResponse.allHeaderFields {
            if let key = key as? String, let value = value as? String {
                headers[key] = value
            }
        }
        return headers
    }
    
}
