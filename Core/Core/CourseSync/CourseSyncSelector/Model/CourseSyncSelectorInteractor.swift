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
import CombineExt
import Foundation

protocol CourseSyncSelectorInteractor {
    func getCourseSyncEntries() -> AnyPublisher<[CourseSyncEntry], Error>
    func observeSelectedCount() -> AnyPublisher<Int, Never>
    func setSelected(selection: CourseEntrySelection, isSelected: Bool)
}

final class CourseSyncSelectorInteractorLive: CourseSyncSelectorInteractor {
    private let courseListStore = ReactiveStore(
        useCase: GetCourseListCourses(enrollmentState: .active)
    )
    private let courseSyncEntries = CurrentValueRelay<[CourseSyncEntry]>(.init())
    private var subscriptions = Set<AnyCancellable>()

    func getCourseSyncEntries() -> AnyPublisher<[CourseSyncEntry], Error> {
        courseListStore.getEntities()
            .flatMap { Publishers.Sequence(sequence: $0).setFailureType(to: Error.self) }
            .flatMap { course in
                Publishers.Zip(
                    self.getTabs(courseId: course.courseId),
                    self.getAllFiles(courseId: course.courseId)
                )
                .map {
                    CourseSyncEntry(
                        name: course.name,
                        id: course.courseId,
                        tabs: $0.0,
                        files: $0.1
                    )
                }
            }
            .collect()
            .handleEvents(receiveOutput: { self.courseSyncEntries.accept($0) })
            .eraseToAnyPublisher()
    }

    func observeSelectedCount() -> AnyPublisher<Int, Never> {
        courseSyncEntries
            .map {
                $0.reduce(0) { partialResult, entry in
                    partialResult + (entry.selectedFilesCount + entry.selectedTabsCount)
                }
            }
            .eraseToAnyPublisher()
    }

    func setSelected(selection: CourseEntrySelection, isSelected: Bool) {
        var entries = courseSyncEntries.value

        switch selection {
        case .course(let courseIndex):
            entries[courseIndex].isSelected = isSelected
        case .tab(let courseIndex, let tabIndex):
            entries[courseIndex].selectTab(index: tabIndex, isSelected: isSelected)
        case .file(let courseIndex, let fileIndex):
            entries[courseIndex].selectFile(index: fileIndex, isSelected: isSelected)
        }

        courseSyncEntries.accept(entries)
    }

    private func getTabs(courseId: String) -> AnyPublisher<[CourseSyncEntry.Tab], Error> {
        ReactiveStore(
            useCase: GetContextTabs(
                context: Context.course(courseId)
            )
        )
        .getEntities()
        .map { $0.offlineSupportedTabs() }
        .map {
            $0.map {
                CourseSyncEntry.Tab(
                    id: $0.id,
                    name: $0.label,
                    type: $0.name
                )
            }
        }
        .eraseToAnyPublisher()
    }

    private func getAllFiles(courseId: String) -> AnyPublisher<[CourseSyncEntry.File], Error> {
        ReactiveStore(
            useCase: GetFolderByPath(
                context: .course(courseId)
            )
        )
        .getEntities()
        .flatMap {
            Publishers.Sequence(sequence: $0)
                .setFailureType(to: Error.self)
                .flatMap { self.getFiles(folderID: $0.id, initialArray: []) }
        }
        .map {
            $0.map {
                CourseSyncEntry.File(
                    id: $0.file?.id ?? Foundation.UUID().uuidString,
                    name: $0.file?.displayName ?? "Unknown file",
                    url: $0.file?.url
                )
            }
        }
        .eraseToAnyPublisher()
    }

    private func getFiles(folderID: String, initialArray: [FolderItem]) -> AnyPublisher<[FolderItem], Error> {
        var result = initialArray

        return getFilesAndFolderIDs(folderID: folderID)
            .flatMap { files, folderIDs in
                result.append(contentsOf: files)

                guard folderIDs.count > 0 else {
                    return Just([result])
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
                return Publishers.Sequence(sequence: folderIDs)
                    .setFailureType(to: Error.self)
                    .flatMap {
                        self.getFiles(folderID: $0, initialArray: result)
                            .handleEvents(
                                receiveOutput: {
                                    result.append(contentsOf: $0)
                                }
                            )
                    }
                    .collect()
                    .eraseToAnyPublisher()
            }
            .map { _ in result }
            .eraseToAnyPublisher()
    }

    private func getFilesAndFolderIDs(folderID: String) -> AnyPublisher<([FolderItem], [String]), Error> {
        return ReactiveStore(
            useCase: GetFolderItems(
                folderID: folderID
            )
        )
        .getEntities()
        .retry(3)
        .tryCatch { error -> AnyPublisher<[FolderItem], Error> in
            if case .unauthorized = error as? Core.APIError {
                return Just([])
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            } else {
                throw error
            }
        }
        .map {
            let files = $0.filter { $0.file != nil }
            let folderIDs = $0
                .filter { $0.folder != nil }
                .compactMap { $0.folder }
                .map { $0.id }

            return (files, folderIDs)
        }
        .eraseToAnyPublisher()
    }
}

enum CourseEntrySelection {
    typealias CourseIndex = Int
    typealias TabIndex = Int
    typealias FileIndex = Int

    case course(CourseIndex)
    case tab(CourseIndex, TabIndex)
    case file(CourseIndex, FileIndex)
}

struct CourseSyncEntry {
    struct Tab {
        let id: String
        let name: String
        let type: TabName
        var isCollapsed: Bool = true
        var isSelected: Bool = true
    }

    struct File {
        let id: String
        let name: String
        let url: URL?
        var isSelected: Bool = true
    }

    let name: String
    let id: String

    var tabs: [Self.Tab]
    var selectedTabsCount: Int {
        tabs.reduce(0) { partialResult, tab in
            partialResult + (tab.isSelected ? 1 : 0)
        }
    }

    var files: [Self.File]
    var selectedFilesCount: Int {
        files.reduce(0) { partialResult, file in
            partialResult + (file.isSelected ? 1 : 0)
        }
    }

    var isCollapsed: Bool = true
    var isSelected: Bool = true {
        didSet {
            tabs.indices.forEach { tabs[$0].isSelected = isSelected }
            files.indices.forEach { files[$0].isSelected = isSelected }
        }
    }

    mutating func selectTab(index: Int, isSelected: Bool) {
        tabs[index].isSelected = isSelected

        guard tabs[index].type == .files else {
            return
        }

        files.indices.forEach { files[$0].isSelected = isSelected }
    }

    mutating func selectFile(index: Int, isSelected: Bool) {
        files[index].isSelected = isSelected
        guard let fileTabIndex = tabs.firstIndex(where: { $0.type == TabName.files } ) else {
            return
        }
        tabs[fileTabIndex].isSelected = files.count == selectedFilesCount
    }
}
