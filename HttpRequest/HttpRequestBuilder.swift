//
//  HttpRequestBuilder.swift
//  HttpRequest
//
//  Created by Bradley Hilton on 7/2/15.
//  Copyright © 2015 Skyvive. All rights reserved.
//

import Foundation
import Convertible

/// Default request builder; instantiate subclasses GET, POST, etc. Request is automatically rendered; do not save reference.
public class HttpRequestBuilder<T : DataInitializable> {
    
    var autoRequestEnabled = true
    
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
    
    /// Set session configuration
    public func configuration(configuration: NSURLSessionConfiguration) -> Self {
        request.configuration = configuration
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
    
    /// Set operation queue
    public func queue(queue: NSOperationQueue) -> Self {
        request.queue = queue
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
    
    /// Handler that returns a cached response
    public func cache(cache: (HttpResponse<T>) -> ()) -> Self {
        request.cache = cache
        return self
    }
    
    /// Handler that returns progress for the request and response respectively represented by two doubles between 0.0 to 1.0
    public func progress(progress: (Double, Double) -> ()) -> Self {
        request.progress = progress
        return self
    }
    
    func makeRequest() {
        let when = dispatch_time(DISPATCH_TIME_NOW, Int64(10 * NSEC_PER_MSEC))
        let queue = (NSOperationQueue.currentQueue()?.underlyingQueue ?? NSOperationQueue.mainQueue().underlyingQueue) ?? dispatch_get_main_queue()!
        dispatch_after(when, queue) {
            if self.autoRequestEnabled {
                self.start()
            }
        }
    }
    
    /// Call to postpone making call; must call start() to make request.
    public func wait() -> Self {
        autoRequestEnabled = false
        return self
    }
    
    /// Call to make request manually. Unless you previously called wait(), there is no need to call start().
    public func start() {
        autoRequestEnabled = false
        if request.cache != nil {
            HttpCacheTask(request: request)
            if request.success != nil || request.completion != nil {
                HttpNetworkTask(request: request)
            }
        } else {
            HttpStandardTask(request: request)
        }
    }
    
}

/// Creates a request with "GET" as method; see HttpRequestBuilder for more info
public class GET<T : DataInitializable> : HttpRequestBuilder<T> {}
/// Creates a request with "POST" as method; see HttpRequestBuilder for more info
public class POST<T : DataInitializable> : HttpRequestBuilder<T> { override static var method: String { return "POST" } }
/// Creates a request with "PUT" as method; see HttpRequestBuilder for more info
public class PUT<T : DataInitializable> : HttpRequestBuilder<T> { override static var method: String { return "PUT" } }
/// Creates a request with "DELETE" as method; see HttpRequestBuilder for more info
public class DELETE<T : DataInitializable> : HttpRequestBuilder<T> { override static var method: String { return "DELETE" } }
/// Creates a request with "PATCH" as method; see HttpRequestBuilder for more info
public class PATCH<T : DataInitializable> : HttpRequestBuilder<T> { override static var method: String { return "PATCH" } }
/// Creates a request with "HEAD" as method; see HttpRequestBuilder for more info
public class HEAD<T : DataInitializable> : HttpRequestBuilder<T> { override static var method: String { return "HEAD" } }
/// Creates a request with "OPTIONS" as method; see HttpRequestBuilder for more info
public class OPTIONS<T : DataInitializable> : HttpRequestBuilder<T> { override static var method: String { return "OPTIONS" } }