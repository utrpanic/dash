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
    var configurationSaveErrorMessage: String?
    var configurationSaveInFlight: BoardingPointConfiguration?
    var hasLoadedConfiguration: Bool
    var hasRequestedInitialLocation: Bool
    var isLoadingConfiguration: Bool
    var isRequestingUserLocation: Bool
    var upcomingBuses: [UpcomingBus]
    var isLoadingUpcomingBuses: Bool
    var upcomingBusesErrorMessage: String?
    var lastUpdatedAt: Date?
    var pendingConfigurationSave: BoardingPointConfiguration?
    var persistedBoardingPointID: BoardingPoint.ID?

    init() {
      self.boardingPoints = []
      self.boardingPointSelection = .locating
      self.configurationLoadErrorMessage = nil
      self.configurationSaveErrorMessage = nil
      self.configurationSaveInFlight = nil
      self.hasLoadedConfiguration = false
      self.hasRequestedInitialLocation = false
      self.isLoadingConfiguration = false
      self.isRequestingUserLocation = false
      self.upcomingBuses = []
      self.isLoadingUpcomingBuses = false
      self.upcomingBusesErrorMessage = nil
      self.lastUpdatedAt = nil
      self.pendingConfigurationSave = nil
      self.persistedBoardingPointID = nil
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
    case appBecameActive
    case listButtonTapped
    case configurationLoadResponse(ConfigurationLoadResponse)
    case configurationSaveErrorDismissed
    case configurationSaveResponse(ConfigurationSaveResponse)
    case loadUpcomingBuses
    case loadUpcomingBusesResponse(UpcomingBusesResponse)
    case locationButtonTapped
    case nextBoardingPointButtonTapped
    case refreshButtonTapped
    case retryConfigurationLoadButtonTapped
    case retryConfigurationSaveButtonTapped
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

  enum ConfigurationSaveResponse: Equatable {
    case success
    case failure
  }

  enum UpcomingBusesResponse: Equatable {
    case success([UpcomingBus])
    case failure(String)
  }

  private enum CancelID: Hashable {
    case loadUpcomingBuses
  }

  @Dependency(\.busArrivalRepository) var busArrivalRepository: any BusArrivalRepository
  @Dependency(\.boardingPointRepository) var boardingPointRepository
  @Dependency(\.date.now) var now
  @Dependency(\.userLocationClient) var userLocationClient
  
  init() {}

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .appBecameActive:
        guard state.hasLoadedConfiguration,
              state.selectedBoardingPointHasSelectedRoutes,
              !state.isLoadingUpcomingBuses
        else {
          return .none
        }
        return .send(.loadUpcomingBuses)

      case let .configurationLoadResponse(.success(configuration)):
        state.isLoadingConfiguration = false
        state.hasLoadedConfiguration = true
        state.configurationLoadErrorMessage = nil
        state.boardingPoints = configuration.boardingPoints
        state.persistedBoardingPointID = configuration.currentBoardingPointID.flatMap { id in
          state.boardingPoints.contains(where: { $0.id == id }) ? id : nil
        }

        guard !state.boardingPoints.isEmpty else {
          state.boardingPointSelection = .noSelectedRoutes
          return .none
        }

        state.boardingPointSelection = .locating
        return .send(.task)

      case .configurationLoadResponse(.failure):
        state.isLoadingConfiguration = false
        state.configurationLoadErrorMessage = "탑승 지점 정보를 불러오지 못했습니다."
        state.boardingPointSelection = .locationUnavailable
        return .none

      case .configurationSaveErrorDismissed:
        state.configurationSaveErrorMessage = nil
        return .none

      case .configurationSaveResponse(.success):
        state.persistedBoardingPointID = state.configurationSaveInFlight?.currentBoardingPointID
        state.configurationSaveInFlight = nil
        return startPendingConfigurationSave(state: &state)

      case .configurationSaveResponse(.failure):
        state.configurationSaveInFlight = nil
        state.pendingConfigurationSave = configuration(from: state)
        state.configurationSaveErrorMessage = "변경사항을 저장하지 못했습니다. 다시 시도해주세요."
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

      case .loadUpcomingBusesResponse(.failure):
        state.isLoadingUpcomingBuses = false
        state.upcomingBusesErrorMessage = "도착 정보를 불러오지 못했습니다."
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
        return .merge(
          enqueueConfigurationSave(state: &state),
          .send(.loadUpcomingBuses)
        )

      case .refreshButtonTapped:
        return .send(.loadUpcomingBuses)

      case .retryConfigurationLoadButtonTapped:
        state.configurationLoadErrorMessage = nil
        return .send(.task)

      case .retryConfigurationSaveButtonTapped:
        state.configurationSaveErrorMessage = nil
        if state.pendingConfigurationSave == nil {
          state.pendingConfigurationSave = configuration(from: state)
        }
        return startPendingConfigurationSave(state: &state)

      case let .boardingPointSelected(boardingPointID):
        if boardingPointID != state.selectedBoardingPointID {
          state.lastUpdatedAt = nil
        }
        state.boardingPointSelection = .selected(boardingPointID)
        return .merge(
          enqueueConfigurationSave(state: &state),
          .send(.loadUpcomingBuses)
        )

      case let .boardingPointDeleted(boardingPointID):
        guard state.boardingPoints.count > 1,
              state.boardingPoints.contains(where: { $0.id == boardingPointID })
        else {
          return .none
        }
        let deletedSelectedBoardingPoint = state.selectedBoardingPointID == boardingPointID
        state.boardingPoints.removeAll { $0.id == boardingPointID }
        if state.persistedBoardingPointID == boardingPointID {
          state.persistedBoardingPointID = nil
        }
        guard deletedSelectedBoardingPoint else {
          return enqueueConfigurationSave(state: &state)
        }

        state.upcomingBuses = []
        state.isLoadingUpcomingBuses = false
        state.upcomingBusesErrorMessage = nil
        state.lastUpdatedAt = nil
        state.isRequestingUserLocation = false

        guard !state.boardingPoints.isEmpty else {
          state.boardingPointSelection = .locationUnavailable
          return .merge(
            enqueueConfigurationSave(state: &state),
            .cancel(id: CancelID.loadUpcomingBuses)
          )
        }

        state.boardingPointSelection = .locating
        state.hasRequestedInitialLocation = false
        return .merge(
          enqueueConfigurationSave(state: &state),
          .concatenate(
            .cancel(id: CancelID.loadUpcomingBuses),
            .send(.task)
          )
        )

      case let .boardingPointUpdated(boardingPoint):
        if let index = state.boardingPoints.firstIndex(where: { $0.id == boardingPoint.id }) {
          state.boardingPoints[index] = boardingPoint
        } else {
          state.boardingPoints.append(boardingPoint)
        }
        let saveEffect = enqueueConfigurationSave(state: &state)
        guard boardingPoint.id == state.selectedBoardingPointID else {
          return saveEffect
        }
        state.lastUpdatedAt = nil
        return .merge(
          saveEffect,
          .send(.loadUpcomingBuses)
        )

      case let .setCurrentBoardingPoint(boardingPoint):
        state.boardingPointSelection = .selected(boardingPoint.id)
        state.lastUpdatedAt = nil
        return .merge(
          enqueueConfigurationSave(state: &state),
          .send(.loadUpcomingBuses)
        )

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
        return .merge(
          enqueueConfigurationSave(state: &state),
          .send(.loadUpcomingBuses)
        )

      case .userLocationResponse(.authorizationDenied):
        return recoverFromLocationFailure(
          state: &state,
          unavailableSelection: .locationPermissionDenied
        )

      case .userLocationResponse(.unavailable):
        return recoverFromLocationFailure(
          state: &state,
          unavailableSelection: .locationUnavailable
        )
        
      case .delegate:
        return .none
      }
    }
  }
}

