# Dash Android 진행 상태

기준: 2026-09-14 · Android API 계층 구현 완료, 실제 API 응답 검증 대기.

## 완료

1. `79145c1` — 현재 iOS 구현을 Source of truth로 삼아 제품·데이터·API·디자인 공유 명세를 최신화.
2. `440f960` — Kotlin·Compose 기반 Android 초기 프로젝트를 추가하고 emulator 실행 확인.
3. `58826f4` — 환경변수 또는 ignored properties를 입력으로 사용하는 단일 공통 secret 생성기와 Android Secrets Gradle Plugin, GitHub Actions 초안을 구성.
4. `72a015b` — [단계 1 완료] Android 기반 domain model과 repository interface를 공유 계약에 맞춰 구현하고 단위 테스트를 추가.
5. [단계 2 완료] 서울·경기 API client와 부분 성공 결합 repository, parser·repository·live integration test를 구현하고 빌드·단위 테스트·lint 통과.

## 다음 단계

1. Room 저장소와 의도된 초기 seed 구현.
2. 현재 위치 기반 탑승 지점 선택 구현.
3. 현재 탑승 지점 및 도착 정보 화면 구현.
4. 탑승 지점 목록·편집 화면 구현.
5. Google Maps 기반 정류장 검색·추가 화면 구현.
6. 버스 노선 선택 화면 구현.
7. 전체 흐름 계측 테스트와 마감.

## 보류

1. 노선 우선 추가 흐름 설계 및 구현.

## 구현 기준

1. 제품 동작의 Source of truth는 현재 iOS 앱이며 플랫폼 중립 계약은 `specs/`를 따른다.
2. Android UI는 공유 디자인 의미를 유지하면서 Material 및 Android 접근성 관례에 맞게 구현한다.
3. 각 단계는 구현·테스트·커밋 후 완료 항목으로 이동한다.

## 확인 필요

1. 루트 `.secrets.properties`에 실제 키를 구성한 뒤 Android live integration test 3개로 서울·경기 응답을 검증한다.
