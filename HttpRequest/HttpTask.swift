//
//  HttpRequestDelegate.swift
//  HttpRequest
//
//  Created by Bradley Hilton on 9/1/15.
//  Copyright © 2015 Skyvive. All rights reserved.
//

import Foundation
import Convertible

class HttpStandardTask<T : DataInitializable> : NSObject, NSURLSessionDataDelegate {
    
    let request: HttpRequest<T>
    let data = NSMutableData()
    let startDate = NSDate()
    var completedSendingData = false
    var completedRecievingData = false
    let queue: NSOperationQueue = {
        let queue = NSOperationQueue()
        queue.underlyingQueue = dispatch_queue_create(nil, nil)
        return queue
    }()
    var cachePolicy: NSURLRequestCachePolicy {
        return request.configuration.requestCachePolicy
    }
    var loggingEnabled: Bool {
        return request.loggingEnabled
    }
    var errorReportingEnabled: Bool {
        return true
    }
    var progressTrackingEnabled: Bool {
        return true
    }
    
    init(request: HttpRequest<T>) {
        self.request = request
        super.init()
        do {
            let urlRequest = try request.request(cachePolicy)
            if loggingEnabled { HttpLogging.logRequest(urlRequest) }
            NSURLSession(configuration: request.configuration, delegate: self, delegateQueue: queue).dataTaskWithRequest(urlRequest).resume()
        } catch where errorReportingEnabled {
            returnError(error)
        } catch {}
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        returnProgress(task)
    }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        completedSendingData = true
        returnProgress(dataTask)
        self.data.appendData(data)
    }
    
    func returnProgress(dataTask: NSURLSessionTask) {
        if progressTrackingEnabled {
            let sentProgress = progress(dataTask.countOfBytesSent, dataTask.countOfBytesExpectedToSend, completedSendingData)
            let recievedProgress = progress(dataTask.countOfBytesReceived, dataTask.countOfBytesExpectedToReceive, completedRecievingData)
            request.queue.addOperationWithBlock {
                self.request.progress?(sentProgress, recievedProgress)
            }
        }
    }
    
    func progress(count: Int64, _ expected: Int64, _ completed: Bool) -> Double {
        if expected > 0 {
            return Double(count)/Double(expected)
        } else {
            return completed ? 1 : 0
        }
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        completedRecievingData = true
        returnProgress(task)
        do {
            returnResponse(try getHttpResponse(task, error: error))
        } catch let error where errorReportingEnabled {
            returnError(error)
        } catch {}
        session.finishTasksAndInvalidate()
    }
    
    func getHttpResponse(task: NSURLSessionTask, error: NSError?) throws -> HttpResponse<T>  {
        if let error = error { throw error }
        let responseTime = NSDate().timeIntervalSinceDate(startDate)
        guard let response = task.response as? NSHTTPURLResponse, let request = task.originalRequest else { throw HttpError.UnknownError }
        if loggingEnabled { HttpLogging.logResponse(response, request: request, responseTime: responseTime, data: data) }
        if !(200..<300).contains(response.statusCode) { throw HttpError.HttpError(response: response, data: data) }
        return HttpResponse(body: try T.initializeWithData(data, options: self.request.convertibleOptions), responseTime: responseTime, request: request, urlResponse: response)
    }

    func returnResponse(response: HttpResponse<T>) {
        request.queue.addOperationWithBlock {
            self.request.success?(response)
            self.request.completion?(response, nil)
        }
    }

    func returnError(error: ErrorType) {
        request.queue.addOperationWithBlock {
            self.request.failure?(error)
            self.request.completion?(nil, error)
        }
    }

}

class HttpCacheTask<T : DataInitializable> : HttpStandardTask<T> {
    
    override init(request: HttpRequest<T>) {
        super.init(request: request)
    }
    
    override var cachePolicy: NSURLRequestCachePolicy {
        return NSURLRequestCachePolicy.ReturnCacheDataDontLoad
    }
    
    override var loggingEnabled: Bool {
        return false
    }
    
    override var errorReportingEnabled: Bool {
        return request.success == nil && request.completion == nil
    }
    
    override var progressTrackingEnabled: Bool {
        return false
    }
    
    override func returnResponse(response: HttpResponse<T>) {
        request.queue.addOperationWithBlock {
            self.request.cache?(response)
        }
    }
    
}

class HttpNetworkTask<T : DataInitializable> : HttpStandardTask<T> {
    
    override init(request: HttpRequest<T>) {
        super.init(request: request)
    }
    
    override var cachePolicy: NSURLRequestCachePolicy {
        return NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
    }
    
}

