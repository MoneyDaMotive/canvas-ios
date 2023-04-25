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

import Combine

class CourseSyncSelectorInteractorPreview: CourseSyncSelectorInteractor {
    private var mockData: [CourseSyncEntry]

    init() {
        mockData = [
            .init(name: "Black Hole",
                  id: "0",
                  tabs: [
                    .init(id: "0", name: "Assignments", type: .assignments),
                    .init(id: "1", name: "Discussion", type: .assignments),
                    .init(id: "2", name: "Grades", type: .assignments),
                    .init(id: "3", name: "People", type: .assignments),
                    .init(id: "4", name: "Files", type: .files),
                    .init(id: "5", name: "Syllabus", type: .assignments),
                  ],
                  files: [
                    .init(id: "0", name: "Creative Machines and Innovative Instrumentation.mov", url: nil),
                    .init(id: "0", name: "Intro Energy, Space and Time.mov", url: nil),
                  ])
        ]
        mockData[0].isCollapsed = false
    }

    func getCourseSyncEntries() -> AnyPublisher<[CourseSyncEntry], Error> {
        Future<[CourseSyncEntry], Error> { [mockData] promise in
            promise(.success(mockData))
        }.eraseToAnyPublisher()

    }

    func observeSelectedCount() -> AnyPublisher<Int, Never> {
        Future<Int, Never> { promise in
            promise(.success(0))
        }.eraseToAnyPublisher()
    }

    func setSelected(selection: CourseEntrySelection, isSelected: Bool) {

    }
}
