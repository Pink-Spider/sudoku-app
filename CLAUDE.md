# CLAUDE.md — sudoku-app

이 저장소는 "인앱결제 없이 AdMob 광고만으로 수익 내는 글로벌 퍼즐 앱 팩토리"의 1호 앱(클래식 스도쿠)이다.
같은 엔진으로 킬러 스도쿠·카쿠로·Tango 등을 이어서 출시하는 것이 전제이므로,
**앱 코드에 룰 특화 로직을 넣지 말고 `packages/rules_*`와 `puzzle_engine` 경계를 지켜라.**

## 현재 상태 (2026-09-09, 스캐폴딩 직후)

- 코드는 Cowork 세션에서 작성됐고 **아직 Flutter 툴체인으로 한 번도 빌드/테스트되지 않았다**
  (그 환경에서 pub.dev·Dart SDK 접근이 막혀 있었음). 스도쿠 생성/솔버/난이도 알고리즘만 Python 포트로 검증됨.
- 따라서 첫 할 일: `./scripts/bootstrap.sh` 실행 → analyze/test 에러를 잡는다. 컴파일 에러가 몇 개 나올 수 있다는 전제로 시작할 것.
- `android/`, `ios/`는 bootstrap이 `flutter create`로 생성한다(리포에 없음).
- Firebase 미연결. `core_analytics`는 인터페이스 + Debug/Local 구현만 있다.
- AdMob은 전부 Google 테스트 ID. 실제 ID 교체 지점은 README 체크리스트 참고.

## 구조

- Dart pub workspace (루트 `pubspec.yaml`의 `workspace:`). melos 안 씀. 루트에서 `flutter pub get` 한 번.
- `packages/puzzle_engine` 순수 Dart. `GridPuzzle`(불변 퍼즐), `GameSession`(가변 세션: undo/메모/실수/힌트/직렬화), `PuzzleRule`(룰 인터페이스), `DailySeed`.
- `packages/rules_sudoku` 순수 Dart. `SudokuSolver`(비트마스크 백트래킹, 유일해 카운트), `SudokuLogicSolver`(naked/hidden single, naked pair, pointing, box-line → 난이도 레벨 1~4 + 힌트), `SudokuGenerator`(시드 결정론, 180° 대칭 제거, 등급 불일치 시 재시도 최대 24회), `SudokuRule`.
- `packages/core_ads` Flutter. 앱은 `AdService`만 쓴다(`google_mobile_ads` 직접 import 금지). `InterstitialGate`가 전면 빈도 규칙 전담.
- `packages/core_analytics` Flutter. `AnalyticsService`/`RemoteConfigService` + 이벤트 이름 상수(`AnalyticsEvents`, `RewardPlacement`, `RemoteConfigKeys`).
- `packages/core_ui` 테마·`PuzzleColors`(ThemeExtension)·공통 위젯.
- `apps/sudoku` Riverpod 2 (`Notifier`). `GameController`가 `GameSession`을 감싸고 타이머/저장/광고 게이팅 담당. 보드는 `CustomPainter` 하나.
- l10n: `flutter gen-l10n`, ARB는 `apps/sudoku/lib/l10n/`, 생성물은 `lib/l10n/generated/`(gitignore). en/ko/ja/de.

## 규칙

- 난이도 라벨은 클루 수가 아니라 `SudokuGenerator.rate()`(로직 솔버 최고 기법)로 결정한다. 생성기 파일을 바꾸면 데일리 퍼즐이 바뀌므로 `algorithmVersion`을 올려라.
- 리워드 훅은 4개로 고정: 힌트(무료 1회 후), 실수 소진 이어하기, 데일리 추가, 1시간 광고 제거. 새 훅은 `RewardPlacement`에 먼저 추가.
- 전면 광고는 퍼즐 종료 이벤트에서만 `maybeShowInterstitial()`로. 게임 중 절대 금지.
- 문자열은 전부 ARB. 하드코딩 금지.
- 새 앱/룰 추가 절차는 README 하단.

## 명령

```bash
./scripts/bootstrap.sh                          # 최초 1회 (idempotent)
flutter pub get                                 # 루트
(cd packages/rules_sudoku && dart test)
(cd apps/sudoku && flutter gen-l10n && flutter test)
(cd apps/sudoku && flutter run -t lib/main_dev.dart)
```

## 다음 단계 후보 (우선순위 순)

1. bootstrap 통과시키기 (컴파일/린트 수정)
2. 실기기에서 테스트 광고 3종 노출 확인 (배너·전면·리워드), UMP 동의 플로우
3. 통계 화면(난이도별 클리어 수·최고 기록), 데일리 캘린더/스트릭
4. Firebase Analytics + Remote Config 구현체 연결
5. 스토어 리스팅 10개국어, 아이콘/스크린샷, 개인정보처리방침 페이지
6. 2호 룰 패키지(킬러 스도쿠)
