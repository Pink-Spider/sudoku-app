# CLAUDE.md — sudoku-app

이 저장소는 "인앱결제 없이 AdMob 광고만으로 수익 내는 글로벌 퍼즐 앱 팩토리"의 1호 앱(클래식 스도쿠)이다.
같은 엔진으로 킬러 스도쿠·카쿠로·Tango 등을 이어서 출시하는 것이 전제이므로,
**앱 코드에 룰 특화 로직을 넣지 말고 `packages/rules_*`와 `puzzle_engine` 경계를 지켜라.**

## 현재 상태 (2026-09-09, bootstrap 통과)

- `./scripts/bootstrap.sh` 통과. `flutter analyze` 이슈 0개, 테스트 42개 전부 통과
  (puzzle_engine 14 / rules_sudoku 19 / core_ads 4 / apps_sudoku 5).
- Android APK, iOS Runner.app 둘 다 debug 빌드 성공. 아직 **실기기에서 실행해 본 적은 없다**
  (광고 3종 실제 노출·UMP 동의 플로우 미확인).
- 툴체인: Flutter 3.44.5 / Dart 3.12.2 (fvm). `google_mobile_ads` 9.1.0.
  6.0.0은 Gradle 9에서 `configurations.all` 제거로 빌드 불가 → 9.x 필수.
- `android/`, `ios/`는 리포에 커밋되어 있다. bootstrap은 없을 때만 `flutter create`로 만든다.
- Firebase 미연결. `core_analytics`는 인터페이스 + Debug/Local 구현만 있다.
- AdMob **앱 ID는 실제 값**(게시자 6329038356545416), **광고 단위 ID는 테스트 값**이다.
  이 조합이 개발 중 정석: 앱 ID가 있어야 UMP 동의/IDFA 메시지가 연결되고,
  테스트 광고 단위여야 자가 클릭이 무효 트래픽이 되지 않는다.
  실제 광고 단위는 스토어 출시 직전 `AppConfig.prod`에서만 교체한다.
- UMP 메시지 2종(GDPR, IDFA) 모두 AdMob 콘솔에 게시 완료. 반영까지 최대 1시간.
- AdMob 콘솔은 `developer.ygpark@gmail.com` 계정에 있다(`ceo@pink-spider.io`가 아님).

## 플랫폼 설정 주의 (재발 방지)

- Flutter 템플릿 기본값과 싸우지 마라. minSdk(24)·iOS deployment target(13.0) 모두
  `google_mobile_ads` 요구사항과 이미 일치한다. build.gradle.kts를 손으로 고쳐도
  `flutter build`가 되돌리고, Podfile의 platform 줄을 풀면 "non-standard Podfile" 경고가 뜬다.
- Info.plist 수정은 `PlistBuddy`로만. `plutil -insert ... -json`은 키가 없을 때
  파일 전체를 그 JSON으로 덮어써서 plist를 날린다(실제로 한 번 당했다).

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

1. 실기기에서 테스트 광고 3종 노출 확인 (배너·전면·리워드), UMP 동의 플로우
2. 통계 화면(난이도별 클리어 수·최고 기록), 데일리 캘린더/스트릭
3. Firebase Analytics + Remote Config 구현체 연결
4. 스토어 리스팅 10개국어, 아이콘/스크린샷, 개인정보처리방침 페이지
5. 2호 룰 패키지(킬러 스도쿠)
