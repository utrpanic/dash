# Dash 디자인 시스템

## 목적

이 문서는 Dash의 모든 iOS 화면에 적용하는 공통 UI 계약이다. 화면 시안은 이 계약을 적용한 예시이며, 값이 충돌하면 이 문서를 우선한다.

화면 구현에서 새로운 간격, 높이, radius, 선택 표현을 임의로 만들지 않는다. 새로운 값이 필요하면 먼저 이 문서에 사용 목적과 예외 범위를 기록한다.

## 원칙

1. iOS의 기본 내비게이션, 접근성, Dynamic Type 동작을 우선한다.
2. 빠른 비교가 필요한 데이터는 평면 목록, 관련 값을 편집하는 영역은 grouped surface, 독립적인 상태 정보는 card로 표현한다.
3. 같은 의미의 상태는 모든 화면에서 같은 시각 문법을 사용한다.
4. 높이는 텍스트가 커질 수 있도록 고정값보다 최소 높이와 padding으로 정의한다.
5. 콘텐츠 표면에는 그림자를 사용하지 않고 Divider 또는 얇은 stroke를 사용한다.

참고 기준:

- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Apple Design Resources](https://developer.apple.com/design/resources/)

## Foundations

### Color

| Token | Resource | 용도 |
|---|---|---|
| `background` | `r.color.background` | 화면 배경 |
| `surface` | `r.color.surface` | 입력, grouped surface, card |
| `brand` | `r.color.brandMint` | 주요 액션과 선택 상태 |
| `textPrimary` | `r.color.textPrimary` | 제목과 핵심 정보 |
| `textSecondary` | `r.color.textSecondary` | 설명과 메타데이터 |
| `divider` | `textSecondary.opacity(0.25)` | 목록과 내비게이션 구분 |
| `destructive` | system red | 삭제와 파괴적 액션 |

선택 배경은 `brand.opacity(0.08)`, 비활성 콘텐츠는 전체 opacity `0.45`를 기본값으로 사용한다.

### Spacing

| Token | Value | 용도 |
|---|---:|---|
| `xxSmall` | 4pt | 아이콘과 짧은 텍스트 사이 |
| `xSmall` | 8pt | 밀접한 요소 사이 |
| `small` | 12pt | 행 내부 요소와 control 주변 |
| `medium` | 16pt | 화면·목록 좌우 여백, 기본 control padding |
| `large` | 24pt | 섹션 사이와 화면 상하 여백 |
| `xLarge` | 32pt | 강한 섹션 분리만 허용 |

기본 화면과 목록의 좌우 여백은 `16pt`이다. 지도 위 검색창처럼 콘텐츠 위에 뜨는 overlay도 별도 예외가 없으면 `16pt`를 사용한다.

### Typography

| Token | Value | 용도 |
|---|---|---|
| `screenTitle` | 24pt regular | 내비게이션 화면 제목 |
| `sectionTitle` | 17pt semibold | 섹션 제목 |
| `input` | 20pt regular | 단일 행 입력값 |
| `rowTitle` | 20pt medium | 일반 행 제목 |
| `selectedRowTitle` | 20pt semibold | 선택 행 제목 |
| `body` | 16pt regular | 본문과 행 보조 정보 |
| `metadata` | 14pt regular | 식별자와 부가 정보 |
| `navigationAction` | 17pt semibold | 저장·완료 같은 텍스트 액션 |
| `arrivalRoute` | 40pt semibold | 도착 카드 노선 번호 |
| `arrivalValue` | 48pt | 도착까지 남은 시간 |

구현은 이 의미 기반 token을 사용하고 Dynamic Type에서 줄바꿈과 높이 증가를 허용한다.

### Size

| Token | Value | 용도 |
|---|---:|---|
| `minimumTouchTarget` | 44pt | 모든 버튼과 선택 영역 |
| `textFieldHeight` | 52pt | 단일 행 입력 |
| `primaryButtonHeight` | 56pt | 화면 주요 액션 |
| `utilityButtonSize` | 64pt | 지도·새로고침 floating 원형 버튼 |
| `compactRowMinHeight` | 56pt | 한 줄 행 |
| `standardRowMinHeight` | 72pt | 두 줄 행 |
| `richRowMinHeight` | 88pt | 세 줄 이상 또는 줄바꿈 가능한 행 |
| `rowVerticalPadding` | 14pt | 목록 행 상하 padding |
| `selectionRailWidth` | 4pt | 단일 선택 rail |

### Radius

| Token | Value | 용도 |
|---|---:|---|
| `control` | 12pt | TextField와 일반 버튼 |
| `surface` | 16pt | grouped surface와 status card |
| `selectionRail` | 0pt | 목록 경계와 일치하는 rail |
| `capsule` | capsule | 검색창과 pill 형태 control |

### Elevation

- 목록, 입력, grouped surface, card는 그림자를 사용하지 않는다.
- 화면 위에 뜨는 floating action과 utility button만 `black 12% / radius 8 / y 3` 그림자를 사용한다.
- overlay search field는 `black 10% / radius 8 / y 2`를 사용한다.

## Components

### Navigation bar

- 상세 화면은 시스템 back button, 중앙 `screenTitle`, trailing 44pt 액션 영역을 사용한다.
- 주요 텍스트 액션은 `navigationAction`과 brand color를 사용한다.
- 내비게이션 아래에는 `divider`를 표시한다.

### Flat list row

- 외부 rounded container를 사용하지 않는다.
- 행 콘텐츠는 좌우 `16pt`, 상하 `14pt` padding을 사용한다.
- 콘텐츠에 따라 compact, standard, rich 최소 높이를 선택한다.
- 행 사이 Divider는 목록의 16pt 콘텐츠 영역 안에 둔다.
- 행 전체 탭과 trailing 보조 액션은 독립적인 44pt 이상 터치 영역을 가진다.

### Grouped surface

- 서로 관련된 입력 또는 편집 행을 하나의 `surface` 배경으로 묶는다.
- radius는 `16pt`, 테두리는 `divider` 색상 1pt를 사용한다.
- grouped surface 내부 행은 Divider로 나눈다.

### Status card

- 실시간 도착 정보처럼 각 항목이 독립적인 상태 단위일 때만 사용한다.
- `surface` 배경, radius `16pt`, divider 색상 1pt stroke를 사용한다.
- 콘텐츠 그림자는 사용하지 않는다.

### Primary button

- 높이 `56pt`, 좌우 화면 여백 `16pt`, radius `12pt`를 사용한다.
- 가장 중요한 완료 액션 한 개에만 brand 배경과 흰색 제목을 사용한다.
- 비활성 상태는 opacity `0.45`를 사용한다.

### Floating primary button

- 스크롤 콘텐츠 위에 overlay한다.
- 화면 하단과 좌우 safe area에서 `16pt` 이상 띄운다.
- 스크롤 콘텐츠에는 버튼 전체 높이와 하단 간격만큼 bottom inset을 둔다.
- primary button의 크기와 색상을 사용하고 floating elevation을 추가한다.

## Interaction states

### 단일 선택

- `brand.opacity(0.08)` 배경
- 왼쪽 전체 높이 `4pt` brand rail
- 제목을 `selectedRowTitle`로 강조
- 접근성 레이블에 선택 상태 포함

탑승 지점 목록의 현재 지점과 정류장 추가 화면의 임시 선택은 같은 단일 선택 컴포넌트를 사용한다.

### 다중 선택

- 단일 선택과 같은 brand 8% 배경
- selection rail은 사용하지 않는다.
- trailing check circle로 포함 여부를 표시한다.

### 지도와 목록 선택

- 지도 A/B/C 마커는 지도와 목록의 항목 대응 정보다.
- 실제 선택 상태는 지도와 목록이 하나의 selection state를 공유한다.
- 색상만을 유일한 선택 신호로 사용하지 않고 목록 rail과 제목 강조를 함께 제공한다.

### Pressed, disabled, destructive

- custom button은 pressed feedback을 제공한다.
- disabled는 opacity `0.45`와 interaction 비활성화를 함께 적용한다.
- destructive action은 system red와 destructive role을 사용하고 확인 절차를 제공한다.

## Surface decision

| 질문 | Yes | No |
|---|---|---|
| 여러 항목을 빠르게 비교하거나 선택하는가? | Flat list | 다음 질문 |
| 관련된 값을 한 덩어리로 편집하는가? | Grouped surface | 다음 질문 |
| 독립적인 실시간 상태 단위인가? | Status card | 기본 배경 위 콘텐츠 |

장식 목적으로 card를 사용하지 않는다.

## Screen templates

### StatusDashboard

- 루트 selector 또는 화면 정체성 control
- status card 목록
- floating utility actions
- loading, empty, error 상태

적용: 현재 탑승 지점 화면

### FlatEntityList

- navigation title과 add action
- flat list row와 inset Divider
- 필요할 때 single selection
- trailing 보조 action
- empty 상태

적용: 탑승 지점 목록 화면

### FormEditor

- navigation save action
- 이름 입력
- grouped edit surface
- 추가 action
- 화면 하단 destructive action

적용: 탑승 지점 편집 화면

### MultiSelectList

- flat list row와 inset Divider
- multi selection 상태
- 완료 action

적용: 버스 노선 선택 화면

### MapSingleSelect

- full-width 1:1 지도
- 지도 위 검색 overlay
- 지도와 연결된 flat list
- single selection 상태
- floating primary action

적용: 정류장 추가 화면

## 화면 명세 작성 형식

새 화면은 수치를 다시 정의하지 않고 아래 항목만 기록한다.

```md
## 화면 이름

Template: FlatEntityList
Entity: BoardingPoint
Row: title + route summary + trailing edit
Selection: single persistent
Primary action: navigation-bar add
States: loading, empty, error, content
Exceptions: none
```

## 예외 관리

- 예외는 화면 명세의 `Exceptions`에 이유와 적용 범위를 기록한다.
- 두 화면 이상에서 같은 예외가 필요하면 component 또는 token으로 승격한다.
- 시안에만 존재하고 문서화되지 않은 숫자는 구현 기준으로 사용하지 않는다.
- 공통 component 변경은 대표 화면 한 곳에서 먼저 검증한 뒤 다른 화면에 적용한다.

## 검수 체크리스트

1. raw spacing, font size, radius가 화면 코드에 새로 추가되지 않았는가?
2. flat list, grouped surface, status card 선택이 데이터 목적과 맞는가?
3. 선택 상태가 해당 selection pattern과 일치하는가?
4. 모든 interactive element가 44pt 이상인가?
5. Dynamic Type에서 고정 높이 때문에 텍스트가 잘리지 않는가?
6. loading, empty, error, content 상태가 정의되어 있는가?
7. VoiceOver 레이블에 역할과 상태가 포함되는가?