private extension CurrentBoardingPointFeature {
  func recoverFromLocationFailure(
    state: inout State,
    unavailableSelection: State.BoardingPointSelection
  ) -> Effect<Action> {
    state.isRequestingUserLocation = false
    guard state.selectedBoardingPointID == nil else {
      return .none
    }
    guard let persistedBoardingPointID = state.persistedBoardingPointID,
          state.boardingPoints.contains(where: { $0.id == persistedBoardingPointID })
    else {
      state.boardingPointSelection = unavailableSelection
      state.isLoadingUpcomingBuses = false
      return .none
    }
    state.boardingPointSelection = .selected(persistedBoardingPointID)
    state.lastUpdatedAt = nil
    return .send(.loadUpcomingBuses)
  }

  func configuration(from state: State) -> BoardingPointConfiguration {
    BoardingPointConfiguration(
      boardingPoints: state.boardingPoints,
      currentBoardingPointID: state.selectedBoardingPointID ?? state.persistedBoardingPointID
    )
  }

  func enqueueConfigurationSave(state: inout State) -> Effect<Action> {
    state.pendingConfigurationSave = configuration(from: state)
    guard state.configurationSaveInFlight == nil,
          state.configurationSaveErrorMessage == nil
    else {
      return .none
    }
    return startPendingConfigurationSave(state: &state)
  }

  func startPendingConfigurationSave(state: inout State) -> Effect<Action> {
    guard state.configurationSaveInFlight == nil,
          let configuration = state.pendingConfigurationSave
    else {
      return .none
    }

    state.pendingConfigurationSave = nil
    state.configurationSaveInFlight = configuration
    let saveConfiguration = boardingPointRepository.saveConfiguration
    return .run { send in
      do {
        try await saveConfiguration(configuration)
        await send(.configurationSaveResponse(.success))
      } catch {
        await send(.configurationSaveResponse(.failure))
      }
    }
  }

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
    let selectedStops = boardingPoint.routes.filter { !$0.value.isEmpty }
    let results = await withTaskGroup(of: StopFetchResult.self) { group in
      for (busStop, busRoutes) in selectedStops {
        group.addTask { [busArrivalRepository] in
          do {
            let arrivals = try await busArrivalRepository.fetchArrivals(
              at: busStop,
              for: busRoutes
            )
            return .success(
              arrivals.flatMap {
                $0.upcomingBuses(boardingPoint: boardingPoint, busStop: busStop)
              }
            )
          } catch {
            return .failure
          }
        }
      }

      var results: [StopFetchResult] = []
      for await result in group {
        results.append(result)
      }
      return results
    }

    guard results.contains(where: \.isSuccess) else {
      throw UpcomingBusFetchError.unavailable
    }
    return results.flatMap(\.upcomingBuses).sortedByArrival
  }
}

private enum UpcomingBusFetchError: Error {
  case unavailable
}

private enum StopFetchResult: Sendable {
  case success([UpcomingBus])
  case failure

  var isSuccess: Bool {
    if case .success = self { return true }
    return false
  }

  var upcomingBuses: [UpcomingBus] {
    if case let .success(upcomingBuses) = self { return upcomingBuses }
    return []
  }
}
