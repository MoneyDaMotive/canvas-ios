// @flow

import React from 'react'
import {
  SpeedGrader,
  refreshSpeedGrader,
  shouldRefresh,
  isRefreshing,
} from '../SpeedGrader'
import renderer from 'react-test-renderer'

jest.mock('../components/GradePicker')

const templates = {
  ...require('../../../api/canvas-api/__templates__/submissions'),
  ...require('../../../redux/__templates__/app-state'),
  ...require('../../../__templates__/react-native-navigation'),
  ...require('../../submissions/list/__templates__/submission-props'),
}

let ownProps = {
  assignmentID: '1',
  userID: '1',
  courseID: '1',
}

let defaultProps = {
  ...ownProps,
  pending: false,
  refreshing: false,
  refresh: jest.fn(),
  refreshSubmissions: jest.fn(),
  navigator: templates.navigator(),
  submissions: [],
}

describe('SpeedGrader', () => {
  it('renders', () => {
    let tree = renderer.create(
      <SpeedGrader {...defaultProps} />
    ).toJSON()

    expect(tree).toMatchSnapshot()
    expect(defaultProps.navigator.setTitle).toHaveBeenCalledWith({
      title: 'SpeedGrader',
    })
    expect(defaultProps.navigator.setOnNavigatorEvent).toHaveBeenCalled()
  })

  it('shows the loading spinner when there are no submissions', () => {
    let tree = renderer.create(
      <SpeedGrader {...defaultProps} />
    ).toJSON()

    expect(tree).toMatchSnapshot()
  })

  it('shows the loading spinner when pending and not refreshing', () => {
    let tree = renderer.create(
      <SpeedGrader {...defaultProps} pending={true} />
    ).toJSON()

    expect(tree).toMatchSnapshot()
  })

  it('calls dismissModal when done is pressed', () => {
    let tree = renderer.create(
      <SpeedGrader {...defaultProps} />
    )

    tree.getInstance().onNavigatorEvent({
      type: 'NavBarButtonPress',
      id: 'done',
    })

    expect(defaultProps.navigator.dismissModal).toHaveBeenCalled()
  })

  it('renders submissions if there are some', () => {
    const submissions = [templates.submissionProps()]
    const props = { ...defaultProps, submissions }
    let tree = renderer.create(
      <SpeedGrader {...props} />
    ).toJSON()

    expect(tree).toMatchSnapshot()
  })
})

describe('refresh functions', () => {
  const props = {
    courseID: '12',
    assignmentID: '55',
    userID: '145',
    refreshSubmissions: jest.fn(),
    refreshEnrollments: jest.fn(),
    submissions: [],
    refresh: jest.fn(),
    refreshing: false,
    pending: false,
    navigator: templates.navigator(),
  }
  it('refreshSubmissions', () => {
    refreshSpeedGrader(props)
    expect(props.refreshSubmissions).toHaveBeenLastCalledWith(props.courseID, props.assignmentID)
    expect(props.refreshEnrollments).toHaveBeenLastCalledWith(props.courseID)
  })
  it('isRefreshing', () => {
    const isNot = isRefreshing(props)
    expect(isNot).toBeFalsy()

    const is = isRefreshing({ ...props, pending: true })
    expect(is).toBeTruthy()
  })
  it('shouldRefresh', () => {
    const should = shouldRefresh(props)
    expect(should).toBeTruthy()

    const submissions = [templates.submissionProps()]
    const shouldNot = shouldRefresh({ ...props, submissions })
    expect(shouldNot).toBeFalsy()
  })
})
