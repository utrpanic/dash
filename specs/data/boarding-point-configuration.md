# 탑승 지점 저장 계약 v1

`BoardingPointConfiguration`은 사용자가 설정한 탑승 지점과 마지막으로 선택한 지점을 함께 보관한다. iOS는 SwiftData, Android는 Room 등 플랫폼 저장 방식을 사용할 수 있지만 아래 의미와 제약은 동일하다.

## 논리 스키마

```json
{
  "boardingPoints": [
    {
      "id": "suwon-station",
      "name": "수원역",
      "stops": [
        {
          "id": 202000106,
          "region": "gyeonggi",
          "arsID": null,
          "name": "수원역7번출구.AK플라자",
          "alias": null,
          "latitude": 37.2674167,
          "longitude": 127.0009,
          "selectedRoutes": [
            {
              "id": 200000069,
              "number": "13-1",
              "region": "gyeonggi"
            }
          ]
        }
      ]
    }
  ],
  "currentBoardingPointID": "suwon-station"
}
```

서울 정류장은 `stopID`와 `arsID`, 경기 정류장은 `stopID`로 식별한다. 저장 구조가 단일 정수 `id`를 사용하더라도 `region` 및 서울의 `arsID`를 함께 보존해야 한다.

## 의미와 제약

- `boardingPoints` 배열 순서는 목록 및 다음 지점 전환 순서이므로 보존한다.
- `stops`와 `selectedRoutes`의 저장 순서에는 제품 의미가 없다.
- 탑승 지점은 정류장 0개, 정류장은 선택 노선 0개를 가질 수 있다.
- `currentBoardingPointID`는 `null`이거나 `boardingPoints` 안의 ID여야 한다.
- 현재 지점 값은 마지막 선택의 기록이다. 앱 시작 시 유효한 현재 위치를 얻으면 최근접 지점이 이 값을 덮어쓰며, 위치 실패 시에만 fallback으로 사용한다.
- 자동 최근접 선택과 다음 지점 전환 후보는 선택 노선이 하나 이상인 탑승 지점뿐이다.
- 탑승 지점 좌표는 포함된 모든 정류장 좌표의 산술 평균이다. 선택 노선이 없는 정류장도 중심 계산에는 포함한다.
- 정류장 alias는 저장하지만 현재 기본 UI에는 표시하지 않는다.
- 노선 ID는 지역과 함께 저장한다. 노선 번호는 렌더링 및 오프라인 표시를 위한 snapshot이다.
- 같은 실제 정류장이 여러 탑승 지점에 포함될 수 있으므로 정류장은 전역 master가 아니라 탑승 지점의 membership으로 저장한다.
- 도착 정보, API 응답 원문, 검색 결과 및 경유 노선 조회 결과는 저장하지 않는다.

## 초기값과 변경 처리

- 최초 설치의 기본 설정은 영등포역과 더현대서울 두 지점이며 현재 지점은 영등포역이다. 이는 마이그레이션 대상이 아닌 첫 버전의 의도적인 seed다.
- 새 탑승 지점은 저장 시 배열 끝에 추가하지만 자동으로 현재 지점으로 선택하지 않는다.
- 마지막 남은 탑승 지점은 삭제하지 않는다.
- 화면 상태는 변경을 즉시 반영하고 저장은 순차 수행한다. 저장 중 추가 변경이 발생하면 가장 최신 configuration을 pending 값으로 유지한다.
- 저장 실패 시 최신 configuration을 유지하고 사용자에게 재시도를 제공한다.

## 플랫폼 매핑

- iOS: `BoardingPointConfigurationRecord` → `BoardingPointRecord` → `BoardingPointStopRecord` → `SelectedRouteRecord`
- Android: configuration table 또는 settings row → boarding point → stop membership → selected route 관계

플랫폼의 물리 스키마는 달라도 위 논리 스키마를 손실 없이 왕복할 수 있어야 한다.
