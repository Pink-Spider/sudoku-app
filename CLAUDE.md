# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

이 저장소는 "인앱결제 없이 AdMob 광고만으로 수익 내는 글로벌 퍼즐 앱 팩토리"의 1호 앱(클래식 스도쿠)이다.
같은 엔진으로 킬러 스도쿠·카쿠로·노노그램 등을 이어서 출시하는 것이 전제이므로,
**앱 코드에 룰 특화 로직을 넣지 말고 `packages/rules_*`와 `puzzle_engine` 경계를 지켜라.**

## 현재 상태 (2026-10-19)

- `1.0.0+10`을 2026-09-10에 Play(프로덕션, 1차 거부 후 재제출)와 App Store(심사) 양쪽에 제출했다.
  거부 사유·수정 내역·콘솔 상태는 `docs/store-listing.md` 하단에 있다.
- `flutter analyze` 이슈 0, 테스트 43개 전부 통과 (puzzle_engine 15 / rules_sudoku 19 / core_ads 4 / apps/sudoku 5).
- 툴체인: Flutter 3.44.5 / Dart 3.12.2 (fvm default). `google_mobile_ads` 9.1.0 —
  6.0.0은 Gradle 9에서 `configurations.all` 제거로 빌드 불가라 9.x 필수.
- Firebase 미연결. `core_analytics`는 인터페이스 + Debug/Local 구현만 있다.
- 실기기에서 광고 3종 실제 노출·UMP 동의 플로우를 확인한 기록은 아직 없다.
- **`packages/puzzle_engine/lib`는 형제 리포 `../nonogram-app`의 같은 경로와 바이트 단위로 동일해야 한다.**
  pub으로 공유하는 게 아니라 복사본이라, 한쪽을 고치면 반드시
  `diff -r packages/puzzle_engine/lib ../nonogram-app/packages/puzzle_engine/lib`로 맞출 것.
  2026-09-15에 `isCorrect` 훅이 한쪽에만 있어 조용히 갈라졌던 적이 있다.

## 명령

Dart pub workspace(루트 `pubspec.yaml`의 `workspace:`). melos 안 씀. 루트에서 `flutter pub get` 한 번.

```bash
./scripts/bootstrap.sh                  # 최초 1회, idempotent: pub get → 플랫폼 패치 → 아이콘 → gen-l10n → analyze → 전체 테스트
flutter analyze                         # 루트에서. analysis_options는 루트 하나(strict-casts/inference/raw-types)
(cd apps/sudoku && flutter gen-l10n)    # lib/l10n/generated/ 는 gitignore. 새 클론·ARB 수정 후 analyze/test 전에 필수
```

테스트 (패키지별로 따로 돈다):

```bash
(cd packages/puzzle_engine && dart test)
(cd packages/rules_sudoku && dart test)
(cd packages/core_ads && flutter test)
(cd apps/sudoku && flutter test)
# 단일 파일 / 단일 케이스
(cd packages/rules_sudoku && dart test test/sudoku_generator_test.dart -n "daily seed")
(cd apps/sudoku && flutter test test/game_controller_test.dart --plain-name "<테스트 이름>")
```

실행:

```bash
cd apps/sudoku
flutter run -t lib/main_dev.dart        # 테스트 광고, EEA 강제, 동의 매번 리셋. main.dart == dev
flutter run -t lib/main_dev.dart --dart-define=UMP_TEST_DEVICE_IDS=<해시>   # 동의창을 보려면 필수 (docs/consent-testing.md)
```

릴리스·스토어:

```bash
(cd apps/sudoku/android && fastlane internal)      # flutter build appbundle + Play 업로드(draft). production 레인도 동일
scripts/build_ios.sh [build-number]                # ipa 빌드 → Transporter로 Deliver
scripts/upload_ios.sh [build-number]               # ipa 빌드 → altool 검증·업로드 (ASC_KEY_ID / ASC_ISSUER_ID 필요)
(cd apps/sudoku && tool/screenshots.sh)            # 로케일 4개 × 4컷. 인자로 "iPad Pro 13-inch (M4)" 등 시뮬레이터 지정
(cd apps/sudoku && tool/gen_icons.sh && tool/gen_store_assets.sh)
```

