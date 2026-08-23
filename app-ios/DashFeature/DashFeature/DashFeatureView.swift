import ComposableArchitecture
import SwiftUI

public struct DashFeatureView: View {
  @Bindable private var store: StoreOf<DashFeature>

  public init(
    boardingPointRepository: BoardingPointRepositoryClient,
    busArrivalRepository: any BusArrivalRepository,
    busRouteRepository: any BusRouteRepository
  ) {
    self.store = Store(
      initialState: DashFeature.State()
    ) {
      DashFeature()
    } withDependencies: {
      $0.boardingPointRepository = boardingPointRepository
      $0.busArrivalRepository = busArrivalRepository
      $0.busRouteRepository = busRouteRepository
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
          boardingPoints: [
            .suwonStation,
            .homaesilSsangyongApartment,
            .yeongdeungpoStation,
            .theHyundaiSeoul,
          ],
          currentBoardingPointID: BoardingPoint.suwonStation.id
        )
      },
      save: { _ in }
    ),
    busArrivalRepository: EmptyBusArrivalRepository(),
    busRouteRepository: EmptyBusRouteRepository()
  )
}
