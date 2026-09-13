# Dash Android 진행 상태

기준: 2026-09-14 · Android Room 저장 계층 구현 완료.

## 완료

1. `79145c1` — 현재 iOS 구현을 Source of truth로 삼아 제품·데이터·API·디자인 공유 명세를 최신화.
2. `440f960` — Kotlin·Compose 기반 Android 초기 프로젝트를 추가하고 emulator 실행 확인.
3. `58826f4` — 환경변수 또는 ignored properties를 입력으로 사용하는 단일 공통 secret 생성기와 Android Secrets Gradle Plugin, GitHub Actions 초안을 구성.
4. `72a015b` — [단계 1 완료] Android 기반 domain model과 repository interface를 공유 계약에 맞춰 구현하고 단위 테스트를 추가.
5. `b07f576` — [단계 2 완료] 서울·경기 API client와 부분 성공 결합 repository를 구현하고 실제 응답 integration test 3개 통과.
6. [단계 3 완료] Room V1 스키마와 repository, 영등포역·더현대서울 seed를 구현하고 emulator 디스크 재오픈 테스트 2개 통과.
7. [단계 4 완료] Android 위치 provider와 현재 위치 최우선·저장값 fallback 선택 정책을 구현하고 단위 테스트 통과.
8. [단계 5 완료] 현재 탑승 지점의 병렬 도착 조회·정렬·최대 5개 표시와 위치·새로고침·active 재조회 UI를 구현.
9. [단계 6 완료] 탑승 지점 목록 선택과 추가·이름 편집·정류장 제거·저장·삭제 UI를 Room 저장소에 연결.
10. [단계 7 완료] Google Maps 기반 정류장 주변·검색 결과, A–Z marker, 즉시 선택·스크롤·경유 노선 상세·draft 추가를 구현.
11. [단계 8 완료] 자연 정렬 adaptive route grid, 기존 선택 보존, 복수 선택, 0개 완료 방지를 갖춘 버스 노선 선택을 구현.

## 다음 단계

1. 전체 흐름 계측 테스트와 실제 Google Maps 키 기반 지도 렌더링 검증 및 마감.

## 보류

1. 노선 우선 추가 흐름 설계 및 구현.

## 구현 기준

1. 제품 동작의 Source of truth는 현재 iOS 앱이며 플랫폼 중립 계약은 `specs/`를 따른다.
2. Android UI는 공유 디자인 의미를 유지하면서 Material 및 Android 접근성 관례에 맞게 구현한다.
3. 각 단계는 구현·테스트·커밋 후 완료 항목으로 이동한다.