위 릴리스 경로 셋은 모두 `tool/ad_units.sh`로 실제 광고 단위 ID를 `--dart-define`으로 주입한다.
직접 `flutter build`를 칠 때만 `$(tool/ad_units.sh)`를 붙이면 된다.
빌드 번호(`pubspec.yaml`의 `+N`)는 Play도 ASC도 재사용 불가라 재업로드마다 올린다.

## 구조

```
packages/puzzle_engine   순수 Dart. GridPuzzle(불변), GameSession(가변: undo/메모/실수/힌트/직렬화), PuzzleRule, DailySeed
packages/rules_sudoku    순수 Dart. SudokuSolver(비트마스크 백트래킹, 유일해), SudokuLogicSolver(기법별 레벨 1~4 + 힌트), SudokuGenerator, SudokuRule
packages/core_ads        Flutter. AdService 추상화 + AdMobAdService/NoopAdService, ConsentManager(UMP+ATT), AdBanner, InterstitialGate
packages/core_analytics  Flutter. AnalyticsService/RemoteConfigService 인터페이스 + 이벤트·키 상수(AnalyticsEvents, RewardPlacement, RemoteConfigKeys)
packages/core_ui         테마, PuzzleColors(ThemeExtension), RewardButton 등
apps/sudoku              Riverpod 2(Notifier). features/{home,game}. 보드는 CustomPainter 하나
```

### 앱 부팅과 DI

- 플레이버는 엔트리포인트 차이뿐이다: `main_dev.dart`/`main_prod.dart`가 `AppConfig.dev()`/`.prod()`를 `bootstrap()`에 넘긴다.
  플레이버를 직접 보는 코드는 `app_config.dart` 하나여야 한다.
- `bootstrap()`은 `ProviderScope.overrides`로 `appConfig / adService / consentManager / sharedPreferences`
  네 provider를 채운다. `providers.dart`의 기본값은 throw라서 override를 빠뜨리면 즉시 터진다.
  단위 테스트(`test/test_overrides.dart`)와 스크린샷 하네스(`integration_test/screenshots_test.dart`)는
  bootstrap을 거치지 않고 같은 override를 직접 구성한다 — 그래서 광고 없음·시드 고정·로케일 지정이 된다.
- `_startAds()`의 순서 **UMP 동의 → ATT → SDK 초기화**(첫 프레임 이후)는 요구사항이다. 바꾸지 말 것.
  이유는 README의 "광고 동의 흐름"과 `docs/consent-testing.md`.
- 룰 교체 지점은 `puzzleRuleProvider` 하나. 2호 앱은 `apps/sudoku`를 복제하고 이 provider만 바꾼다.

### 게임 루프

- `GameSession`(puzzle_engine)이 보드·메모·undo·실수·힌트·JSON 직렬화를 전담한다.
  `GameController`(Riverpod `Notifier`)는 그 위에 타이머, 10초마다 저장, 광고 게이팅, 애널리틱스만 얹는다.
  규칙 변경은 세션 쪽, UI·광고는 컨트롤러 쪽.
- 정답 판정은 `PuzzleRule.isCorrect()` 훅(기본값 완전 일치)을 거친다. 노노그램의 X표시 같은
  "주석 값"이 실수로 집계되지 않게 하려고 있고, `place()`와 `isSolved` 둘 다 이 훅을 쓴다.
- 퍼즐 생성은 `compute()`로 백그라운드 아이솔레이트에서 돈다.
- 무료 힌트 카운터는 의도적으로 저장하지 않는다(앱 재시작이 무료 힌트가 되는 걸 막기 위해).
- 데일리 = `DailySeed.forDate(now, salt: 1)` → 결정론 생성. 서버 없이 전 세계가 같은 퍼즐을 받는다.

