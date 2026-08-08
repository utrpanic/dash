import SwiftUI

struct BoardingPointView: View {
  let upcomingBuses: [UpcomingBus]

  var body: some View {
    LazyVStack(spacing: r.dimen.spacingSmall) {
      ForEach(upcomingBuses) { upcomingBus in
        UpcomingBusView(upcomingBus: upcomingBus)
      }
    }
  }
}
