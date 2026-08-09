import ComposableArchitecture
import DashDomain

@Reducer
struct EditBoardingPointFeature {
  @ObservableState
  struct State: Equatable {
    enum DeleteConfirmation: Equatable {
      case boardingPoint
    }

    var boardingPoint: BoardingPoint
    var canDeleteBoardingPoint: Bool
    var name: String
    var routes: [BusStop: Set<BusRoute>]
    var deleteConfirmation: DeleteConfirmation?

    init(
      boardingPoint: BoardingPoint,
      canDeleteBoardingPoint: Bool = true
    ) {
      self.boardingPoint = boardingPoint
      self.canDeleteBoardingPoint = canDeleteBoardingPoint
      self.name = boardingPoint.name
      self.routes = boardingPoint.routes
      self.deleteConfirmation = nil
    }
  }
  
  enum Action: Equatable {
    case addBusStopButtonTapped
    case busStopAdded(BusStop)
    case busStopDeleteButtonTapped(BusStop.ID)
    case busStopRoutesChanged(busStopID: BusStop.ID, routes: Set<BusRoute>)
    case busStopTapped(BusStop.ID)
    case deleteBoardingPointButtonTapped
    case deleteConfirmationCancelled
    case deleteConfirmationConfirmed
    case nameChanged(String)
    case saveButtonTapped
    case delegate(Delegate)

    enum Delegate: Equatable {
      case addBusStopRequested(BoardingPoint)
      case selectBusRoutesRequested(BoardingPoint, BusStop)
      case deleteCompleted(BoardingPoint.ID)
      case saveCompleted(BoardingPoint)
    }
  }
  
  init() {}
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .addBusStopButtonTapped:
        return .send(
          .delegate(
            .addBusStopRequested(updatedBoardingPoint(from: state))
          )
        )

      case let .busStopAdded(busStop):
        guard !state.routes.keys.contains(busStop) else {
          return .none
        }
        state.routes[busStop] = []
        return .none

      case let .busStopDeleteButtonTapped(busStopID):
        guard let busStop = state.routes.keys.first(where: { $0.id == busStopID }) else {
          return .none
        }
        state.routes.removeValue(forKey: busStop)
        return .none

      case let .busStopRoutesChanged(busStopID, routes):
        guard let busStop = state.routes.keys.first(where: { $0.id == busStopID }) else {
          return .none
        }
        state.routes[busStop] = routes
        return .none

      case let .busStopTapped(busStopID):
        guard let busStop = state.routes.keys.first(where: { $0.id == busStopID }) else {
          return .none
        }
        return .send(
          .delegate(
            .selectBusRoutesRequested(
              updatedBoardingPoint(from: state),
              busStop
            )
          )
        )

      case .deleteBoardingPointButtonTapped:
        guard state.canDeleteBoardingPoint else {
          return .none
        }
        state.deleteConfirmation = .boardingPoint
        return .none

      case .deleteConfirmationCancelled:
        state.deleteConfirmation = nil
        return .none

      case .deleteConfirmationConfirmed:
        guard state.canDeleteBoardingPoint,
              state.deleteConfirmation != nil
        else {
          return .none
        }
        state.deleteConfirmation = nil
        return .send(.delegate(.deleteCompleted(state.boardingPoint.id)))

      case let .nameChanged(name):
        state.name = name
        return .none

      case .saveButtonTapped:
        let name = state.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
          return .none
        }
        return .send(
          .delegate(
            .saveCompleted(
              BoardingPoint(
                id: state.boardingPoint.id,
                name: name,
                routes: state.routes
              )
            )
          )
        )

      case .delegate:
        return .none
      }
    }
  }

  private func updatedBoardingPoint(from state: State) -> BoardingPoint {
    let name = state.name.trimmingCharacters(in: .whitespacesAndNewlines)
    return BoardingPoint(
      id: state.boardingPoint.id,
      name: name.isEmpty ? state.boardingPoint.name : name,
      routes: state.routes
    )
  }
}
