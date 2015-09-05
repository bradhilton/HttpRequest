//
//  HttpRequest.swift
//  HttpRequest
//
//  Created by Bradley Hilton on 7/2/15.
//  Copyright © 2015 Skyvive. All rights reserved.
//

import Foundation
import Convertible

class HttpRequest<T : DataInitializable> : NSObject {
    var loggingEnabled = false
    var method: String = "GET"
    var basePath: String = ""
    var relativePath: String = ""
    var parameters = [String: String]()
    var headers = [String: String]()
    var body: DataSerializable?
    var configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
    var convertibleOptions = [ConvertibleOption]()
    var queue: NSOperationQueue = NSOperationQueue.mainQueue()
    var completion: ((HttpResponse<T>?, ErrorType?) -> ())?
    var success: ((HttpResponse<T>) -> ())?
    var failure: ((ErrorType) -> ())?
    var cache: ((HttpResponse<T>) -> ())?
    var progress: ((Double, Double) -> ())?
    var originalRequest: NSURLRequest?
    var startTime: NSDate?
    
    override init() {
        super.init()
    }
    
    init(method: String) {
        super.init()
        self.method = method
    }
    
}

extension HttpRequest {
    
    func request(cachePolicy: NSURLRequestCachePolicy) throws -> NSURLRequest {
        guard let requestUrl = requestUrl else { throw HttpError.InvalidPath(requestPath) }
        let request = NSMutableURLRequest(URL: requestUrl)
        request.HTTPMethod = method
        request.allHTTPHeaderFields = headers
        request.HTTPBody = try body?.serializeToDataWithOptions(self.convertibleOptions)
        request.timeoutInterval = configuration.timeoutIntervalForRequest
        request.cachePolicy = cachePolicy
        return request
    }
    
    private var requestPath: String {
        let path = basePath + relativePath
        if let components = NSURLComponents(string: path) where parameters.count > 0  {
            var queryItems: [NSURLQueryItem] = components.queryItems ?? [NSURLQueryItem]()
            for (name, value) in parameters {
                queryItems.append(NSURLQueryItem(name: name, value: value))
            }
            components.queryItems = queryItems
            return components.string?.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding) ?? path
        } else {
            return path
        }
    }
    
    private var requestUrl: NSURL? {
        return NSURL(string: requestPath)
    }
    
    private var session: NSURLSession {
        return NSURLSession(configuration: configuration)
    }
    
}
