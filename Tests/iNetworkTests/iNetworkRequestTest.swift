//
//  iNetworkRequestTest.swift
//  iNetworkTests
//
//  Created by Ahmad Alhayek on 12/29/22.
//

import XCTest
import iNetwork
import Combine

struct MockInterceptor: Interceptor {

    var interceptChain: ((RestChain) throws -> Void)?
    var interceptRequest: ((URLRequest, Data?, ServiceError?) throws -> Void)?

    func intercept(chain: RestChain) -> RestChain {
        if let interceptChain {
            try! interceptChain(chain)
        }
        return chain
    }

    func intercept(request: URLRequest, output: Data?, error: ServiceError?) {
        if let interceptRequest {
            try! interceptRequest(request, output, error)
        }
    }
}

final class iNetworkRequestTest: XCTestCase {
    var restPerformer: RestPerformer!
    override func setUpWithError() throws {
        try super.setUpWithError()
        restPerformer = RestPerformerImpl(urlSession: URLSession.shared)
    }
    
    override func tearDownWithError() throws {
       
        try super.tearDownWithError()
        restPerformer = nil
    }
    
    func testFetchingData() throws {
        let request: URLRequest = .init(url: URL(string: "https://the-trivia-api.com/api/categories")!)
        let publisher = restPerformer.response(for: request)
        _ = try awaitPublisherSuccess(publisher, timeoutAfter: 4, expectationDescription: "testing fetch")
        
    }
    
    /// response intercapter then request intercapter
    func testResponseIntercapter() throws {
        let request: URLRequest = .init(url: URL(string: "https://the-trivia-api.com/api/categories")!)
        let responseIntercapter = ResponseRecorderInterceptor()
        restPerformer.addIntercapter(responseIntercapter)
        let publisher = restPerformer.response(for: request)
        
        let data = try awaitPublisherSuccess(publisher, timeoutAfter: 4, expectationDescription: "await fetch and save").0!
        
        
        let requestIntercapter = RequestReaderInterceptor()
        restPerformer.addIntercapter(requestIntercapter)
        
        let mockPublisher = restPerformer.response(for: request)
        
        let mockData = try awaitPublisherSuccess(mockPublisher, timeoutAfter: 4, expectationDescription: "await mock fetch").0!
        
        XCTAssertEqual(mockData.count, data.count)
        
    }
    
}
