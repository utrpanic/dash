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
        Text("승차 지점")
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
        .accessibilityLabel("승차 지점 추가")
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
            if boardingPoint.id != store.boardingPoints.last?.id {
              Divider()
                .background(r.color.textSecondary.opacity(0.25))
            }
          }
        }
      }
      .scrollIndicators(.hidden)
    }
    .padding(.horizontal, 16)
  }

  private var emptyState: some View {
    ContentUnavailableView {
      Label("등록된 승차 지점이 없습니다", systemImage: "bus")
    } actions: {
      Button("승차 지점 추가") {
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
        HStack(spacing: 16) {
          selectionIndicator

          VStack(alignment: .leading, spacing: 6) {
            Text(boardingPoint.name)
              .font(.system(size: 20, weight: .semibold))
              .foregroundStyle(r.color.textPrimary)
              .lineLimit(1)

            Text(routeNumbers.joined(separator: ", "))
              .font(.system(size: 16, weight: .regular))
              .foregroundStyle(r.color.textSecondary)
              .lineLimit(2)
              .multilineTextAlignment(.leading)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel(
        isSelected
          ? "\(boardingPoint.name), 현재 선택됨"
          : boardingPoint.name
      )

      Button(action: edit) {
        Image(systemName: "square.and.pencil")
          .font(.system(size: 20, weight: .regular))
          .foregroundStyle(r.color.textSecondary)
          .frame(width: 44, height: 44)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("\(boardingPoint.name) 편집")
    }
    .frame(minHeight: 84)
    .padding(.horizontal, 20)
  }

  @ViewBuilder
  private var selectionIndicator: some View {
    if isSelected {
      Image(systemName: "checkmark")
        .font(.system(size: 20, weight: .regular))
        .foregroundStyle(r.color.brandMint)
        .frame(width: 32, height: 32)
        .accessibilityHidden(true)
    } else {
      Color.clear
        .frame(width: 32, height: 32)
        .accessibilityHidden(true)
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
