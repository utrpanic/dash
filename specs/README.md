# Dash 공유 명세

이 디렉터리는 iOS와 Android가 공유하는 제품 동작, 데이터, API, 디자인 계약을 보관한다.

## Source of truth

- Android가 현재 기능을 재현할 때의 제품 동작 기준은 `app-ios/`의 실행 가능한 구현이다.
- 이 문서는 iOS 구현을 플랫폼 중립적인 계약으로 옮긴 것이다. 문서와 코드가 충돌하면 iOS 코드를 확인하고 같은 변경에서 문서를 바로잡는다.
- 플랫폼별 UI는 각 운영체제의 관례와 접근성 규칙에 맞게 조정할 수 있지만, 선택 정책·저장 의미·오류 처리 같은 제품 동작은 공유 명세를 따른다.
- 이 문서는 2026-09-13, iOS 커밋 `8359a4a`를 기준으로 검증했다.

## 문서 구조

1. [탑승 지점 MVP](product/boarding-point-mvp.md): 현재 구현된 화면과 사용자 흐름
2. [탑승 지점 저장 계약](data/boarding-point-configuration.md): 영속 데이터의 의미와 제약
3. [API 명세와 클라이언트 계약](api/README.md): 공공 API와 결합·실패 처리
4. [디자인 시스템](design/design-system.md): 공통 시각 문법과 플랫폼 매핑
5. [탑승 지점 디자인 언어](design/design-language.md): 화면별 정보 구조와 선택 표현

`design/boarding-point-mockups/`의 `-v2` 이미지는 방향을 설명하는 참고 자료다. 실제 동작과 세부 상태는 문서 및 iOS 구현을 우선한다.

## 외부 기획 자료

전체 서비스 기획은 [Project](https://app.notion.com/p/Project-392b093902d180da9307d6170d5a90c8)에서 관리한다.
