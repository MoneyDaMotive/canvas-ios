/**
* @flow
*/

import React, { Component, PropTypes } from 'react'
import { connect } from 'react-redux'
import { mapStateToProps, type AssignmentDetailsProps } from './map-state-to-props'
import SubmissionBreakdownGraphSection from './components/SubmissionBreakdownGraphSection'
import SubmissionType from './components/SubmissionType'
import AssignmentSection from './components/AssignmentSection'
import i18n from 'format-message'
import { Heading1, Text } from '../../common/text'
import WebContainer from '../../common/components/WebContainer'
import PublishedIcon from './components/PublishedIcon'
import AssignmentDates from './components/AssignmentDates'
import colors from '../../common/colors'
import { RefreshableScrollView } from '../../common/components/RefreshableList'
import refresh from '../../utils/refresh'
import AssignmentActions from '../assignments/actions'
import Images from '../../images'
import Screen from '../../routing/Screen'

import {
  View,
  StyleSheet,
} from 'react-native'

export class AssignmentDetails extends Component<any, AssignmentDetailsProps, any> {
  props: AssignmentDetailsProps

  render (): React.Element<View> {
    const assignment = this.props.assignmentDetails

    let assignmentPoints = i18n({
      default: 'pts',
      description: 'Assignment Details points for given assignment',
    })

    let sectionTitleDue = i18n({
      default: 'Due',
      description: 'Assignment Details Section title for when assignment is due',
    })

    let sectionTitleSubmissionTypes = i18n({
      default: 'Submission Types',
      description: 'Assignment Details Section title for types of submission, (i.e. online, text, upload, etc)',
    })

    let sectionTitleSubmissions = i18n({
      default: 'Submissions',
      description: 'Assignment Details Section title for info on submissions',
    })

    let sectionTitleDescription = i18n({
      default: 'Description',
      description: 'Assignment Details Section title for assignment Description',
    })

    let descriptionElement = <View />
    if (assignment.description) {
      descriptionElement = (<AssignmentSection title={sectionTitleDescription} >
                              <WebContainer style={{ flex: 1 }} html={assignment.description}/>
                            </AssignmentSection>)
    }

    return (
      <Screen
        navBarColor={this.props.courseColor}
        navBarStyle='dark'
        title={i18n({
          default: 'Assignment Details',
          description: 'Title of Assignment details screen',
        })}
        rightBarButtons={[
          {
            title: i18n({
              default: 'Edit',
              description: 'Shown at the top of the app to allow the user to edit',
            }),
            testID: 'assignment-deets.edit-btn',
            action: this.editAssignment.bind(this),
          },
        ]}
      >
        <RefreshableScrollView
          refreshing={Boolean(this.props.pending)}
          onRefresh={this.props.refresh}
        >
          <AssignmentSection isFirstRow={true} style={style.topContainer}>
            <Heading1>{assignment.name}</Heading1>
            <View style={style.pointsContainer}>
              <Text style={style.points}>{assignment.points_possible} {assignmentPoints}</Text>
              <PublishedIcon published={assignment.published} style={style.publishedIcon} />
            </View>
          </AssignmentSection>

          <AssignmentSection
            title={sectionTitleDue}
            accessibilityLabel={i18n({ default: 'Due Dates, Double tap for details.', description: 'Accessibility label for due dates in assignment details' })}
            image={Images.assignments.calendar}
            showDisclosureIndicator={true}
            onPress={this.viewDueDateDetails} >
            <AssignmentDates assignment={assignment} />
          </AssignmentSection>

          <AssignmentSection title={sectionTitleSubmissionTypes}>
            <SubmissionType data={assignment.submission_types} />
          </AssignmentSection>

          { global.V02 &&
            <AssignmentSection
              title={sectionTitleSubmissions}
              onPress={() => this.viewSubmissions()}
              showDisclosureIndicator>
              <SubmissionBreakdownGraphSection onPress={this.onSubmissionDialPress} courseID={this.props.courseID} assignmentID={this.props.assignmentID} style={style.submission}/>
            </AssignmentSection>
          }

          {descriptionElement}

        </RefreshableScrollView>
      </Screen>
    )
  }

  onSubmissionDialPress = (type: string) => {
    this.viewSubmissions(type)
  }

  editAssignment () {
    this.props.navigator.show(`/courses/${this.props.courseID}/assignments/${this.props.assignmentDetails.id}/edit`, { modal: true, modalPresentationStyle: 'formsheet' })
  }

  viewDueDateDetails = () => {
    this.props.navigator.show(`/courses/${this.props.courseID}/assignments/${this.props.assignmentDetails.id}/due_dates`)
  }

  viewAllSubmissions = () => {
    this.viewSubmissions()
  }

  viewSubmissions = (filterType: ?string) => {
    if (global.V02) {
      const { courseID, assignmentDetails } = this.props
      if (filterType) {
        this.props.navigator.show(`/courses/${courseID}/assignments/${assignmentDetails.id}/submissions`, { modal: false }, { filterType })
      } else {
        this.props.navigator.show(`/courses/${courseID}/assignments/${assignmentDetails.id}/submissions`)
      }
    }
  }
}

const style = StyleSheet.create({
  container: {
    flex: 1,
  },
  topContainer: {
    paddingTop: 14,
    paddingLeft: global.style.defaultPadding,
    paddingRight: global.style.defaultPadding,
    paddingBottom: 17,
  },
  loadingContainer: {
    flex: 1,
    flexDirection: 'column',
    justifyContent: 'center',
    alignItems: 'center',
  },
  pointsContainer: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 2,
  },
  publishedIcon: {
    marginLeft: 14,
  },
  submission: {
    marginRight: 40,
    marginTop: global.style.defaultPadding / 2,
  },
  points: {
    fontWeight: '500',
    color: colors.grey4,
  },
})

const assignementDetailsShape = PropTypes.shape({
  id: PropTypes.string,
  name: PropTypes.string.isRequired,
  description: PropTypes.string.isRequired,
  created_at: PropTypes.string,
  updated_at: PropTypes.string,
  due_at: PropTypes.string,
  lock_at: PropTypes.string,
  unlock_at: PropTypes.string,
  has_overrides: PropTypes.bool,
  course_id: PropTypes.string,
  published: PropTypes.bool,
  unpublishable: PropTypes.bool,
})

AssignmentDetails.propTypes = {
  assignmentDetails: assignementDetailsShape,
  pending: PropTypes.number,
  error: PropTypes.string,
}

let Refreshed = refresh(
  props => props.refreshAssignment(props.courseID, props.assignmentID),
  props => !props.assignmentDetails,
  props => Boolean(props.pending)
)(AssignmentDetails)
let Connected = connect(mapStateToProps, AssignmentActions)(Refreshed)
export default (Connected: Component<any, AssignmentDetailsProps, any>)
