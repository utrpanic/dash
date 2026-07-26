import ComposableArchitecture

@Reducer
struct EditBoardingPointFeature {
  @ObservableState
  struct State: Equatable {
    var boardingPoint: BoardingPoint

    init(boardingPoint: BoardingPoint) {
      self.boardingPoint = boardingPoint
    }
  }
  
  enum Action: Equatable {
    case delegate(Delegate)

    enum Delegate: Equatable {
      case saveCompleted(BoardingPoint)
    }
  }
  
  init() {}
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .delegate:
        .none
      }
    }
  }
}
