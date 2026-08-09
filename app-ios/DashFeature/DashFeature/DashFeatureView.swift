import ComposableArchitecture
import SwiftUI

public struct DashFeatureView: View {
  @Bindable private var store: StoreOf<DashFeature>

  public init(
    boardingPointRepository: BoardingPointRepositoryClient,
    gyeonggiBusArrivalAPIClient: GyeonggiBusArrivalAPIClient,
    gyeonggiBusStationAPIClient: GyeonggiBusStationAPIClient,
    seoulBusArrivalAPIClient: SeoulBusArrivalAPIClient,
    seoulBusStationAPIClient: SeoulBusStationAPIClient
  ) {
    self.store = Store(
      initialState: DashFeature.State()
    ) {
      DashFeature()
    } withDependencies: {
      $0.boardingPointRepository = boardingPointRepository
      $0.gyeonggiBusArrivalAPIClient = gyeonggiBusArrivalAPIClient
      $0.gyeonggiBusStationAPIClient = gyeonggiBusStationAPIClient
      $0.seoulBusArrivalAPIClient = seoulBusArrivalAPIClient
      $0.seoulBusStationAPIClient = seoulBusStationAPIClient
    }
  }

  public var body: some View {
    NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
      CurrentBoardingPointView(
        store: store.scope(
          state: \.currentBoardingPoint,
          action: \.currentBoardingPoint
        )
      )
    } destination: { store in
      switch store.case {
      case let .boardingPoints(store):
        BoardingPointsView(store: store)
      case let .editBoardingPoint(store):
        EditBoardingPointView(store: store)
      case let .addBusStop(store):
        AddBusStopView(store: store)
      case let .selectBusRoutes(store):
        SelectBusRoutesView(store: store)
      }
    }
  }
}

#Preview {
  DashFeatureView(
    boardingPointRepository: BoardingPointRepositoryClient(
      load: {
        BoardingPointConfiguration(
          boardingPoints: .mock,
          currentBoardingPointID: BoardingPoint.suwonStation.id
        )
      },
      save: { _ in }
    ),
    gyeonggiBusArrivalAPIClient: .testValue,
    gyeonggiBusStationAPIClient: .testValue,
    seoulBusArrivalAPIClient: .testValue,
    seoulBusStationAPIClient: .testValue
  )
}
