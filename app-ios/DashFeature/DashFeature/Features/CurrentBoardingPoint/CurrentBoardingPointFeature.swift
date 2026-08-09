import ComposableArchitecture
import DashDomain
import Foundation

@Reducer
struct CurrentBoardingPointFeature: Sendable {
  @ObservableState
  struct State: Equatable {
    enum BoardingPointSelection: Equatable, Hashable {
      case locating
      case locationPermissionDenied
      case locationUnavailable
      case noSelectedRoutes
      case selected(BoardingPoint.ID)
    }

    var boardingPoints: [BoardingPoint]
    var boardingPointSelection: BoardingPointSelection
    var configurationLoadErrorMessage: String?
    var hasLoadedConfiguration: Bool
    var hasRequestedInitialLocation: Bool
    var isLoadingConfiguration: Bool
    var isRequestingUserLocation: Bool
    var upcomingBuses: [UpcomingBus]
    var isLoadingUpcomingBuses: Bool
    var upcomingBusesErrorMessage: String?
    var lastUpdatedAt: Date?

    init() {
      self.boardingPoints = []
      self.boardingPointSelection = .locating
      self.configurationLoadErrorMessage = nil
      self.hasLoadedConfiguration = false
      self.hasRequestedInitialLocation = false
      self.isLoadingConfiguration = false
      self.isRequestingUserLocation = false
      self.upcomingBuses = []
      self.isLoadingUpcomingBuses = false
      self.upcomingBusesErrorMessage = nil
      self.lastUpdatedAt = nil
    }

    var selectedBoardingPointID: BoardingPoint.ID? {
      guard case let .selected(boardingPointID) = boardingPointSelection else {
        return nil
      }
      return boardingPointID
    }
    var boardingPointIsNotAvailable: Bool {
      selectedBoardingPointID == nil
    }
    var selectedBoardingPointHasSelectedRoutes: Bool {
      guard let selectedBoardingPointID,
            let boardingPoint = boardingPoints.first(
              where: { $0.id == selectedBoardingPointID }
            )
      else {
        return false
      }
      return boardingPoint.hasSelectedRoutes
    }
    var hasBoardingPointWithSelectedRoutes: Bool {
      boardingPoints.contains(where: \.hasSelectedRoutes)
    }
  }

  enum Action: Equatable {
    case editButtonTapped
    case listButtonTapped
    case configurationLoadResponse(ConfigurationLoadResponse)
    case loadUpcomingBuses
    case loadUpcomingBusesResponse(UpcomingBusesResponse)
    case locationButtonTapped
    case nextBoardingPointButtonTapped
    case refreshButtonTapped
    case boardingPointSelected(BoardingPoint.ID)
    case boardingPointDeleted(BoardingPoint.ID)
    case boardingPointUpdated(BoardingPoint)
    case setCurrentBoardingPoint(BoardingPoint)
    case task
    case userLocationResponse(UserLocationResponse)
    case delegate(Delegate)
    enum Delegate: Equatable {
      case boardingPointsRequested
      case editBoardingPointRequested(BoardingPoint)
    }
  }

  enum UserLocationResponse: Equatable {
    case success(UserLocation)
    case authorizationDenied
    case unavailable
  }

  enum ConfigurationLoadResponse: Equatable {
    case success(BoardingPointConfiguration)
    case failure(String)
  }

  enum UpcomingBusesResponse: Equatable {
    case success([UpcomingBus])
    case failure(String)
  }

  private enum CancelID: Hashable {
    case loadUpcomingBuses
  }

  @Dependency(\.gyeonggiBusArrivalAPIClient) var gyeonggiBusArrivalAPIClient
  @Dependency(\.boardingPointRepository) var boardingPointRepository
  @Dependency(\.date.now) var now
  @Dependency(\.seoulBusArrivalAPIClient) var seoulBusArrivalAPIClient
  @Dependency(\.userLocationClient) var userLocationClient
  
  init() {}

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .configurationLoadResponse(.success(configuration)):
        state.isLoadingConfiguration = false
        state.hasLoadedConfiguration = true
        state.configurationLoadErrorMessage = nil
        state.boardingPoints = configuration.boardingPoints

        guard !state.boardingPoints.isEmpty else {
          state.boardingPointSelection = .noSelectedRoutes
          return .none
        }

        if let currentBoardingPointID = configuration.currentBoardingPointID,
           state.boardingPoints.contains(where: { $0.id == currentBoardingPointID }) {
          state.boardingPointSelection = .selected(currentBoardingPointID)
          return .send(.loadUpcomingBuses)
        }

        state.boardingPointSelection = .locating
        return .send(.task)

      case let .configurationLoadResponse(.failure(message)):
        state.isLoadingConfiguration = false
        state.configurationLoadErrorMessage = message
        state.boardingPointSelection = .locationUnavailable
        return .none

