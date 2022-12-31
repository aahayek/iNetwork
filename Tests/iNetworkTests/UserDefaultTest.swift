//
//  UserDefaultTest.swift
//  iNetworkTests
//
//  Created by Ahmad Alhayek on 12/29/22.
//

import XCTest
import Combine
import iNetwork

final class UserDefaultTest: XCTestCase {
    
    @UserDefault<Int64>(key: "user-default-test-storge") var storge

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testingAssigningValue() {
        let initilValue = storge
        let nextValue = 1 + (initilValue ?? 0)
        storge = nextValue
        let finalValue = storge

        XCTAssertNotEqual(initilValue, nextValue)
        XCTAssertEqual(finalValue, nextValue)
    }

    func testingProjectedValue() {
        let initilValue = storge
        let nextValue =  1 + (initilValue ?? 0)
        var finalValue: Int64?
        let cancellable = $storge.sink { value in
            finalValue = value
        }
        XCTAssertNotEqual(initilValue, nextValue)
        storge = nextValue
        XCTAssertEqual(finalValue, nextValue)
        storge = nextValue + finalValue!
        XCTAssertEqual(finalValue, nextValue * 2)
        cancellable.cancel()
    }

}
