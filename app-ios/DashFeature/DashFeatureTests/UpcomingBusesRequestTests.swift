import ComposableArchitecture
import Foundation
import Testing
@testable import DashFeature

@MainActor
@Suite struct UpcomingBusesRequestTests {
  @Test(arguments: [false, true])
  func rejectsOldRequestForSamePoint(failure: Bool) async {
    var state = loadingState(point: .theHyundaiSeoul)
    state.upcomingBusesRequestID = 3
    let store = TestStore(initialState: state) { CurrentBoardingPointFeature() }

    // The first A request must remain stale after A → B → A, including errors.
    await store.send(.loadUpcomingBusesResponse(
      requestID: 1, boardingPoint: .theHyundaiSeoul,
      failure ? .failure("old request") : .success([])
    ))
  }

  @Test(arguments: [false, true])
  func rejectsResponseForDifferentPoint(failure: Bool) async {
    let store = TestStore(initialState: loadingState(point: .suwonStation)) {
      CurrentBoardingPointFeature()
    }
    await store.send(.loadUpcomingBusesResponse(
      requestID: 1, boardingPoint: .theHyundaiSeoul,
      failure ? .failure("old point") : .success([])
    ))
  }

  @Test func rejectsResponseForRoutesBeforeEditing() async {
    let original = BoardingPoint.theHyundaiSeoul
    let edited = BoardingPoint(id: original.id, name: original.name, routes: [.theHyundaiSeoul: [.route662]])
    let store = TestStore(initialState: loadingState(point: edited)) {
      CurrentBoardingPointFeature()
    }
    await store.send(.loadUpcomingBusesResponse(
      requestID: 1, boardingPoint: original, .success([])
    ))
  }

  @Test func rejectsResponseAfterSelectionIsRemoved() async {
    var state = loadingState(point: .theHyundaiSeoul)
    state.boardingPointSelection = .noSelectedRoutes
    state.isLoadingUpcomingBuses = false
    let store = TestStore(initialState: state) { CurrentBoardingPointFeature() }
    await store.send(.loadUpcomingBusesResponse(
      requestID: 1, boardingPoint: .theHyundaiSeoul, .failure("old point")
    ))
  }

  @Test func currentFailureStopsLoading() async {
    let store = TestStore(initialState: loadingState(point: .theHyundaiSeoul)) {
      CurrentBoardingPointFeature()
    }
    await store.send(.loadUpcomingBusesResponse(
      requestID: 1, boardingPoint: .theHyundaiSeoul, .failure("current failure")
    )) {
      $0.isLoadingUpcomingBuses = false
      $0.upcomingBusesErrorMessage = "도착 정보를 불러오지 못했습니다."
    }
  }

  @Test func switchingClearsOldListAndInvalidatesRequestBeforeNextLoad() {
    let reducer = CurrentBoardingPointFeature()
    var state = loadingState(point: .theHyundaiSeoul)
    state.boardingPoints.append(.suwonStation)
    state.upcomingBuses = [UpcomingBus(
      boardingPoint: .theHyundaiSeoul, busStop: .theHyundaiSeoul,
      busRoute: .route662, timeIntervalUntilArrival: 120
    )]
    state.lastUpdatedAt = Date(timeIntervalSinceReferenceDate: 1)
    _ = reducer.reduce(into: &state, action: .boardingPointSelected(BoardingPoint.suwonStation.id))
    #expect(state.upcomingBuses.isEmpty)
    #expect(state.lastUpdatedAt == nil)
    #expect(state.upcomingBusesRequestID == 2)

    _ = reducer.reduce(into: &state, action: .boardingPointSelected(BoardingPoint.theHyundaiSeoul.id))
    let expected = state
    _ = reducer.reduce(into: &state, action: .loadUpcomingBusesResponse(
      requestID: 1, boardingPoint: .theHyundaiSeoul, .success([])
    ))
    #expect(state == expected)
  }

  private func loadingState(point: BoardingPoint) -> CurrentBoardingPointFeature.State {
    var state = CurrentBoardingPointFeature.State()
    state.boardingPoints = [point]
    state.boardingPointSelection = .selected(point.id)
    state.upcomingBusesRequestID = 1
    state.isLoadingUpcomingBuses = true
    return state
  }
}