### 난이도

라벨은 클루 수가 아니라 `SudokuGenerator.rate()`(로직 솔버가 필요로 한 최고 기법 레벨)로 정한다.
생성기 파일을 바꾸면 데일리 퍼즐이 바뀌므로 `algorithmVersion`을 올려라.

### 광고

- 앱은 `AdService`만 쓴다. `google_mobile_ads` 직접 import 금지. `NoopAdService`가 테스트·스크린샷·웹용.
- 전면은 `InterstitialGate`가 N번째 이벤트·최소 간격·세션 초반 유예로 제어하고 값은 `RemoteConfigKeys.defaults`에서 온다.
  **퍼즐 종료 이벤트에서만 `maybeShowInterstitial()`**. 게임 중 절대 금지.
- 리워드 배치는 `RewardPlacement`에 4개(힌트, 실수 소진 이어하기, 데일리 추가, 1시간 광고 제거)가 선언돼 있지만
  **구현은 3개**다. `extraDaily`는 예약만. 새 훅은 여기에 먼저 추가한다.
- 광고 단위 ID는 리포에 없다. `~/.pink-spider/secrets/sudoku/ad-units.env` → `tool/ad_units.sh` → `--dart-define`.
  없으면 prod가 **조용히 테스트 단위로 폴백**하고(앱은 돌고 수익만 0) 릴리스 스크립트가 거기서 막는다. `docs/ad-units.md`.
- **자가 클릭 방지**: `--dart-define=UMP_TEST_DEVICE_IDS=<해시>`를 넘긴 기기는
  `MobileAds.updateRequestConfiguration`에 등록되어 실제 단위에서도 테스트 광고만 받는다.
  실기기로 prod를 돌릴 땐 반드시 넘길 것 — 실제 광고를 직접 탭하면 무효 트래픽으로 AdMob 계정이 정지될 수 있다.

### 문자열

전부 ARB(`apps/sudoku/lib/l10n/app_{en,ko,ja,de}.arb`). 하드코딩 금지.
앱 내 타이틀은 ARB의 `appTitle`이고 `AppConfig.appName`은 어디서도 안 쓰는 죽은 필드다.
iOS ATT 문구는 `tool/infoplist/*.strings`가 원본이고 `tool/gen_infoplist_strings.sh`가 `ios/`로 복사한다
(`ios/`를 재생성해도 번역이 안 날아가게 하려고 원본을 밖에 뒀다).

## 플랫폼 설정 주의 (재발 방지)

- `android/`, `ios/`는 커밋돼 있다. bootstrap은 없을 때만 `flutter create`로 만든다.
- minSdk는 Flutter 템플릿 기본값(24)으로 둔다. build.gradle.kts를 손으로 고쳐도 `flutter build`가 되돌린다.
- iOS deployment target은 **15.0**이다(ASC가 15 미만 업로드를 거부, 경고 90068). 템플릿은 13.0을 내놓고
  `flutter build`가 pbxproj를 재생성하지 않으므로, bootstrap이 pbxproj와 Podfile 둘 다 sed로 패치한다.
  `ios/`를 다시 만들었으면 bootstrap을 다시 돌릴 것.
- Info.plist 수정은 `PlistBuddy`로만. `plutil -insert ... -json`은 키가 없을 때
  파일 전체를 그 JSON으로 덮어써서 plist를 날린다(실제로 한 번 당했다).
- R8: 릴리스는 minify가 켜져 있다. `android/app/proguard-rules.pro`의 androidx.work/room keep 규칙이 없으면
  **Dart가 뜨기도 전에 앱이 죽는다**. debug는 R8을 안 돌려 재현이 안 된다.

## 릴리스 빌드는 반드시 실기기/에뮬레이터에서 확인

