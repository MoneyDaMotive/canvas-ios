//
// Copyright (C) 2016-present Instructure, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import XCTest
@testable import Core

class API_Tests: XCTestCase {
    struct DateHaver: Codable, Equatable {
        let date: Date
    }

    struct InvalidScheme: APIRequestable {
        typealias Response = DateHaver
        let path = "custom://host.tld/api/v1"
    }

    struct InvalidPath: APIRequestable {
        typealias Response = DateHaver
        let path = "<>"
    }

    struct WrongResponse: APIRequestable {
        typealias Response = DateHaver
        let path = "https://canvas.instructure.com/api/v1/accounts/search"
    }

    func testUrlSession() {
        let session = URLSessionAPI().urlSession
        XCTAssertNil(session.configuration.urlCache)
    }

    func testMakeRequestInvalidPath() {
        let expectation = XCTestExpectation(description: "request callback runs")
        URLSessionAPI().makeRequest(InvalidPath()) { value, response, error in
            XCTAssertNil(value)
            XCTAssertNil(response)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testMakeRequestUnsupported() {
        let expectation = XCTestExpectation(description: "request callback runs")
        URLSessionAPI().makeRequest(InvalidScheme()) { value, response, error in
            XCTAssertNil(value)
            XCTAssertNil(response)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testMakeRequestWrongResponse() {
        let expectation = XCTestExpectation(description: "request callback runs")
        URLSessionAPI().makeRequest(WrongResponse()) { value, response, error in
            XCTAssertNil(value)
            XCTAssertNotNil(response)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }

    func testNoCredsNeeded() {
        let expectation = XCTestExpectation(description: "request callback runs")
        URLSessionAPI().makeRequest(GetAccountsSearch()) { value, response, error in
            XCTAssertNotNil(value)
            XCTAssertNotNil(response)
            XCTAssertNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }
}