      case .editButtonTapped:
        guard let selectedBoardingPointID = state.selectedBoardingPointID,
              let boardingPoint = state.boardingPoints.first(
                where: { $0.id == selectedBoardingPointID }
              )
        else {
          return .none
        }
        return .send(.delegate(.editBoardingPointRequested(boardingPoint)))
      case .listButtonTapped:
        return .send(.delegate(.boardingPointsRequested))
      case .loadUpcomingBuses:
        guard let selectedBoardingPointID = state.selectedBoardingPointID,
              let boardingPoint = state.boardingPoints.first(
                where: { $0.id == selectedBoardingPointID }
              )
        else {
          state.isLoadingUpcomingBuses = false
          return .none
        }

        guard state.selectedBoardingPointHasSelectedRoutes else {
          state.upcomingBuses = []
          state.isLoadingUpcomingBuses = false
          state.upcomingBusesErrorMessage = nil
          state.lastUpdatedAt = nil
          return .cancel(id: CancelID.loadUpcomingBuses)
        }

        state.isLoadingUpcomingBuses = true
        state.upcomingBusesErrorMessage = nil

        return .run { send in
          do {
            let upcomingBuses = try await self.fetchUpcomingBuses(boardingPoint: boardingPoint)
            await send(.loadUpcomingBusesResponse(.success(upcomingBuses)))
          } catch {
            await send(.loadUpcomingBusesResponse(.failure(String(describing: error))))
          }
        }
        .cancellable(id: CancelID.loadUpcomingBuses, cancelInFlight: true)

      case let .loadUpcomingBusesResponse(.success(upcomingBuses)):
        state.isLoadingUpcomingBuses = false
        state.upcomingBuses = upcomingBuses
        state.upcomingBusesErrorMessage = nil
        state.lastUpdatedAt = now
        return .none

      case let .loadUpcomingBusesResponse(.failure(message)):
        state.isLoadingUpcomingBuses = false
        state.upcomingBusesErrorMessage = message
        return .none

      case .locationButtonTapped:
        state.isRequestingUserLocation = true
        let requestLocation = userLocationClient.requestLocation
        return .run { send in
          do {
            await send(.userLocationResponse(.success(try await requestLocation())))
          } catch UserLocationError.authorizationDenied {
            await send(.userLocationResponse(.authorizationDenied))
          } catch {
            await send(.userLocationResponse(.unavailable))
          }
        }

      case .nextBoardingPointButtonTapped:
        guard !state.boardingPoints.isEmpty else {
          state.boardingPointSelection = .noSelectedRoutes
          state.upcomingBuses = []
          state.upcomingBusesErrorMessage = nil
          state.isLoadingUpcomingBuses = false
          state.lastUpdatedAt = nil
          return .none
        }

        let boardingPoints = state.boardingPoints
        let selectedIndex = state.selectedBoardingPointID
          .flatMap { selectedBoardingPointID in
            boardingPoints.firstIndex { $0.id == selectedBoardingPointID }
          } ?? -1

        let nextBoardingPoint = (1...boardingPoints.count)
          .lazy
          .map { offset in
            boardingPoints[(selectedIndex + offset) % boardingPoints.count]
          }
          .first(where: \.hasSelectedRoutes)
        guard let nextBoardingPoint else {
          state.boardingPointSelection = .noSelectedRoutes
          state.upcomingBuses = []
          state.upcomingBusesErrorMessage = nil
          state.isLoadingUpcomingBuses = false
          state.lastUpdatedAt = nil
          return .none
        }

        state.boardingPointSelection = .selected(nextBoardingPoint.id)
        state.lastUpdatedAt = nil
        return .send(.loadUpcomingBuses)

      case .refreshButtonTapped:
        return .send(.loadUpcomingBuses)

      case let .boardingPointSelected(boardingPointID):
        if boardingPointID != state.selectedBoardingPointID {
          state.lastUpdatedAt = nil
        }
        state.boardingPointSelection = .selected(boardingPointID)
        return .send(.loadUpcomingBuses)

      case let .boardingPointDeleted(boardingPointID):
        guard state.boardingPoints.count > 1,
              state.boardingPoints.contains(where: { $0.id == boardingPointID })
        else {
          return .none
        }
        state.boardingPoints.removeAll { $0.id == boardingPointID }
        guard state.selectedBoardingPointID == boardingPointID else {
          return .none
        }

        state.upcomingBuses = []
        state.isLoadingUpcomingBuses = false
        state.upcomingBusesErrorMessage = nil
        state.lastUpdatedAt = nil
        state.isRequestingUserLocation = false

        guard !state.boardingPoints.isEmpty else {
          state.boardingPointSelection = .locationUnavailable
          return .cancel(id: CancelID.loadUpcomingBuses)
        }

        state.boardingPointSelection = .locating
        state.hasRequestedInitialLocation = false
        return .concatenate(
          .cancel(id: CancelID.loadUpcomingBuses),
          .send(.task)
        )

      case let .boardingPointUpdated(boardingPoint):
        guard let index = state.boardingPoints.firstIndex(where: { $0.id == boardingPoint.id }) else {
          return .none
        }
        state.boardingPoints[index] = boardingPoint
        guard boardingPoint.id == state.selectedBoardingPointID else {
          return .none
        }
        state.lastUpdatedAt = nil
        return .send(.loadUpcomingBuses)

