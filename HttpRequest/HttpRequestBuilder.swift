//
//  HttpRequestBuilder.swift
//  HttpRequest
//
//  Created by Bradley Hilton on 7/2/15.
//  Copyright © 2015 Skyvive. All rights reserved.
//

import Foundation
import Convertible

/// Base request class. Do not save request or delay configuring since it starts automatically.
public class GET<T where T : DataInitializable> {
    
    var token = dispatch_once_t()
    
    var request: HttpRequest<T>
    
    class var method: String { return "GET" }
    
    init() {
        self.request = HttpRequest<T>(method: self.dynamicType.method)
        makeRequest()
    }
    
    /// Convenience method to create request with base path
    public convenience init(_ basePath: String) {
        self.init()
        request.basePath = basePath
    }
    
    /// Convenience method to create request with service type
    public convenience init(_ httpService: HttpService.Type) {
        self.init()
        httpService.init().loadSettingsIntoRequest(&request)
    }
    
    /// Sets whether logging the request and response is enabled; false by default
    public func logging(logging: Bool) -> Self {
        request.loggingEnabled = logging
        return self
    }
    
    /// Appends a new path component
    public func path(path: String) -> Self {
        request.relativePath += path
        return self
    }
    
    /// Set values for query params; may remove query argument by setting value for param key to nil
    public func params(params: [String : String?]) -> Self {
        for (key, value) in params {
            request.parameters[key] = value
        }
        return self
    }
    
    /// Set values for headers; may remove header by setting value for header key to nil
    public func headers(headers: [String : String?]) -> Self {
        for (key, value) in headers {
            request.headers[key] = value
        }
        return self
    }
    
    /// Optionally include a DataSerializable object to include in request body
    public func body(body: DataSerializable?) -> Self {
        request.body = body
        return self
    }
    
    /// Handler to update session configuration
    public func configure(configure: (inout NSURLSessionConfiguration) -> ()) -> Self {
        configure(&request.configuration)
        return self
    }
    
    /// Set convertible options
    public func convertibleOptions(convertibleOptions: [ConvertibleOption]) -> Self {
        request.convertibleOptions = convertibleOptions
        return self
    }
    
    /// Handler for completion; will return HttpResponse if successful, otherwise an error
    public func completion(completion: (HttpResponse<T>?, ErrorType?) -> ()) -> Self {
        request.completion = completion
        return self
    }
    
    /// Handler for success that returns an HttpResponse
    public func success(success: (HttpResponse<T>) -> ()) -> Self {
        request.success = success
        return self
    }
    
    /// Handler for failure that returns an error
    public func failure(failure: (ErrorType) -> ()) -> Self {
        request.failure = failure
        return self
    }
    
    func makeRequest() {
        let when = dispatch_time(DISPATCH_TIME_NOW, Int64(10 * NSEC_PER_MSEC))
        let queue = (NSOperationQueue.currentQueue()?.underlyingQueue ?? NSOperationQueue.mainQueue().underlyingQueue) ?? dispatch_get_main_queue()!
        dispatch_once(&token) {
            dispatch_after(when, queue) { self.request.start() }
        }
    }
    
}

/// Creates a request with "POST" as method; see GET for more info
public class POST<T where T : DataInitializable> : GET<T> { override static var method: String { return "POST" } }
/// Creates a request with "PUT" as method; see GET for more info
public class PUT<T where T : DataInitializable> : GET<T> { override static var method: String { return "PUT" } }
/// Creates a request with "DELETE" as method; see GET for more info
public class DELETE<T where T : DataInitializable> : GET<T> { override static var method: String { return "DELETE" } }
/// Creates a request with "PATCH" as method; see GET for more info
public class PATCH<T where T : DataInitializable> : GET<T> { override static var method: String { return "PATCH" } }
/// Creates a request with "HEAD" as method; see GET for more info
public class HEAD<T where T : DataInitializable> : GET<T> { override static var method: String { return "HEAD" } }
/// Creates a request with "OPTIONS" as method; see GET for more info
public class OPTIONS<T where T : DataInitializable> : GET<T> { override static var method: String { return "OPTIONS" } }