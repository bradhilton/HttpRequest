//
//  HttpLogging.swift
//  HttpRequest
//
//  Created by Bradley Hilton on 9/1/15.
//  Copyright © 2015 Skyvive. All rights reserved.
//

import Foundation

struct HttpLogging {
    
    static func logRequest(request: NSURLRequest) {
        if let method = request.HTTPMethod,
            let url = request.URL?.absoluteString {
                print("\n---> \(method) \(url)")
                printHeaderFields(request.allHTTPHeaderFields)
                printBody(request.HTTPBody)
                print("---> END " + bytesDescription(request.HTTPBody))
        }
    }
    
    static func logResponse(response: NSURLResponse?, request: NSURLRequest?, responseTime: NSTimeInterval, data: NSData?) {
        if let request = request,
            let method = request.HTTPMethod,
            let url = request.URL?.absoluteString,
            let response = response as? NSHTTPURLResponse {
                print("\n<--- \(method) \(url) (\(response.statusCode), \(responseTimeDescription(responseTime)))")
                printHeaderFields(response.allHeaderFields)
                printBody(data)
                print("<--- END " + bytesDescription(data))
        }
    }
    
    private static func responseTimeDescription(responseTime: NSTimeInterval) -> NSString {
        return NSString(format: "%0.2fs", responseTime)
    }
    
    private static func printHeaderFields(headerFields: [NSObject : AnyObject]?) {
        if let headerFields = headerFields {
            for (field, value) in headerFields {
                print("\(field): \(value)")
            }
        }
    }
    
    private static func printBody(data: NSData?) {
        if let body = data,
            let bodyString = NSString(data: body, encoding: NSUTF8StringEncoding) where bodyString.length > 0 {
                print(bodyString)
        }
    }
    
    private static func bytesDescription(data: NSData?) -> String {
        return "(\(data != nil ? data!.length : 0) bytes)"
    }
    
}