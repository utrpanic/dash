import SwiftUI
import DashDomain

struct UpcomingBusView: View {
  let upcomingBus: UpcomingBus

  private var minutesRemaining: Int {
    max(0, Int(ceil(upcomingBus.timeIntervalUntilArrival / 60)))
  }

  private var arrivalTime: Date {
    .now.addingTimeInterval(upcomingBus.timeIntervalUntilArrival)
  }

  var body: some View {
    DashStatusCard {
      HStack(alignment: .center, spacing: r.dimen.spacingMedium) {
        VStack(alignment: .leading, spacing: r.dimen.spacingSmall) {
          Text(upcomingBus.busRoute.number)
            .font(r.font.arrivalRoute)
            .foregroundStyle(r.color.textPrimary)

          Label(
            arrivalTime.formatted(date: .omitted, time: .shortened),
            systemImage: "clock"
          )
          .font(r.font.body)
          .fontWeight(.medium)
          .foregroundStyle(r.color.textSecondary)
          .labelStyle(.titleAndIcon)
        }

        Spacer(minLength: r.dimen.spacingMedium)

        HStack(alignment: .lastTextBaseline, spacing: r.dimen.spacingXXSmall) {
          Text("\(minutesRemaining)")
            .font(r.font.arrivalValue)
            .fontWeight(timeWeight)
            .foregroundStyle(r.color.brandMint)
            .monospacedDigit()

          Text("분")
            .font(r.font.screenTitle)
            .fontWeight(timeWeight)
            .foregroundStyle(r.color.brandMint)
            .padding(.bottom, r.dimen.spacingXXSmall)
        }
        .frame(minWidth: r.dimen.standardRowMinHeight)
      }
      .padding(.horizontal, r.dimen.spacingLarge)
      .padding(.vertical, r.dimen.spacingLarge)
    }
  }

  private var timeWeight: Font.Weight {
    switch minutesRemaining {
    case ...3:
      return .bold
    case 4...10:
      return .regular
    default:
      return .light
    }
  }
}