`flutter analyze`와 테스트가 통과해도 debug 빌드는 R8을 돌리지 않아서 릴리스에서만 죽는 부류를 못 잡는다.
2026-09-10 Play 거부가 정확히 이것이었다. 제출 전에 항상:

```bash
cd apps/sudoku
flutter build apk --release -t lib/main_prod.dart $(tool/ad_units.sh)
adb install -r build/app/outputs/flutter-apk/app-release.apk
adb logcat -c && adb shell am start -n io.pinkspider.sudoku/.MainActivity
adb shell pidof io.pinkspider.sudoku    # 비어 있으면 죽은 것
adb logcat -d | grep -A20 "FATAL EXCEPTION"
```

런처의 아이콘·앱 이름도 눈으로 확인할 것. 스토어 등록정보와 다르면 "혼동을 야기하는 주장"으로 거부된다.
`tool/gen_icons.sh`가 iOS와 Android를 모두 만든다(예전엔 iOS만 만들어서 Flutter 기본 아이콘이 배포됐다).

## 비밀·계정

- 비밀 4종(업로드 키스토어, key.properties, Play API 서비스 계정 키, ad-units.env)은 리포가 아니라
  `~/.pink-spider/secrets/sudoku/`에 있다. gitignore만으로는 `git clean -xdf`에 날아가서 밖으로 뺐다.
  `key.properties`가 없으면 릴리스가 **디버그 키로 서명되고 빌드는 성공**한다(Play가 거부할 때까지 모른다).
  `keytool -printcert -jarfile <aab>`로 확인. `docs/android-signing.md`.
- Play 업로드는 fastlane(`docs/play-api-automation.md`). `release_status: draft`가 기본이라 실제 공개는 콘솔에서 누른다.
- **AdMob 콘솔은 `developer.ygpark@gmail.com`**, **Play Console·gcloud 관리자는 `ceo@pink-spider.io`**다.
  developer 계정은 Play에서 "새 앱을 만들려면 권한이 필요합니다"로 막히고, ceo 계정으로 AdMob에 들어가면
  가입 화면이 떠서 엉뚱한 계정이 만들어진다. 둘 다 같은 Pink Spider 개발자 계정(8732421573193870105).
- 계정 전체에 2026-09-30 기한의 Android 개발자 인증 요구가 걸려 있었다. 기한이 지났으니 처리됐는지 확인할 것.
- UMP 메시지 2종(GDPR, IDFA)은 AdMob 콘솔에 게시 완료. 한국에서는 기기 해시 없이 동의창이 안 뜬다(`docs/consent-testing.md`).
- `app-ads.txt`는 도메인당 하나이고 이미 배포돼 있다(`pub-6329038356545416`). 앱마다 만들 필요 없고,
  대신 양쪽 스토어 리스팅의 개발자 웹사이트를 `https://pink-spider.github.io`로 넣어야 크롤러가 찾는다.
- 스토어 문구와 개인정보 설문 답변은 `docs/store-listing.md`. 수집 항목이 바뀌면
  개인정보처리방침(`Pink-Spider/sudoku-privacy`, AdMob 메시지와 양쪽 스토어가 참조)부터 고친다.

## 다음 단계 후보 (우선순위 순)

1. 실기기에서 테스트 광고 3종 노출 확인(배너·전면·리워드), UMP 동의 플로우
2. AdMob "광고 게재가 제한됨" 해제 — 앱 목록에서 Play/App Store 리스팅 연결. 안 하면 실제 단위가 채워지지 않는다
3. 통계 화면(난이도별 클리어 수·최고 기록), 데일리 캘린더/스트릭
4. Firebase Analytics + Remote Config 구현체 연결
5. 스토어 리스팅 10개국어 확장
6. 2호 룰 패키지 — 노노그램은 별도 리포 `../nonogram-app`에서 진행 중이며 `puzzle_engine`을 공유한다
