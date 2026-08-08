import ComposableArchitecture

@Reducer
struct AddBusStopFeature {
  @ObservableState
  struct State: Equatable {
    var boardingPoint: BoardingPoint
    var availableStops: [BusStop]
    var query = ""
    var selectedStopID: BusStop.ID?
    var userLocation: UserLocation?
    var isLoadingLocation = false

    init(boardingPoint: BoardingPoint, availableStops: [BusStop] = BusStop.allKnown) {
      self.boardingPoint = boardingPoint
      self.availableStops = availableStops
    }
  }

  enum Action: Equatable {
    case task
    case locationResponse(Result<UserLocation, UserLocationError>)
    case queryChanged(String)
    case stopTapped(BusStop.ID)
    case selectButtonTapped
    case delegate(Delegate)

    enum Delegate: Equatable {
      case busStopSelected(BusStop)
    }
  }

  @Dependency(\.userLocationClient) var userLocationClient

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .task:
        guard !state.isLoadingLocation else { return .none }
        state.isLoadingLocation = true
        return .run { send in
          do {
            await send(.locationResponse(.success(try await userLocationClient.requestLocation())))
          } catch let error as UserLocationError {
            await send(.locationResponse(.failure(error)))
          } catch {
            await send(.locationResponse(.failure(.locationUnavailable)))
          }
        }

      case let .locationResponse(result):
        state.isLoadingLocation = false
        if case let .success(location) = result {
          state.userLocation = location
        }
        return .none

      case let .queryChanged(query):
        state.query = query
        return .none

      case let .stopTapped(stopID):
        state.selectedStopID = stopID
        return .none

      case .selectButtonTapped:
        guard let selectedStopID = state.selectedStopID,
              let stop = state.availableStops.first(where: { $0.id == selectedStopID })
        else {
          return .none
        }
        return .send(.delegate(.busStopSelected(stop)))

      case .delegate:
        return .none
      }
    }
  }
}
