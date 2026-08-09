import ComposableArchitecture
import DashDomain

@Reducer
struct BoardingPointsFeature {
  @ObservableState
  struct State: Equatable {
    var boardingPoints: [BoardingPoint]
    var deleteConfirmation: BoardingPoint?
    var selectedBoardingPointID: BoardingPoint.ID?

    init(
      boardingPoints: [BoardingPoint],
      selectedBoardingPointID: BoardingPoint.ID?
    ) {
      self.boardingPoints = boardingPoints
      self.deleteConfirmation = nil
      self.selectedBoardingPointID = selectedBoardingPointID
    }
  }
  
  enum Action: Equatable {
    case addButtonTapped
    case boardingPointTapped(BoardingPoint.ID)
    case boardingPointDeleted(BoardingPoint.ID)
    case deleteButtonTapped(BoardingPoint.ID)
    case deleteConfirmationCancelled
    case deleteConfirmationConfirmed
    case editButtonTapped(BoardingPoint.ID)
    case delegate(Delegate)

    enum Delegate: Equatable {
      case addBoardingPointRequested
      case boardingPointDeleted(BoardingPoint.ID)
      case boardingPointSelected(BoardingPoint)
      case editBoardingPointRequested(BoardingPoint)
    }
  }
  
  init() {}
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .addButtonTapped:
        return .send(.delegate(.addBoardingPointRequested))

      case let .boardingPointTapped(boardingPointID):
        guard let boardingPoint = state.boardingPoints.first(
          where: { $0.id == boardingPointID }
        ) else {
          return .none
        }
        return .send(.delegate(.boardingPointSelected(boardingPoint)))

      case let .boardingPointDeleted(boardingPointID):
        guard state.boardingPoints.count > 1 else {
          return .none
        }
        state.boardingPoints.removeAll { $0.id == boardingPointID }
        if state.selectedBoardingPointID == boardingPointID {
          state.selectedBoardingPointID = nil
        }
        return .none

      case let .deleteButtonTapped(boardingPointID):
        guard state.boardingPoints.count > 1,
              let boardingPoint = state.boardingPoints.first(
                where: { $0.id == boardingPointID }
              )
        else {
          return .none
        }
        state.deleteConfirmation = boardingPoint
        return .none

      case .deleteConfirmationCancelled:
        state.deleteConfirmation = nil
        return .none

      case .deleteConfirmationConfirmed:
        guard state.boardingPoints.count > 1,
              let boardingPoint = state.deleteConfirmation,
              state.boardingPoints.contains(where: { $0.id == boardingPoint.id })
        else {
          state.deleteConfirmation = nil
          return .none
        }
        state.deleteConfirmation = nil
        state.boardingPoints.removeAll { $0.id == boardingPoint.id }
        if state.selectedBoardingPointID == boardingPoint.id {
          state.selectedBoardingPointID = nil
        }
        return .send(.delegate(.boardingPointDeleted(boardingPoint.id)))

      case let .editButtonTapped(boardingPointID):
        guard let boardingPoint = state.boardingPoints.first(
          where: { $0.id == boardingPointID }
        ) else {
          return .none
        }
        return .send(.delegate(.editBoardingPointRequested(boardingPoint)))

      case .delegate:
        return .none
      }
    }
  }
}
