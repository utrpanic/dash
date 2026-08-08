import ComposableArchitecture
import Foundation
import SwiftUI

struct EditBoardingPointView: View {
  let store: StoreOf<EditBoardingPointFeature>

  var body: some View {
    ZStack {
      r.color.background
        .ignoresSafeArea()

      VStack(spacing: 0) {
        DashListDivider()
          .padding(.horizontal, r.dimen.spacingMedium)

        GeometryReader { proxy in
          ScrollView {
            VStack(alignment: .leading, spacing: r.dimen.spacingLarge) {
              nameSection
              busStopsSection

              Spacer(minLength: r.dimen.primaryButtonHeight)

              deleteBoardingPointButton
            }
            .padding(.horizontal, r.dimen.spacingMedium)
            .padding(.vertical, r.dimen.spacingLarge)
            .frame(minHeight: proxy.size.height, alignment: .top)
          }
          .scrollIndicators(.hidden)
          .scrollDismissesKeyboard(.interactively)
        }
      }
    }
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .principal) {
        Text("탑승 지점 편집")
          .font(r.font.screenTitle)
          .foregroundStyle(r.color.textPrimary)
      }
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          store.send(.saveButtonTapped)
        } label: {
          Text("저장")
            .font(r.font.navigationAction)
            .foregroundStyle(r.color.brandMint)
            .frame(minWidth: r.dimen.minimumTouchTarget)
            .frame(minHeight: r.dimen.minimumTouchTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(trimmedName.isEmpty)
        .opacity(trimmedName.isEmpty ? r.opacity.disabled : 1)
        .accessibilityHint("변경한 탑승 지점을 저장합니다")
      }
      .sharedBackgroundVisibility(.hidden)
    }
    .toolbarBackground(r.color.background, for: .navigationBar)
    .toolbarBackground(.visible, for: .navigationBar)
    .alert(
      "탑승 지점을 삭제할까요?",
      isPresented: Binding(
        get: { store.deleteConfirmation != nil },
        set: { isPresented in
          if !isPresented {
            store.send(.deleteConfirmationCancelled)
          }
        }
      )
    ) {
      Button("취소", role: .cancel) {
        store.send(.deleteConfirmationCancelled)
      }
      Button("탑승 지점 삭제", role: .destructive) {
        store.send(.deleteConfirmationConfirmed)
      }
    } message: {
      Text(deleteConfirmationMessage)
    }
  }

  private var nameSection: some View {
    VStack(alignment: .leading, spacing: r.dimen.spacingXSmall) {
      Text("이름")
        .font(r.font.metadata)
        .fontWeight(.medium)
        .foregroundStyle(r.color.textSecondary)

      TextField(
        "탑승 지점 이름",
        text: Binding(
          get: { store.name },
          set: { store.send(.nameChanged($0)) }
        )
      )
      .font(r.font.input)
      .foregroundStyle(r.color.textPrimary)
      .padding(.horizontal, r.dimen.spacingMedium)
      .frame(minHeight: r.dimen.textFieldHeight)
      .background(
        r.color.surface,
        in: RoundedRectangle(
          cornerRadius: r.dimen.controlRadius,
          style: .continuous
        )
      )
      .overlay {
        RoundedRectangle(
          cornerRadius: r.dimen.controlRadius,
          style: .continuous
        )
        .stroke(
          r.color.textSecondary.opacity(r.opacity.divider),
          lineWidth: 1
        )
      }
      .textInputAutocapitalization(.never)
      .accessibilityLabel("탑승 지점 이름")
    }
  }

  private var busStopsSection: some View {
    VStack(alignment: .leading, spacing: r.dimen.spacingSmall) {
      DashSectionHeader("정류장") {
        Text("\(busStops.count)개 · \(selectedRouteCount)개 노선")
          .font(r.font.metadata)
          .foregroundStyle(r.color.textSecondary)
      }

      DashGroupedSurface {
        VStack(spacing: 0) {
          ForEach(Array(busStops.enumerated()), id: \.element.id) { index, busStop in
            busStopRow(busStop)
            if index < busStops.count - 1 {
              DashListDivider(
                leadingInset: r.dimen.spacingMedium,
                trailingInset: r.dimen.spacingMedium
              )
            }
          }
        }
      }

      addBusStopButton
    }
  }

  private func busStopRow(_ busStop: BusStop) -> some View {
    HStack(spacing: r.dimen.spacingXXSmall) {
      Button {
        store.send(.busStopTapped(busStop.id))
      } label: {
        HStack(spacing: r.dimen.spacingSmall) {
          VStack(alignment: .leading, spacing: r.dimen.spacingXSmall) {
            Text(busStop.name)
              .font(r.font.rowTitle)
              .foregroundStyle(r.color.textPrimary)
              .lineLimit(2)
              .multilineTextAlignment(.leading)

            Text(verbatim: "정류장 번호 \(busStop.id)")
              .font(r.font.metadata)
              .foregroundStyle(r.color.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: r.dimen.spacingXSmall) {
              Text("선택 노선")
                .font(r.font.metadata)
                .fontWeight(.medium)
                .foregroundStyle(r.color.brandMint)

              Text(routeSummary(for: busStop))
                .font(r.font.metadata)
                .foregroundStyle(r.color.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)

          Image(systemName: "chevron.right")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(r.color.textSecondary)
            .accessibilityHidden(true)
        }
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel(busStopAccessibilityLabel(busStop))
      .accessibilityHint("버스 노선 선택 화면을 엽니다")

      Image(systemName: "line.3.horizontal")
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(r.color.textSecondary)
        .frame(
          width: r.dimen.minimumTouchTarget,
          height: r.dimen.minimumTouchTarget
        )
        .contentShape(Rectangle())
        .draggable(String(busStop.id))
        .accessibilityLabel("\(busStop.name) 순서 변경")
        .accessibilityHint("길게 눌러 원하는 위치로 끌어 이동합니다")

    }
    .dropDestination(for: String.self) { items, _ in
      guard let sourceID = items.compactMap({ Int($0) }).first,
            sourceID != busStop.id
      else {
        return false
      }
      store.send(.busStopMoved(sourceID: sourceID, targetID: busStop.id))
      return true
    }
    .padding(.leading, r.dimen.spacingMedium)
    .padding(.trailing, r.dimen.spacingXSmall)
    .padding(.vertical, r.dimen.rowVerticalPadding)
    .frame(minHeight: r.dimen.richRowMinHeight)
  }

  private var addBusStopButton: some View {
    DashGroupedSurface {
      Button {
        store.send(.addBusStopButtonTapped)
      } label: {
        Label("정류장 추가", systemImage: "plus")
          .font(r.font.sectionTitle)
          .foregroundStyle(r.color.brandMint)
          .frame(maxWidth: .infinity)
          .frame(minHeight: r.dimen.primaryButtonHeight)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
    }
    .accessibilityHint("정류장 추가 화면을 엽니다")
  }

  private var deleteBoardingPointButton: some View {
    Button("탑승 지점 삭제", role: .destructive) {
      store.send(.deleteBoardingPointButtonTapped)
    }
    .font(r.font.body)
    .foregroundStyle(.red)
    .frame(maxWidth: .infinity)
    .frame(minHeight: r.dimen.minimumTouchTarget)
    .buttonStyle(.plain)
    .accessibilityHint("확인 후 탑승 지점을 삭제합니다")
  }

  private var busStops: [BusStop] {
    let orderedStops = store.busStopOrder.compactMap { id in
      store.routes.keys.first(where: { $0.id == id })
    }
    let orderedIDs = Set(orderedStops.map(\.id))
    let remainingStops = store.routes.keys.filter { !orderedIDs.contains($0.id) }.sorted {
      let comparison = $0.name.localizedStandardCompare($1.name)
      if comparison == .orderedSame {
        return $0.id < $1.id
      }
      return comparison == .orderedAscending
    }
    return orderedStops + remainingStops
  }

  private var selectedRouteCount: Int {
    store.routes.values.reduce(0) { $0 + $1.count }
  }

  private func routeNumbers(for busStop: BusStop) -> [String] {
    (store.routes[busStop] ?? [])
      .map(\.number)
      .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
  }

  private func routeSummary(for busStop: BusStop) -> String {
    let routeNumbers = routeNumbers(for: busStop)
    return routeNumbers.isEmpty ? "없음" : routeNumbers.joined(separator: ", ")
  }

  private func busStopAccessibilityLabel(_ busStop: BusStop) -> String {
    let components = [
      busStop.name,
      "정류장 번호 \(busStop.id)",
      "선택 노선 \(routeSummary(for: busStop))",
    ]
    return components.joined(separator: ", ")
  }

  private var trimmedName: String {
    store.name.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private var deleteConfirmationMessage: String {
    switch store.deleteConfirmation {
    case .boardingPoint:
      return "‘\(displayName)’ 탑승 지점을 삭제합니다."
    case nil:
      return ""
    }
  }

  private var displayName: String {
    trimmedName.isEmpty ? store.boardingPoint.name : trimmedName
  }
}

#Preview {
  NavigationStack {
    EditBoardingPointView(
      store: Store(initialState: EditBoardingPointFeature.State(boardingPoint: .suwonStation)) {
        EditBoardingPointFeature()
      }
    )
  }
}
