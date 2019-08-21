//
//  zLeetCodeProTests.swift
//  zLeetCodeProTests
//
//  Created by 周向真 on 2019/8/12.
//  Copyright © 2019 周向真. All rights reserved.
//

import XCTest
@testable import zLeetCodePro

class zLeetCodeProTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testResourceSuccess() {
        let resource = Resource<String>(request: URLRequest(url: URL(string: "https://google.com")!)) { (_, _) -> String? in
            return "Resource"
        }
        
        APIServiceMock.shared.load(from: resource) { (result: Result<String, APIError>) in
            switch result {
            case .failure(_):
                XCTAssert(false)
            case let .success(data):
                XCTAssert(data == "Resource")
            }
        }
    }
    
    func testResourceDecodeFailure() {
        let resource = Resource<String>(request: URLRequest(url: URL(string: "https://google.com")!)) { (_, _) -> String? in
            throw APIError.invalidCredential
        }
        
        APIServiceMock.shared.load(from: resource) { result in
            switch result {
            case .failure(let error):
                XCTAssert(error == APIError.invalidCredential)
            case .success:
                XCTAssert(false)
            }
        }
    }
    
    func testResourceEmptyFailure() {
        let resource = Resource<String>(request: URLRequest(url: URL(string: "https://google.com")!)) { (_, _) -> String? in
            return nil
        }
        
        APIServiceMock.shared.load(from: resource) { result in
            switch result {
            case .failure(let error):
                XCTAssert(error == .empty)
            case .success:
                XCTAssert(false)
            }
        }
    }
    
    func testCombinedNext() {
        var resource1Parsed = false
        var resource2Parsed = false
        
        let resource1 = Resource<String>(request: URLRequest(url: URL(string: "https://google.com")!)) { (_, _) -> String? in
            resource1Parsed = true
            return "Resource1 parsed"
        }
        
        let combine = resource1.combinable.next { (data) -> combined<String> in
            XCTAssert(data == "Resource1 parsed")
            
            return Resource<String>(request: URLRequest(url: URL(string: "https://google.com")!)) { (_, _) -> String? in
                resource2Parsed = true
                return "Resource2 parsed"
            }.combinable
        }
        
        APIServiceMock.shared.load(from: combine) { (result) in
            switch result {
            case .failure:
                XCTAssert(false)
            case .success(let r):
                XCTAssert(r == "Resource2 parsed")
                XCTAssert(resource1Parsed)
                XCTAssert(resource2Parsed)
            }
        }
    }
    
    func testCombinedNextInterruptFailure() {
        var resource1Parsed = false
        
        let resource1 = Resource<String>(request: URLRequest(url: URL(string: "https://google.com")!)) { (_, _) -> String? in
            resource1Parsed = true
            return "Resource1 parsed"
        }
        
        let combine = resource1.combinable.next { (data) -> combined<String> in
            XCTAssert(data == "Resource1 parsed")
            
            return combined.asInterrupt(.failure(.interrupted))
        }
        
        APIServiceMock.shared.load(from: combine) { (result) in
            switch result {
            case .failure(let error):
                XCTAssert(error == .interrupted)
                XCTAssert(resource1Parsed)
            case .success:
                XCTAssert(false)
            }
        }
    }
    
    func testCombinedNextInterruptSuccess() {
        var resource1Parsed = false
        
        let resource1 = Resource<String>(request: URLRequest(url: URL(string: "https://google.com")!)) { (_, _) -> String? in
            resource1Parsed = true
            return "Resource1 parsed"
        }
        
        let combine = resource1.combinable.next { (data) -> combined<String> in
            XCTAssert(data == "Resource1 parsed")
            
            return combined.asInterrupt(.success("Interrupted success"))
        }
        
        APIServiceMock.shared.load(from: combine) { (result) in
            switch result {
            case .failure:
                XCTAssert(false)
            case .success(let r):
                XCTAssert(r == "Interrupted success")
                XCTAssert(resource1Parsed)
            }
        }
    }
    
    func testCombinedRetrySuccess() {
        let count = 0
        let resource1 = Resource<Int>(get: URL(string: "https://google.com")!) { (_, _) -> Int? in
            print("parsing: [count] = \(count)")
            return count
        }
        
        let c = resource1.combinable.retryable { (data) -> combined<Int> in
            print("retrying: [count] = \(data)")
            XCTAssert(data < 6)
            
            if data == 5 {
                return combined.asInterrupt(.success(251))
            }
            
            return Resource<Int>(get: URL(string: "https://google.com")!) { (_, _) in
                data + 1
            }.combinable
        }
        
        APIServiceMock.shared.load(from: c) { (result) in
            switch result {
            case .failure:
                XCTAssert(false)
            case .success(let r):
                XCTAssert(r == 251)
            }
        }
    }
    
    func testCombinedRetryEmpty() {
        let count = 0
        let resource1 = Resource<Int>(get: URL(string: "https://google.com")!) { (_, _) -> Int? in
            print("parsing: [count] = \(count)")
            return count
        }
        
        let c = resource1.combinable.retryable { (data) -> combined<Int> in
            print("retrying: [count] = \(data)")
            XCTAssert(data == 0)
            return Resource<Int>(get: URL(string: "https://google.com")!) { (_, _) in
                return nil
            }.combinable
        }
        
        APIServiceMock.shared.load(from: c) { (result) in
            switch result {
            case .failure(let error):
                XCTAssert(error == .empty)
            case .success:
                XCTAssert(false)
            }
        }
    }
}
