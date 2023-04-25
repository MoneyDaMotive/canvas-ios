//
// This file is part of Canvas.
// Copyright (C) 2023-present  Instructure, Inc.
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
import TestsFoundation

struct PeopleListCell {
    let index: Int
    lazy var cell: Element = {
        return app.find(id: "people-list-cell-row-\(index)")
    }()

    lazy var name: String = {
        return app.find(id: "people-list-cell-row-\(index).name-label").label()
    }()

    lazy var role: String = {
        return app.find(id: "people-list-cell-row-\(index).role-label").label()
    }()
}

class DSPeopleE2ETests: E2ETestCase {
    // Follow-up of MBL-15555
    func testPeopleListRoleE2E() {
        let users = seeder.createUsers(2)
        let course = seeder.createCourse()
        let teacher = users[0]
        let student = users[1]
        seeder.enrollTeacher(teacher, in: course)
        seeder.enrollStudent(student, in: course)

        logInDSUser(teacher)
        Dashboard.courseCard(id: course.id).tap()
        CourseNavigation.people.tap()

        var testStudent = PeopleListCell(index: 1)
        testStudent.cell.waitToExist()

        XCTAssertEqual(testStudent.name, student.name)
        XCTAssertEqual(testStudent.role, "Student")
        testStudent.cell.tap()
        NavBar.backButton.tap()
        testStudent.cell.waitToExist()
        XCTAssertEqual(testStudent.role, "Student")
    }
}
