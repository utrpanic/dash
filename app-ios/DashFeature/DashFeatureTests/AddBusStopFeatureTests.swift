import ComposableArchitecture
import DashDomain
import Testing
@testable import DashFeature

@MainActor
@Test func selectingBusStopLoadsRoutesForOnlyThatStop() async {
  let stop = BusStop.suwonStationExit7Outer
  let route = BusRoute.route13
  var initialState = AddBusStopFeature.State(boardingPoint: .suwonStation)
  initialState.availableStops = [stop, .suwonStationExit7Inner]

  let store = TestStore(initialState: initialState) {
    AddBusStopFeature()
  } withDependencies: {
    $0.busRouteRepository = BusRouteRepositoryStub { requestedStop in
      #expect(requestedStop == stop)
      return [route]
    }
  }

  await store.send(.stopTapped(stop.id)) {
    $0.selectedStopID = stop.id
    $0.loadingRouteStopIDs = [stop.id]
  }
  await store.receive(.routeOptionsResponse(stop.id, .success([route]))) {
    $0.routeOptionsByStopID[stop.id] = [route]
    $0.loadingRouteStopIDs = []
  }
}

@MainActor
@Test func receivingStopsDoesNotMarkEveryRouteAsLoading() async {
  let stops = [BusStop.suwonStationExit7Outer, .suwonStationExit7Inner]
  let store = TestStore(
    initialState: AddBusStopFeature.State(boardingPoint: .suwonStation)
  ) {
    AddBusStopFeature()
  }

  await store.send(.stopResponse(.success(stops))) {
    $0.availableStops = stops
  }
}

@MainActor
@Test func locationPermissionFailureExplainsSearchFallback() async {
  var initialState = AddBusStopFeature.State(boardingPoint: .suwonStation)
  initialState.isLoadingLocation = true
  let store = TestStore(initialState: initialState) {
    AddBusStopFeature()
  }

  await store.send(.locationResponse(.failure(.authorizationDenied))) {
    $0.isLoadingLocation = false
    $0.locationErrorMessage = "위치 권한이 없습니다. 정류장을 검색해주세요."
  }
}

@MainActor
@Test func unavailableLocationExplainsSearchFallback() async {
  var initialState = AddBusStopFeature.State(boardingPoint: .suwonStation)
  initialState.isLoadingLocation = true
  let store = TestStore(initialState: initialState) {
    AddBusStopFeature()
  }

  await store.send(.locationResponse(.failure(.locationUnavailable))) {
    $0.isLoadingLocation = false
    $0.locationErrorMessage = "현재 위치를 확인할 수 없습니다. 정류장을 검색해주세요."
  }
}
