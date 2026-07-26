import ComposableArchitecture

@Reducer
struct BoardingPointsFeature {
  @ObservableState
  struct State: Equatable {
    var boardingPoints: [BoardingPoint]
    var selectedBoardingPointID: BoardingPoint.ID?

    init(
      boardingPoints: [BoardingPoint],
      selectedBoardingPointID: BoardingPoint.ID?
    ) {
      self.boardingPoints = boardingPoints
      self.selectedBoardingPointID = selectedBoardingPointID
    }
  }
  
  enum Action: Equatable {
    case addButtonTapped
    case boardingPointTapped(BoardingPoint.ID)
    case editButtonTapped(BoardingPoint.ID)
    case delegate(Delegate)

    enum Delegate: Equatable {
      case addBoardingPointRequested
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
