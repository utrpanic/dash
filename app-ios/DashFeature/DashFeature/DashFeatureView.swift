import ComposableArchitecture
import SwiftUI

public struct DashFeatureView: View {
  @Bindable private var store: StoreOf<DashFeature>

  public init() {
    self.store = Store(initialState: DashFeature.State()) {
      DashFeature()
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
      }
    }
  }
}

#Preview {
  DashFeatureView()
}
