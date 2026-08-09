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
