//
//  XCTestCase+extention.swift
//  
//
//  Created by Ahmad Alhayek on 12/29/22.
//

import Foundation
import XCTest
import Combine

extension XCTestCase {
    func awaitPublisherSuccess<T: Publisher>(_ publisher: T, timeoutAfter time: TimeInterval,
                                             expectationDescription description: String) throws -> (T.Output?, T.Failure?) {
        let expectation = expectation(description: description)
        var result: Result<T.Output, T.Failure>?
        let cancellable = publisher.sink { completion in
            if case let .failure(error) = completion {
                result = .failure(error)
            }
            
            expectation.fulfill()
        } receiveValue: { output in
            result = .success(output)
        }

        wait(for: [expectation], timeout: time)
        cancellable.cancel()
        switch result {
        case.failure(let error):
            return (nil, error)
        case .success(let wrapped):
            return (wrapped, nil)
        default:
            return (nil, nil)
        }
    }
}
