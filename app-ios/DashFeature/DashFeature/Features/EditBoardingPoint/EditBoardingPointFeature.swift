import ComposableArchitecture

@Reducer
struct EditBoardingPointFeature {
  @ObservableState
  struct State: Equatable {
    enum DeleteConfirmation: Equatable {
      case boardingPoint
    }

    var boardingPoint: BoardingPoint
    var name: String
    var routes: [BusStop: Set<BusRoute>]
    var busStopOrder: [BusStop.ID]
    var deleteConfirmation: DeleteConfirmation?

    init(boardingPoint: BoardingPoint) {
      self.boardingPoint = boardingPoint
      self.name = boardingPoint.name
      self.routes = boardingPoint.routes
      self.busStopOrder = boardingPoint.busStopOrder
      self.deleteConfirmation = nil
    }
  }
  
  enum Action: Equatable {
    case addBusStopButtonTapped
    case busStopMoved(sourceID: BusStop.ID, targetID: BusStop.ID)
    case busStopTapped(BusStop.ID)
    case deleteBoardingPointButtonTapped
    case deleteConfirmationCancelled
    case deleteConfirmationConfirmed
    case nameChanged(String)
    case saveButtonTapped
    case delegate(Delegate)

    enum Delegate: Equatable {
      case addBusStopRequested(BoardingPoint)
      case busRouteSelectionRequested(BoardingPoint, BusStop)
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

      case let .busStopMoved(sourceID, targetID):
        guard sourceID != targetID,
              let sourceIndex = state.busStopOrder.firstIndex(of: sourceID),
              let targetIndex = state.busStopOrder.firstIndex(of: targetID)
        else {
          return .none
        }
        state.busStopOrder.remove(at: sourceIndex)
        let insertionIndex = sourceIndex < targetIndex ? targetIndex - 1 : targetIndex
        state.busStopOrder.insert(sourceID, at: insertionIndex)
        return .none

      case let .busStopTapped(busStopID):
        guard let busStop = state.routes.keys.first(where: { $0.id == busStopID }) else {
          return .none
        }
        return .send(
          .delegate(
            .busRouteSelectionRequested(
              updatedBoardingPoint(from: state),
              busStop
            )
          )
        )

      case .deleteBoardingPointButtonTapped:
        state.deleteConfirmation = .boardingPoint
        return .none

      case .deleteConfirmationCancelled:
        state.deleteConfirmation = nil
        return .none

      case .deleteConfirmationConfirmed:
        guard state.deleteConfirmation != nil else {
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
                routes: state.routes,
                busStopOrder: state.busStopOrder
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
      routes: state.routes,
      busStopOrder: state.busStopOrder
    )
  }
}
