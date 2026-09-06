import ComposableArchitecture
import SwiftUI

public struct DashFeatureView: View {
  @Bindable private var store: StoreOf<DashFeature>

  public init(
    boardingPointRepository: BoardingPointRepositoryClient,
    busArrivalRepository: any BusArrivalRepository,
    busRouteRepository: any BusRouteRepository,
    busStopRepository: any BusStopRepository
  ) {
    self.store = Store(
      initialState: DashFeature.State()
    ) {
      DashFeature()
    } withDependencies: {
      $0.boardingPointRepository = boardingPointRepository
      $0.busArrivalRepository = busArrivalRepository
      $0.busRouteRepository = busRouteRepository
      $0.busStopRepository = busStopRepository
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
    .alert(
      "변경사항을 저장하지 못했습니다",
      isPresented: Binding(
        get: { store.currentBoardingPoint.configurationSaveErrorMessage != nil },
        set: { isPresented in
          if !isPresented {
            store.send(.currentBoardingPoint(.configurationSaveErrorDismissed))
          }
        }
      )
    ) {
      Button("나중에", role: .cancel) {
        store.send(.currentBoardingPoint(.configurationSaveErrorDismissed))
      }
      Button("다시 시도") {
        store.send(.currentBoardingPoint(.retryConfigurationSaveButtonTapped))
      }
    } message: {
      Text(store.currentBoardingPoint.configurationSaveErrorMessage ?? "")
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
    busRouteRepository: EmptyBusRouteRepository(),
    busStopRepository: EmptyBusStopRepository()
  )
}
