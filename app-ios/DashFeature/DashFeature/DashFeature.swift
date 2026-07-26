import ComposableArchitecture

@Reducer
struct DashFeature {
  @ObservableState
  struct State: Equatable {
    var currentBoardingPoint: CurrentBoardingPointFeature.State
    var path = StackState<Path.State>()

    init() {
      self.currentBoardingPoint = CurrentBoardingPointFeature.State()
    }
  }

  enum Action {
    case currentBoardingPoint(CurrentBoardingPointFeature.Action)
    case path(StackActionOf<Path>)
  }

  @Reducer
  enum Path {
    case boardingPoints(BoardingPointsFeature)
    case editBoardingPoint(EditBoardingPointFeature)
  }

  init() {}

  var body: some ReducerOf<Self> {
    Scope(
      state: \.currentBoardingPoint,
      action: \.currentBoardingPoint
    ) {
      CurrentBoardingPointFeature()
    }
    
    Reduce { state, action in
      switch action {
      case let .currentBoardingPoint(.delegate(delegate)):
        switch delegate {
        case .boardingPointsRequested:
          state.path.append(
            .boardingPoints(
              BoardingPointsFeature.State(
                boardingPoints: state.currentBoardingPoint.boardingPoints,
                selectedBoardingPointID: state.currentBoardingPoint.selectedBoardingPointID
              )
            )
          )
          return .none
        case let .editBoardingPointRequested(boardingPoint):
          state.path.append(
            .editBoardingPoint(
              EditBoardingPointFeature.State(
                boardingPoint: boardingPoint
              )
            )
          )
          return .none
        }
        
      case .currentBoardingPoint:
        return .none
      
      case let .path(
        .element(
          id: _,
          action: .boardingPoints(
            .delegate(.editBoardingPointRequested(boardingPoint))
          )
        )
      ):
        state.path.append(
          .editBoardingPoint(
            EditBoardingPointFeature.State(
              boardingPoint: boardingPoint
            )
          )
        )
        return .none
        
      case let .path(
        .element(
          id: _,
          action: .boardingPoints(
            .delegate(.boardingPointSelected(boardingPoint))
          )
        )
      ):
        state.path.removeAll()
        return .send(
          .currentBoardingPoint(
            .setCurrentBoardingPoint(boardingPoint)
          )
        )
        
      case let .path(
        .element(
          id: _,
          action: .editBoardingPoint(
            .delegate(.saveCompleted(boardingPoint))
          )
        )
      ):
        state.path.removeLast()
        return .send(
          .currentBoardingPoint(
            .boardingPointUpdated(boardingPoint)
          )
        )
        
      case .path:
        return .none
      }
    }
    .forEach(\.path, action: \.path)
  }
}

extension DashFeature.Path.State: Equatable {}
