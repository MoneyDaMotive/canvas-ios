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

class APIOAuth_Requestable_Tests: XCTestCase {
    func testGetMobileVerify() {
        XCTAssertEqual(GetMobileVerify(domain: "cgnu").path, "https://canvas.instructure.com/api/v1/mobile_verify.json")
        XCTAssertEqual(GetMobileVerify(domain: "cgnu").queryItems, [
            URLQueryItem(name: "domain", value: "cgnu"),
        ])
    }

    func testPostLoginOAuth() {
        let client = APIVerifyClient(authorized: true, base_url: URL(string: "https://cgnuonline-eniversity.edu"), client_id: "cgnu", client_secret: "dna evidence")
        XCTAssertEqual(PostLoginOAuth(client: client, code: "1234").method, .post)
        XCTAssertEqual(PostLoginOAuth(client: client, code: "1234").path, "https://cgnuonline-eniversity.edu/login/oauth2/token")
        XCTAssertEqual(PostLoginOAuth(client: client, code: "1234").queryItems, [
            URLQueryItem(name: "client_id", value: "cgnu"),
            URLQueryItem(name: "client_secret", value: "dna evidence"),
            URLQueryItem(name: "code", value: "1234"),
        ])
    }

    func testPostLoginOAuthUnauthorized() {
        let client = APIVerifyClient(authorized: false, base_url: nil, client_id: nil, client_secret: nil)
        XCTAssertEqual(PostLoginOAuth(client: client, code: "1234").path, "login/oauth2/token")
        XCTAssertEqual(PostLoginOAuth(client: client, code: "1234").queryItems, [
            URLQueryItem(name: "client_id", value: ""),
            URLQueryItem(name: "client_secret", value: ""),
            URLQueryItem(name: "code", value: "1234"),
        ])
    }
}
