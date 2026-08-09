# 탑승 지점 저장 계약 v1

`BoardingPointConfiguration`은 사용자가 설정한 탑승 지점과 현재 선택 지점을 함께 보관한다. iOS는 SwiftData, Android는 Room 등 각 플랫폼의 저장 방식을 사용할 수 있지만 이 문서의 의미와 필드는 동일하게 유지한다.

## 스키마

```json
{
  "boardingPoints": [
    {
      "id": "suwon-station",
      "name": "수원역",
      "stops": [
        {
          "id": 202000106,
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

## 의미와 제약

- `boardingPoints`의 배열 순서는 목록과 다음 탑승 지점 전환에 사용하므로 보존한다.
- `stops`와 `selectedRoutes`는 순서에 의미가 없다.
- 탑승 지점은 정류장 0개, 정류장은 선택 노선 0개를 가질 수 있다.
- 최초 실행을 위해 `boardingPoints`가 비어 있는 configuration도 허용한다. UI는 탑승 지점이 하나만 남은 뒤의 삭제를 막는다.
- `currentBoardingPointID`는 `null`이거나 `boardingPoints` 안의 ID여야 한다.
- 정류장 alias는 저장하지만 기본 UI에는 표시하지 않는다.
- 노선 ID는 지역과 함께 저장한다. 노선 번호는 렌더링과 오프라인 표시를 위한 snapshot이다.
- 도착 정보, API 응답 원문, 검색 결과 캐시는 이 configuration에 저장하지 않는다.

## 플랫폼 매핑

- iOS: `BoardingPointConfigurationRecord` → `BoardingPointRecord` → `BoardingPointStopRecord` → `SelectedRouteRecord`
- Android: configuration table 또는 settings row → boarding point → stop membership → selected route 관계

같은 실제 정류장이 여러 탑승 지점에 포함될 수 있으므로, 정류장은 전역 정류장 마스터가 아니라 탑승 지점의 stop membership으로 저장한다.