      case let .setCurrentBoardingPoint(boardingPoint):
        state.boardingPointSelection = .selected(boardingPoint.id)
        state.lastUpdatedAt = nil
        return .send(.loadUpcomingBuses)

      case .task:
        guard state.hasLoadedConfiguration else {
          guard !state.isLoadingConfiguration else {
            return .none
          }
          state.isLoadingConfiguration = true
          state.configurationLoadErrorMessage = nil
          let loadConfiguration = boardingPointRepository.loadConfiguration
          return .run { send in
            do {
              await send(.configurationLoadResponse(.success(try await loadConfiguration())))
            } catch {
              await send(
                .configurationLoadResponse(.failure(String(describing: error)))
              )
            }
          }
        }

        guard !state.hasRequestedInitialLocation else {
          return .none
        }

        state.hasRequestedInitialLocation = true
        state.isRequestingUserLocation = true
        state.isLoadingUpcomingBuses = true
        let requestLocation = userLocationClient.requestLocation
        return .run { send in
          do {
            await send(.userLocationResponse(.success(try await requestLocation())))
          } catch UserLocationError.authorizationDenied {
            await send(.userLocationResponse(.authorizationDenied))
          } catch {
            await send(.userLocationResponse(.unavailable))
          }
        }

      case let .userLocationResponse(.success(location)):
        state.isRequestingUserLocation = false
        guard let nearestBoardingPointID = Self.nearestBoardingPointID(
          to: location,
          in: state.boardingPoints
        ) else {
          state.boardingPointSelection = .noSelectedRoutes
          state.upcomingBuses = []
          state.upcomingBusesErrorMessage = nil
          state.isLoadingUpcomingBuses = false
          state.lastUpdatedAt = nil
          return .none
        }
        if nearestBoardingPointID != state.selectedBoardingPointID {
          state.lastUpdatedAt = nil
        }
        state.boardingPointSelection = .selected(nearestBoardingPointID)
        return .send(.loadUpcomingBuses)

      case .userLocationResponse(.authorizationDenied):
        state.isRequestingUserLocation = false
        if state.selectedBoardingPointID == nil {
          state.boardingPointSelection = .locationPermissionDenied
          state.isLoadingUpcomingBuses = false
        }
        return .none

      case .userLocationResponse(.unavailable):
        state.isRequestingUserLocation = false
        if state.selectedBoardingPointID == nil {
          state.boardingPointSelection = .locationUnavailable
          state.isLoadingUpcomingBuses = false
        }
        return .none
        
      case .delegate:
        return .none
      }
    }
  }
}

private extension CurrentBoardingPointFeature {
  static func nearestBoardingPointID(
    to location: UserLocation,
    in boardingPoints: [BoardingPoint]
  ) -> BoardingPoint.ID? {
    boardingPoints.filter(\.hasSelectedRoutes).map { boardingPoint in
      (
        id: boardingPoint.id,
        distance: distance(from: location, to: boardingPoint)
      )
    }
    .min { $0.distance < $1.distance }?
    .id
  }

  static func distance(from location: UserLocation, to boardingPoint: BoardingPoint) -> Double {
    guard let latitude = boardingPoint.centerLatitude,
          let longitude = boardingPoint.centerLongitude
    else {
      return .greatestFiniteMagnitude
    }
    let earthRadius = 6_371_000.0
    let latitudeDelta = radians(latitude - location.latitude)
    let longitudeDelta = radians(longitude - location.longitude)
    let sourceLatitude = radians(location.latitude)
    let destinationLatitude = radians(latitude)
    let haversine = sin(latitudeDelta / 2) * sin(latitudeDelta / 2)
      + cos(sourceLatitude) * cos(destinationLatitude)
      * sin(longitudeDelta / 2) * sin(longitudeDelta / 2)
    return earthRadius * 2 * atan2(sqrt(haversine), sqrt(1 - haversine))
  }

  static func radians(_ degrees: Double) -> Double {
    degrees * .pi / 180
  }

  func fetchUpcomingBuses(boardingPoint: BoardingPoint) async throws -> [UpcomingBus] {
    var upcomingBuses: [UpcomingBus] = []

    for (busStop, busRoutes) in boardingPoint.routes {
      let matchingArrivals: [BusArrival]
      switch busStop.id {
      case let .gyeonggi(stationID):
        let busRouteIDs = Set(busRoutes.map(\.id))
        let arrivals = try await gyeonggiBusArrivalAPIClient.fetchArrivals(stationID)
        matchingArrivals = arrivals.filter { busRouteIDs.contains($0.route.id) }

      case let .seoul(stationID, _):
        var arrivalsAtStop: [BusArrival] = []
        for busRoute in busRoutes {
          let arrivals = try await seoulBusArrivalAPIClient.fetchArrivalsByRoute(busRoute.id)
          arrivalsAtStop.append(contentsOf: arrivals.filter { $0.stationId == stationID })
        }
        matchingArrivals = arrivalsAtStop
      }

      for arrival in matchingArrivals {
        upcomingBuses.append(
          contentsOf: arrival.upcomingBuses(boardingPoint: boardingPoint, busStop: busStop)
        )
      }
    }

    return upcomingBuses.sortedByArrival
  }
}
