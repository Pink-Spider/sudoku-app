# sudoku-app — puzzle app factory (1호: 클래식 스도쿠)

인앱결제 없이 AdMob 광고만으로 운영하는 글로벌 퍼즐 앱. 공통 엔진 + 룰 패키지 구조라
룰 패키지만 추가하면 킬러 스도쿠·카쿠로 등 다음 앱을 같은 코드베이스로 출시할 수 있다.

## 구조 (Dart pub workspace)

```
packages/
  puzzle_engine/    룰 비의존 프레임워크: GridPuzzle, GameSession(undo/메모/실수/힌트), DailySeed
  rules_sudoku/     스도쿠 규칙: 비트마스크 백트래킹 솔버(유일해 검증), 사람식 로직 솔버(난이도 산정·힌트), 시드 기반 생성기
  core_ads/         AdService 추상화 + AdMob 구현, UMP 동의, 적응형 배너, InterstitialGate(빈도 제어)
  core_analytics/   AnalyticsService / RemoteConfigService 추상화 (Firebase는 앱별로 나중에 연결)
  core_ui/          테마, PuzzleColors, 공통 위젯
apps/
  sudoku/           Flutter 앱 (Riverpod, CustomPainter 보드, 데일리 챌린지, 리워드 훅, 4개 언어)
```

## 시작하기 (Mac)

```bash
./scripts/bootstrap.sh        # flutter pub get → android/ios 생성 → AdMob 테스트 앱ID 패치 → gen-l10n → analyze → test
cd apps/sudoku
flutter run -t lib/main_dev.dart
```

`main_dev.dart`(테스트 광고 ID) / `main_prod.dart`(실제 ID 자리) 두 엔트리포인트로 플레이버를 나눈다.

## 광고 설계 (핵심)

- 리워드: 힌트(무료 1회 후 광고), 실수 소진 시 이어하기, "광고 보고 1시간 광고 제거"
- 전면: 퍼즐 종료 후에만, `InterstitialGate`가 N번째 이벤트·최소 간격·세션 초반 유예로 제어 (리모트 컨피그 키는 `RemoteConfigKeys`)
- 배너: 하단 적응형, 광고 제거 시간 동안 숨김
- 앱 코드는 `google_mobile_ads`를 직접 import하지 않는다 — `AdService`만 사용

## 스토어 아이덴티티

- App Store 이름: **Sudoku Daily: Logic Puzzle** (26자, 상한 30자)
- 부제: Daily challenge & smart hints
- 기기 표시 이름: Sudoku Daily / 번들 ID: `io.pinkspider.sudoku`
- 이름 후보 중복 확인: `scripts/check_app_name.sh "이름"` — 미국 스토어 게시앱만 보므로
  예약된 미출시 이름은 못 잡는다. 후보를 2~3개 준비해 둘 것.

## 출시 전 체크리스트

- [ ] AdMob 앱 ID 교체 (`scripts/bootstrap.sh` 상단 변수 → AndroidManifest / Info.plist)
- [ ] 광고 단위 ID 교체 (`apps/sudoku/lib/app/app_config.dart` → `AppConfig.prod`)
- [ ] AdMob 콘솔에서 GDPR 메시지 + iOS IDFA 메시지 설정 (UMP)
- [ ] Info.plist `SKAdNetworkItems` 전체 목록 추가
- [ ] Firebase 프로젝트 연결 후 Analytics/Remote Config 구현체를 `providers.dart`에 연결
- [ ] 스토어 리스팅 10개국어 이상 현지화
- [ ] 미디에이션(AppLovin/Unity/Meta)은 일 노출 수만 회 넘긴 뒤 추가

## TestFlight

사전 준비(최초 1회): App Store Connect에 앱 레코드를 웹에서 직접 만든다.
ASC API에는 앱 생성 엔드포인트가 없어서 Transporter로도 CLI로도 못 만든다.

```bash
scripts/build_ios.sh [build-number]      # 빌드 후 Finder에서 .ipa 열어줌 → Transporter로 Deliver
```

버전당 빌드 번호는 재사용할 수 없다. 재업로드할 때마다 인자로 올리거나
`apps/sudoku/pubspec.yaml`의 `+N`을 올릴 것.

CLI로 자동화하려면(나중에 CI로 옮길 때) API 키 방식도 있다:

```bash
scripts/upload_ios.sh [build-number]     # 빌드 → 검증 → 업로드
```

App Manager 역할 API 키를 `~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8`에
두고 `ASC_KEY_ID`·`ASC_ISSUER_ID` export.

## 다음 앱 추가하는 법

1. `packages/rules_<name>/`에 `PuzzleRule` 구현(생성기·솔버·힌트)
2. `apps/<name>/`를 `apps/sudoku` 복제 후 `puzzleRuleProvider`만 교체
3. 루트 `pubspec.yaml`의 `workspace:` 목록에 추가
