import ComposableArchitecture
import Foundation
import SwiftUI

struct BoardingPointsView: View {
  let store: StoreOf<BoardingPointsFeature>

  var body: some View {
    ZStack {
      r.color.background
        .ignoresSafeArea()

      if store.boardingPoints.isEmpty {
        emptyState
      } else {
        boardingPointList
      }
    }
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .principal) {
        Text("탑승 지점")
          .font(.system(size: 24, weight: .regular))
          .foregroundStyle(r.color.textPrimary)
      }
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          store.send(.addButtonTapped)
        } label: {
          Image(systemName: "plus")
            .font(.system(size: 22, weight: .regular))
            .foregroundStyle(r.color.brandMint)
            .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("탑승 지점 추가")
      }
      .sharedBackgroundVisibility(.hidden)
    }
    .toolbarBackground(r.color.background, for: .navigationBar)
    .toolbarBackground(.visible, for: .navigationBar)
  }

  private var boardingPointList: some View {
    VStack(spacing: 0) {
      Divider()
        .background(r.color.textSecondary.opacity(0.25))
      ScrollView {
        LazyVStack(spacing: 0) {
          ForEach(store.boardingPoints) { boardingPoint in
            BoardingPointRowView(
              boardingPoint: boardingPoint,
              isSelected: boardingPoint.id == store.selectedBoardingPointID,
              select: {
                store.send(.boardingPointTapped(boardingPoint.id))
              },
              edit: {
                store.send(.editButtonTapped(boardingPoint.id))
              }
            )
            Divider()
              .background(r.color.textSecondary.opacity(0.25))
          }
        }
      }
      .scrollIndicators(.hidden)
    }
    .padding(.horizontal, 16)
  }

  private var emptyState: some View {
    ContentUnavailableView {
      Label("등록된 탑승 지점이 없습니다", systemImage: "bus")
    } actions: {
      Button("탑승 지점 추가") {
        store.send(.addButtonTapped)
      }
      .buttonStyle(.borderedProminent)
      .tint(r.color.brandMint)
    }
  }
}

private struct BoardingPointRowView: View {
  let boardingPoint: BoardingPoint
  let isSelected: Bool
  let select: () -> Void
  let edit: () -> Void

  var body: some View {
    HStack(spacing: 8) {
      Button(action: select) {
        VStack(alignment: .leading, spacing: 6) {
          Text(boardingPoint.name)
            .font(.system(size: 20, weight: isSelected ? .semibold : .medium))
            .foregroundStyle(r.color.textPrimary)
            .lineLimit(1)

          Text("\(routeNumbers.count)개 노선 · \(routeNumbers.joined(separator: ", "))")
            .font(.system(size: 16, weight: .regular))
            .foregroundStyle(r.color.textSecondary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel(
        isSelected
          ? "\(boardingPoint.name), 현재 선택됨"
          : boardingPoint.name
      )
      .accessibilityHint("현재 탑승 지점으로 선택합니다")

      Button(action: edit) {
        Image(systemName: "square.and.pencil")
          .font(.system(size: 20, weight: .regular))
          .foregroundStyle(r.color.textSecondary)
          .frame(width: 44, height: 44)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("\(boardingPoint.name) 편집")
    }
    .frame(height: 86)
    .padding(.horizontal, 16)
    .background {
      if isSelected {
        ZStack(alignment: .leading) {
          r.color.brandMint.opacity(0.08)
          Rectangle()
            .fill(r.color.brandMint)
            .frame(width: 4)
        }
      }
    }
  }

  private var routeNumbers: [String] {
    Set(boardingPoint.routes.values.flatMap { $0 })
      .map(\.number)
      .sorted {
        $0.localizedStandardCompare($1) == .orderedAscending
      }
  }
}

#Preview {
  NavigationStack {
    BoardingPointsView(
      store: Store(
        initialState: BoardingPointsFeature.State(
          boardingPoints: .mock,
          selectedBoardingPointID: BoardingPoint.suwonStation.id
        )
      ) {
        BoardingPointsFeature()
      }
    )
  }
}
