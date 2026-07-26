import SwiftUI

struct BoardingPointView: View {
  let upcomingBuses: [UpcomingBus]

  var body: some View {
    LazyVStack(spacing: 12) {
      ForEach(upcomingBuses) { upcomingBus in
        UpcomingBusView(upcomingBus: upcomingBus)
      }
    }
  }
}
