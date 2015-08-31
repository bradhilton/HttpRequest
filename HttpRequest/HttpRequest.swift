//
//  HttpRequest.swift
//  HttpRequest
//
//  Created by Bradley Hilton on 7/2/15.
//  Copyright © 2015 Skyvive. All rights reserved.
//

import Foundation
import Convertible

struct HttpRequest<T where T : DataInitializable> {
    var loggingEnabled = false
    var method: String = "GET"
    var basePath: String = ""
    var relativePath: String = ""
    var parameters = [String: String]()
    var headers = [String: String]()
    var body: DataSerializable?
    var configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
    var convertibleOptions = [ConvertibleOption]()
    var completion: ((HttpResponse<T>?, ErrorType?) -> ())?
    var success: ((HttpResponse<T>) -> ())?
    var failure: ((ErrorType) -> ())?
    var originalRequest: NSURLRequest?
    var startTime: NSDate?
    init() {}
    init(method: String) { self.method = method }
}

extension HttpRequest {
    
    var requestPath: String {
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
    
    var requestUrl: NSURL? {
        return NSURL(string: requestPath)
    }
    
    var session: NSURLSession {
        return NSURLSession(configuration: configuration)
    }
    
}

extension HttpRequest {
    
    mutating func start() {
        do {
            let request = try self.request()
            originalRequest = request
            startTime = NSDate()
            logRequest(request)
            session.dataTaskWithRequest(request, completionHandler: responseHandler).resume()
        } catch { returnError(error) }
    }
    
    func responseHandler(data: NSData?, response: NSURLResponse?, error: NSError?) {
        if let error = error { self.returnError(error); return }
        guard let request = self.originalRequest, let startTime = self.startTime else { self.returnError(HttpError.UnknownError); return }
        let responseTime = NSDate().timeIntervalSinceDate(startTime)
        self.logResponse(response, request: request, responseTime: responseTime, data: data)
        guard let response = response as? NSHTTPURLResponse else { self.returnError(HttpError.NoResponse); return }
        guard let data = data else { self.returnError(HttpError.NoData); return }
        if !(200..<300).contains(response.statusCode) { self.returnError(HttpError.HttpError(response: response, data: data)); return }
        do {
            self.returnResponse(HttpResponse(body: try T.initializeWithData(data, options: self.convertibleOptions), responseTime: responseTime, request: request, urlResponse: response))
        } catch { self.returnError(error) }
    }
    
    func returnResponse(response: HttpResponse<T>) {
        self.success?(response)
        self.completion?(response, nil)
    }
    
    func returnError(error: ErrorType) {
        dispatch_async(dispatch_get_main_queue()) {
            self.failure?(error)
            self.completion?(nil, error)
        }
    }
    
    func request() throws -> NSURLRequest {
        guard let requestUrl = requestUrl else { throw HttpError.InvalidPath(requestPath) }
        let request = NSMutableURLRequest(URL: requestUrl)
        request.HTTPMethod = method
        request.allHTTPHeaderFields = headers
        request.HTTPBody = try body?.serializeToDataWithOptions(self.convertibleOptions)
        request.timeoutInterval = configuration.timeoutIntervalForRequest
        request.cachePolicy = configuration.requestCachePolicy
        return request
    }
    
}

extension HttpRequest {
    
    func logRequest(request: NSURLRequest) {
        if let method = request.HTTPMethod,
            let url = request.URL?.absoluteString where loggingEnabled {
                print("\n---> \(method) \(url)")
                printHeaderFields(request.allHTTPHeaderFields)
                printBody(request.HTTPBody)
                print("---> END " + bytesDescription(request.HTTPBody))
        }
    }
    
    func logResponse(response: NSURLResponse?, request: NSURLRequest, responseTime: NSTimeInterval, data: NSData?) {
        if let method = request.HTTPMethod,
            let url = request.URL?.absoluteString,
            let response = response as? NSHTTPURLResponse where loggingEnabled {
                print("\n<--- \(method) \(url) (\(response.statusCode), \(responseTimeDescription(responseTime)))")
                printHeaderFields(response.allHeaderFields)
                printBody(data)
                print("<--- END " + bytesDescription(data))
        }
    }
    
    func responseTimeDescription(responseTime: NSTimeInterval) -> NSString {
        return NSString(format: "%0.2fs", responseTime)
    }
    
    func printHeaderFields(headerFields: [NSObject : AnyObject]?) {
        if let headerFields = headerFields {
            for (field, value) in headerFields {
                print("\(field): \(value)")
            }
        }
    }
    
    func printBody(data: NSData?) {
        if let body = data,
            let bodyString = NSString(data: body, encoding: NSUTF8StringEncoding) where bodyString.length > 0 {
                print(bodyString)
        }
    }
    
    func bytesDescription(data: NSData?) -> String {
        return "(\(data != nil ? data!.length : 0) bytes)"
    }
    
}
