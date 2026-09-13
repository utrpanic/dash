# API 명세와 클라이언트 계약

## 공통 도메인 매핑

- 서비스 지역은 `seoul`과 `gyeonggi`다.
- 경기 정류장 ID는 `stopID`, 서울 정류장 ID는 `stopID + arsID` 조합이다. 서로 다른 지역의 숫자 ID가 같아도 같은 정류장으로 취급하지 않는다.
- 정류장 추가 검색 목록은 경기의 경우 `stopID`, 서울은 값이 있는 `arsID`를 우선하고 없으면 `stopID`를 표시한다. 현재 iOS의 편집 및 노선 선택 화면은 지역과 무관하게 API `stopID`를 표시한다.
- 노선은 `region + routeID`로 식별하며 번호는 표시용 값이다.
- 인증키는 저장소에 넣지 않고 각 플랫폼의 로컬 secret 구성으로 주입한다.

## 클라이언트 결합 정책

### 정류장 검색과 주변 조회

- 서울 및 경기 API를 동시에 호출한다.
- 한 지역 요청이 실패해도 다른 지역이 성공하면 성공 결과를 사용한다.
- 빈 결과도 정상 응답이다. 두 지역 요청이 모두 실패했을 때만 전체 실패다.
- 결합 결과는 도메인 정류장 ID로 중복 제거한다.
- 주변 조회 지원 범위는 현재 iOS와 동일하게 위도 `36.8...38.4`, 경도 `126.0...128.3`으로 제한한다. 범위 밖에서는 빈 결과를 반환한다.

### 경유 노선 조회

- 선택한 정류장의 지역에 해당하는 API만 호출한다.
- 정류장 추가 화면에서는 선택한 정류장에 대해서만 조회한다.
- 노선 선택 화면에서는 이전에 저장한 노선이 API 응답에서 누락되어도 선택 후보에 합쳐 보존한다.

### 도착 정보 조회

- 탑승 지점에서 선택 노선이 있는 정류장들을 동시에 조회한다.
- 일부 정류장만 성공하면 성공한 도착 정보를 사용하고, 모든 정류장 조회가 실패했을 때만 전체 실패다.
- 경기 API는 정류장의 전체 도착 목록을 한 번 받은 뒤 선택된 `routeID`만 남긴다.
- 서울 API는 선택 노선별 요청을 동시에 수행하고 해당 `stopID`의 결과만 남긴다. 일부 노선 요청만 성공해도 성공 결과를 사용한다.
- 경기 도착 목록의 `resultCode == 4` 및 누락된 `msgBody`는 오류가 아닌 빈 결과로 해석한다. 그 밖의 0이 아닌 결과 코드는 오류다.
- API 응답 원문과 도착 정보는 영속 저장하지 않는다.

## 전송 제약

- 경기 API는 `https://apis.data.go.kr`을 사용한다.
- 서울 API는 현재 `http://ws.bus.go.kr`을 사용한다. 플랫폼 보안 설정에서 예외가 필요하면 해당 host에만 최소 범위로 허용한다.
- 요청 timeout의 현재 기준은 15초다.

## 소스

- [공공데이터 활용신청 목록](https://www.data.go.kr/iim/api/selectAcountList.do)

## 서울특별시

### [서울특별시_정류소정보조회 서비스](https://www.data.go.kr/data/15000303/openapi.do)

| API | 설명 |
| --- | --- |
| `getStationByNameList` | 정류소 명칭 검색 |
| `getStationByUidItem` | 정류소 고유번호로 버스도착정보 목록 조회 |
| `getRouteByStationList` | 정류소 고유번호로 경유 노선 목록 조회 |
| `getBustimeByStationList` | 정류소 고유번호·노선 ID로 첫차·막차 예정시간 조회 |
| `getLowStationByNameList` | 저상버스 운행 정류소 명칭 검색 |
| `getLowStaionByUidList` | 정류소 고유번호의 저상버스 도착정보 조회 |
| `getStaionsByPosList` | 좌표 기반 근접 정류소 조회 |

### [서울특별시_노선정보조회 서비스](https://www.data.go.kr/data/15000193/openapi.do)

| API | 설명 |
| --- | --- |
| `getStaionsByRouteList` | 노선별 경유 정류소 조회 |
| `getRouteInfoItem` | 노선 기본정보 조회 |
| `getRoutePathList` | 노선 지도상 경로 조회 |
| `getBusRouteList` | 노선번호에 해당하는 노선 목록 조회 |

### [서울특별시_버스도착정보조회 서비스](https://www.data.go.kr/data/15000314/openapi.do)

| API | 설명 |
| --- | --- |
| `getArrInfoByRouteAllList` | 경유노선 전체 정류소 도착예정정보 조회 |
| `getArrInfoByRouteList` | 정류소의 특정 노선 도착예정정보 조회 |
| `getLowArrInfoByStIdList` | 정류소 저상버스 도착예정정보 조회 |
| `getLowArrInfoByRouteList` | 정류소의 특정 저상버스 도착예정정보 조회 |

## 경기도

### [경기도_정류소 조회](https://www.data.go.kr/data/15080666/openapi.do)

| API | 설명 |
| --- | --- |
| `getBusStationListv2` | 정류소명·번호 목록 조회 |
| `getBusStationAroundListv2` | 주변 정류소 목록 조회 |
| `getBusStationViaRouteListv2` | 정류소 경유 노선 목록 조회 |
| `busStationInfov2` | 정류소 정보 항목 조회 |

### [경기도_버스노선 조회](https://www.data.go.kr/data/15080662/openapi.do)

| API | 설명 |
| --- | --- |
| `getBusRouteListv2` | 노선번호에 해당하는 노선 목록 조회 |
| `getBusRouteInfoItemv2` | 노선 기본정보 조회 |
| `getBusRouteStationListv2` | 노선별 경유 정류소 조회 |
| `getBusRouteLineListv2` | 노선 지도상 경로 조회 |

### [경기도_버스도착정보 조회](https://www.data.go.kr/data/15080346/openapi.do)

| API | 설명 |
| --- | --- |
| `getBusArrivalListv2` | 버스도착정보 목록 조회 |
| `getBusArrivalItemv2` | 버스도착정보 항목 조회 |

## 저장된 참고 명세

- `경기도-버스노선-swagger.json`, `경기도-버스도착정보-swagger.json`: 제공 페이지의 inline Swagger 자료에서 추출
- `서울-버스노선-api-spec.json`, `서울-버스도착정보-api-spec.json`: 제공 페이지의 요청·응답 표를 바탕으로 프로젝트에서 작성한 Swagger 2.0 문서
- `bus-route-list-13.json`, `bus-route-station-list-13.json`: 통합 테스트 및 응답 구조 확인용 fixture
