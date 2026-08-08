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
        Divider()
          .background(r.color.textSecondary.opacity(0.25))
          .padding(.horizontal, 16)

        GeometryReader { proxy in
          ScrollView {
            VStack(alignment: .leading, spacing: 28) {
              nameSection
              busStopsSection

              Spacer(minLength: 56)

              deleteBoardingPointButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 24)
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
          .font(.system(size: 24, weight: .regular))
          .foregroundStyle(r.color.textPrimary)
      }
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          
        } label: {
          Text("저장")
            .font(.system(size: 20, weight: .regular))
            .foregroundStyle(r.color.brandMint)
        }
        .buttonStyle(.plain)
        .disabled(trimmedName.isEmpty)
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
    VStack(alignment: .leading, spacing: 10) {
      Text("이름")
        .font(.system(size: 15, weight: .medium))
        .foregroundStyle(r.color.textSecondary)

      TextField(
        "탑승 지점 이름",
        text: Binding(
          get: { store.name },
          set: { store.send(.nameChanged($0)) }
        )
      )
      .font(.system(size: 20, weight: .regular))
      .foregroundStyle(r.color.textPrimary)
      .padding(.horizontal, 16)
      .frame(height: 52)
      .background(
        r.color.surface,
        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
      )
      .overlay {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
          .stroke(r.color.textSecondary.opacity(0.18), lineWidth: 1)
      }
      .textInputAutocapitalization(.never)
      .accessibilityLabel("탑승 지점 이름")
    }
  }

  private var busStopsSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("정류장")
        .font(.system(size: 17, weight: .semibold))
        .foregroundStyle(r.color.textPrimary)
      VStack(spacing: 0) {
        ForEach(Array(busStops.enumerated()), id: \.element.id) { index, busStop in
          busStopRow(busStop)
          if index < busStops.count - 1 {
            Divider()
              .background(r.color.textSecondary.opacity(0.25))
              .padding(.horizontal, 24)
          }
        }
      }
      .background(
        r.color.surface,
        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
      )
      .overlay {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .stroke(r.color.textSecondary.opacity(0.18), lineWidth: 1)
      }

      addBusStopButton
    }
  }

  private func busStopRow(_ busStop: BusStop) -> some View {
    HStack(spacing: 4) {
      Button {
        store.send(.busStopTapped(busStop.id))
      } label: {
        HStack(spacing: 12) {
          VStack(alignment: .leading, spacing: 5) {
            Text(busStop.name)
              .font(.system(size: 18, weight: .semibold))
              .foregroundStyle(r.color.textPrimary)
              .lineLimit(2)
              .multilineTextAlignment(.leading)

            if let alias = busStop.alias {
              Text(alias)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(r.color.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            }

            Text(verbatim: "정류장 번호 \(busStop.id)")
              .font(.system(size: 14, weight: .regular))
              .foregroundStyle(r.color.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
              Text("선택 노선")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(r.color.brandMint)

              Text(routeNumbers(for: busStop).joined(separator: ", "))
                .font(.system(size: 14, weight: .regular))
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
        .frame(width: 44, height: 44)
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
    .padding(.leading, 16)
    .padding(.trailing, 8)
    .padding(.vertical, 17)
  }

  private var addBusStopButton: some View {
    Button {
      store.send(.addBusStopButtonTapped)
    } label: {
      Label("정류장 추가", systemImage: "plus")
        .font(.system(size: 17, weight: .medium))
        .foregroundStyle(r.color.brandMint)
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .background(
      r.color.surface,
      in: RoundedRectangle(cornerRadius: 14, style: .continuous)
    )
    .overlay {
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .stroke(r.color.textSecondary.opacity(0.18), lineWidth: 1)
    }
    .accessibilityHint("정류장 추가 화면을 엽니다")
  }

  private var deleteBoardingPointButton: some View {
    Button("탑승 지점 삭제", role: .destructive) {
      store.send(.deleteBoardingPointButtonTapped)
    }
    .font(.system(size: 17, weight: .regular))
    .foregroundStyle(.red)
    .frame(maxWidth: .infinity)
    .frame(minHeight: 44)
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

  private func busStopAccessibilityLabel(_ busStop: BusStop) -> String {
    let components = [
      busStop.name,
      busStop.alias,
      "정류장 번호 \(busStop.id)",
      "선택 노선 \(routeNumbers(for: busStop).joined(separator: ", "))",
    ]
    return components.compactMap { $0 }.joined(separator: ", ")
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
