//
// This file is part of Canvas.
// Copyright (C) 2019-present  Instructure, Inc.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
//

import Foundation
import XCTest
import Core
import SwiftUI
@testable import Teacher
@testable import CanvasCore

class RoutesTests: XCTestCase {
    let route = URLComponents(string: "https://canvas.instructure.com/api/v1/courses/1")!

    func userInfoFromRoute(options: RouteOptions) -> [AnyHashable: Any]? {
        let expectation = self.expectation(description: "route notification")
        let name = NSNotification.Name("route")
        var userInfo: [AnyHashable: Any]?
        let observer = NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil) { note in
            userInfo = note.userInfo
            expectation.fulfill()
        }
        router.route(to: route, from: UIViewController(), options: options)
        wait(for: [expectation], timeout: 0.5)
        NotificationCenter.default.removeObserver(observer)
        XCTAssertNotNil(userInfo)
        return userInfo
    }

    func testRouteSendsNotification() {
        let userInfo = userInfoFromRoute(options: .push)
        XCTAssertEqual(userInfo?["url"] as? String, route.url!.absoluteString)
        XCTAssertNil(userInfo?["modal"])
        XCTAssertNil(userInfo?["detail"])
        XCTAssertNil(userInfo?["embedInNavigationController"])
    }

    func testModalOption() {
        let userInfo = userInfoFromRoute(options: .modal(.fullScreen, isDismissable: false, embedInNav: true, addDoneButton: true))
        XCTAssertEqual(userInfo?["url"] as? String, route.url!.absoluteString)
        XCTAssertEqual(userInfo?["modal"] as? Bool, true)
        XCTAssertNil(userInfo?["detail"])
        XCTAssertEqual(userInfo?["embedInNavigationController"] as? Bool, true)
        XCTAssertEqual(userInfo?["disableSwipeDownToDismissModal"] as? Bool, true)
        XCTAssertEqual(userInfo?["modalPresentationStyle"] as? String, "fullscreen")

        let formSheet = userInfoFromRoute(options: .modal(.formSheet))
        XCTAssertEqual(formSheet?["embedInNavigationController"] as? Bool, false)
        XCTAssertEqual(formSheet?["disableSwipeDownToDismissModal"] as? Bool, false)
        XCTAssertEqual(formSheet?["modalPresentationStyle"] as? String, "formsheet")
    }

    func testDetailOption() {
        let userInfo = userInfoFromRoute(options: .detail)
        XCTAssertEqual(userInfo?["url"] as? String, route.url!.absoluteString)
        XCTAssertNil(userInfo?["modal"])
        XCTAssertEqual(userInfo?["detail"] as? Bool, true)
        XCTAssertEqual(userInfo?["embedInNavigationController"] as? Bool, true)
    }

    func testRoutes() {
        let appDelegate = UIApplication.shared.delegate as! TeacherAppDelegate
        ExperimentalFeature.nativeDashboard.isEnabled = true
        appDelegate.registerNativeRoutes()
        for (template, _) in HelmManager.shared.nativeViewControllerFactories {
            HelmManager.shared.registerRoute(template)
        }
        XCTAssert(router.match("/courses/2/attendance/5") is AttendanceViewController)
        XCTAssert(router.match("/courses") is CoreHostingController<CourseListView>)
        XCTAssert(router.match("/courses/2/modules") is ModuleListViewController)
        XCTAssert(router.match("/courses/2/modules/2") is ModuleListViewController)
        XCTAssert(router.match("/courses/3/pages") is PageListViewController)
        XCTAssert(router.match("/courses/8/users") is PeopleListViewController)
        XCTAssert(router.match("/courses/3/wiki") is PageDetailsViewController)
        XCTAssert(router.match("/groups/3/pages/page2") is PageDetailsViewController)
        XCTAssert(router.match("/groups/3/wiki/page2") is PageDetailsViewController)
        XCTAssert(router.match("/courses/7/modules/5/items/6") is ModuleItemSequenceViewController)
        XCTAssert(router.match("/courses/7/modules/items/6") is ModuleItemSequenceViewController)
        XCTAssert(router.match("/courses/9/module_item_redirect/8") is ModuleItemSequenceViewController)
        XCTAssert(router.match("/courses/2/announcements/3") is DiscussionDetailsViewController)
        XCTAssert(router.match("/courses/2/discussions/3") is DiscussionDetailsViewController)
        XCTAssert(router.match("/courses/2/discussion_topics/3") is DiscussionDetailsViewController)
        XCTAssert(router.match("/courses/2/discussion_topics/3/reply") is DiscussionReplyViewController)
        XCTAssert(router.match("/courses/2/discussion_topics/3/entries/4/replies") is DiscussionReplyViewController)
        ExperimentalFeature.nativeSpeedGrader.isEnabled = false
        XCTAssert(router.match("/courses/1/assignments/1/submissions") is HelmViewController)
        XCTAssert(router.match("/courses/1/assignments/1/submissions/1") is HelmViewController)
        ExperimentalFeature.nativeSpeedGrader.isEnabled = true
        XCTAssert(router.match("/courses/1/assignments/1/submissions") is SubmissionListViewController)
        XCTAssert(router.match("/courses/1/assignments/1/submissions/1") is CoreHostingController<SpeedGraderView>)
        XCTAssert(router.match("/files") is FileListViewController)
        XCTAssert(router.match("/users/self/files") is FileListViewController)
        XCTAssert(router.match("/files/folder/f1") is FileListViewController)
        XCTAssert(router.match("/groups/2/files/folder/f1") is FileListViewController)
        XCTAssert(router.match("/folders/2/edit") is CoreHostingController<FileEditorView>)
        XCTAssert(router.match("/files/1/edit") is CoreHostingController<FileEditorView>)
        XCTAssert(router.match("/courses/1/files/1/edit") is CoreHostingController<FileEditorView>)
        XCTAssert(router.match("/files?preview=7") is FileDetailsViewController)
        XCTAssert(router.match("/files/1") is FileDetailsViewController)
        XCTAssert(router.match("/files/1/download") is FileDetailsViewController)
        XCTAssert(router.match("/files/1/preview") is FileDetailsViewController)
        XCTAssert(router.match("/courses/1/files/1") is FileDetailsViewController)
        XCTAssert(router.match("/courses/1/files/1/download") is FileDetailsViewController)
        XCTAssert(router.match("/courses/1/files/1/preview") is FileDetailsViewController)
        XCTAssert(router.match("/act-as-user") is ActAsUserViewController)
        XCTAssert(router.match("/act-as-user/1") is ActAsUserViewController)
        XCTAssert(router.match("/wrong-app") is WrongAppViewController)
        XCTAssert(router.match("/courses/1/assignments/2/post_policy") is PostSettingsViewController)
        XCTAssert(router.match("/profile") is ProfileViewController)
        XCTAssert(router.match("/profile/settings") is ProfileSettingsViewController)
        XCTAssert(router.match("/dev-menu/experimental-features") is ExperimentalFeaturesViewController)
        XCTAssert(router.match("/support/problem") is ErrorReportViewController)
        XCTAssert(router.match("/support/feature") is ErrorReportViewController)
    }
}
