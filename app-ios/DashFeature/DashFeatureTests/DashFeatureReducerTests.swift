import ComposableArchitecture
import Foundation
import Testing
@testable import DashFeature

private let testNow = Date(timeIntervalSinceReferenceDate: 0)

@Test func boardingPointsIncludeRequestedSeoulBusRoutes() {
  #expect(
    BoardingPoint.yeongdeungpoStation.routes[.yeongdeungpoStation]?.isSuperset(
      of: [.route88, .route160, .route600, .route662, .route8671]
    ) == true
  )
  #expect(
    BoardingPoint.theHyundaiSeoul.routes[.theHyundaiSeoul]?.isSuperset(
      of: [.route88, .route662, .route6628]
    ) == true
  )
}

@Test func boardingPointUsesCenterOfBusStops() {
  let boardingPoint = BoardingPoint(
    id: "test",
    name: "Test",
    routes: [
      BusStop(id: .gyeonggi(stopID: 1), name: "First", latitude: 37, longitude: 126): [],
      BusStop(id: .gyeonggi(stopID: 2), name: "Second", latitude: 39, longitude: 128): [],
    ]
  )

  #expect(boardingPoint.centerLatitude == 38)
  #expect(boardingPoint.centerLongitude == 127)
}

@MainActor
@Test func reducerLoadsUpcomingBusesFromSeoulArrivalAPI() async {
  let expectedUpcomingBus = UpcomingBus(
    boardingPoint: .theHyundaiSeoul,
    busStop: .theHyundaiSeoul,
    busRoute: .route662,
    timeIntervalUntilArrival: 4 * 60
  )
  var initialState = CurrentBoardingPointFeature.State()
  initialState.boardingPoints = [.theHyundaiSeoul]
  initialState.boardingPointSelection = .selected(BoardingPoint.theHyundaiSeoul.id)

  let store = TestStore(initialState: initialState) {
    CurrentBoardingPointFeature()
  } withDependencies: {
    $0.date.now = testNow
    $0.busArrivalRepository = BusArrivalRepositoryStub { busStop, routes in
      guard busStop == .theHyundaiSeoul, routes == [.route662] else { return [] }
      return [
        BusArrival(
          stopID: BusStop.theHyundaiSeoul.id.stopID,
          route: .route662,
          stopOrder: 29,
          operationState: "",
          firstPrediction: BusArrivalPrediction(
            minutes: 4,
            seconds: 4 * 60,
            locationNumber: nil,
            plateNumber: "",
            remainingSeatCount: nil,
            stateCode: nil,
            stopName: "",
            vehicleId: nil
          ),
          secondPrediction: nil
        ),
      ]
    }
  }

  await store.send(.loadUpcomingBuses) {
    $0.isLoadingUpcomingBuses = true
    $0.upcomingBusesErrorMessage = nil
  }
  await store.receive(.loadUpcomingBusesResponse(.success([expectedUpcomingBus]))) {
    $0.isLoadingUpcomingBuses = false
    $0.upcomingBuses = [expectedUpcomingBus]
    $0.upcomingBusesErrorMessage = nil
    $0.lastUpdatedAt = testNow
  }
}

@MainActor
@Test func returningToActiveRefreshesStaleUpcomingBuses() async {
  let staleUpdate = testNow.addingTimeInterval(-60)
  var initialState = CurrentBoardingPointFeature.State()
  initialState.boardingPoints = [.theHyundaiSeoul]
  initialState.boardingPointSelection = .selected(BoardingPoint.theHyundaiSeoul.id)
  initialState.hasLoadedConfiguration = true
  initialState.lastUpdatedAt = staleUpdate

  let store = TestStore(initialState: initialState) {
    CurrentBoardingPointFeature()
  } withDependencies: {
    $0.date.now = testNow
  }

  await store.send(.appBecameActive)
  await store.receive(.loadUpcomingBuses) {
    $0.isLoadingUpcomingBuses = true
    $0.upcomingBusesErrorMessage = nil
  }
  await store.receive(.loadUpcomingBusesResponse(.success([]))) {
    $0.isLoadingUpcomingBuses = false
    $0.lastUpdatedAt = testNow
  }
}

@MainActor
@Test func returningToActiveKeepsFreshUpcomingBuses() async {
  var initialState = CurrentBoardingPointFeature.State()
  initialState.boardingPoints = [.theHyundaiSeoul]
  initialState.boardingPointSelection = .selected(BoardingPoint.theHyundaiSeoul.id)
  initialState.hasLoadedConfiguration = true
  initialState.lastUpdatedAt = testNow.addingTimeInterval(-59)

  let store = TestStore(initialState: initialState) {
    CurrentBoardingPointFeature()
  } withDependencies: {
    $0.date.now = testNow
  }

  await store.send(.appBecameActive)
}
