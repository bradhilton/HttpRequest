//
//  File.swift
//  HttpRequest
//
//  Created by Bradley Hilton on 7/2/15.
//  Copyright © 2015 Skyvive. All rights reserved.
//

import Foundation

/// Base web service. Subclass and override init() to customize.
public class HttpService {
    
    public var path = ""
    public var headers = [String: String]()
    public var params = [String: String]()
    public var configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
    public var convertibleOptions = [ConvertibleOption]()
    public var failure: ((ErrorType) -> ())?
    public var logging = false
    required public init() {}
    
    func loadSettingsIntoRequest<T>(inout request: HttpRequest<T>) {
        request.basePath = path
        request.headers = headers
        request.parameters = params
        request.loggingEnabled = logging
        request.configuration = configuration
        request.convertibleOptions = convertibleOptions
        request.failure = failure
    }
    
}
