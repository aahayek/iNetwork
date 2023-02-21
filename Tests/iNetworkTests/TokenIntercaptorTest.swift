//
//  TokenIntercaptorTest.swift
//  iNetworkTests
//
//  Created by Ahmad Alhayek on 12/29/22.
//

import XCTest
import iNetwork
import Combine

final class TokenIntercaptorTest: XCTestCase {
    let token = "testingCacheToken"
    var restPerformer: RestPerformer!
    var tokenIntercepor: TokenInterceptor!
    @UserDefault<String>(key: coreTokenAuthinticationKey) var tokenCache
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        restPerformer = RestPerformerImpl(urlSession: MocKRestSession())
        tokenIntercepor = TokenInterceptor()
        restPerformer.addInteractor(tokenIntercepor)
        tokenCache = token
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        restPerformer = nil
    }

    func testAddingTokenToUrlRequest() throws {
        let mockTokenIntercpter = MockInterceptor(interceptChain: { [weak self] rest in
            let requestAuth = rest.urlRequest.value(forHTTPHeaderField: TokenInterceptor.authHttpField)
    
            let expectedAuth = TokenInterceptor.generateBearerWithToken(self?.tokenCache ?? "")
            XCTAssertEqual(requestAuth,
                           expectedAuth)
        })
        restPerformer.addInteractor(mockTokenIntercpter)
        var request: URLRequest = .init(url: URL(string: "https://the-trivia-api.com/api/categories")!)
        request.addValue("", forHTTPHeaderField: MocKRestSession.httpHeaderFieldForMockCode)
        let publisher: AnyPublisher<Data, ServiceError> = restPerformer.response(for: request)
        
        _ = try awaitPublisherSuccess(publisher, timeoutAfter: 0, expectationDescription: "")
    }
    
}
