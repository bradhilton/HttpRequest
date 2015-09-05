//
//  HttpRequestTests.swift
//  HttpRequestTests
//
//  Created by Bradley Hilton on 7/4/15.
//  Copyright © 2015 Skyvive. All rights reserved.
//

import XCTest
import HttpRequest

class HttpRequestTests: XCTestCase {
    
    func testExample() {
        let expectation = expectationWithDescription("Request")
        Contacts.getContacts
        .progress { (sentProgress, receivedProgress) in
            print("Updating progress")
        }
        .cache { response in
            print("Received cached response")
        }
        .success { response in
            print("Recieved network response")
//            for contact in $0.body {
//                print("\(contact.id) \(contact.firstName) \(contact.lastName) \(contact.birthday)")
//            }
            expectation.fulfill()
        }
        .failure { error in
            XCTFail(String(error))
        }
        waitForExpectationsWithTimeout(10.0, handler: nil)
    }
    
}

typealias Number = NSNumber

struct Contact : StructConvertible, UnderscoreToCamelCase, OptionalKeys {
    var id = 0
    var firstName = ""
    var lastName = ""
    var birthday = ""
    let optionalKeys: [String] = []
}

class API : HttpService {
    
    required init() {
        super.init()
        path = "https://api.sendoutcards.com/v1"
        headers = ["Authorization": "Token a77a499e306b3ea41f574a185522556a8146d76f", "Content-Type": "text/json"]
    }
    
}

class Contacts : API {
    
    class var getContacts: GET<[Contact]> { return GET(self).params(["simple":"true"]) }
    
    required init() {
        super.init()
        path += "/contacts"
    }
    
}

