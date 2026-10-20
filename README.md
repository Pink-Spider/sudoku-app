# sudoku-app — puzzle app factory (1호: 클래식 스도쿠)

[![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.6+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![AdMob](https://img.shields.io/badge/AdMob-EA4335?logo=googleadmob&logoColor=white)](https://admob.google.com)
![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-lightgrey?logo=android&logoColor=white)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue)](LICENSE)

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
- 개인정보처리방침: <https://pink-spider.github.io/sudoku-privacy/>
  (저장소 `Pink-Spider/sudoku-privacy`, en+ko. 수집 항목이 바뀌면 **여기부터** 고칠 것 —
  AdMob GDPR 메시지와 양쪽 스토어 리스팅이 이 URL을 참조한다)
- 이름 후보 중복 확인: `scripts/check_app_name.sh "이름"` — 미국 스토어 게시앱만 보므로
  예약된 미출시 이름은 못 잡는다. 후보를 2~3개 준비해 둘 것.

## 광고 동의 흐름 (건드리기 전에 읽을 것)

시작 순서는 `apps/sudoku/lib/app/bootstrap.dart`의 `_startAds()`에 있고, 순서가
그 자체로 요구사항이다.

1. **UMP 동의** — Google이 ATT보다 먼저 처리하도록 요구한다.
2. **ATT 권한** — 첫 프레임이 그려진 뒤에. 앱이 아직 active가 아닐 때 요청하면
   iOS가 조용히 거부하고, 그 거부는 되돌릴 수 없다. `runApp` 전에 하면 안 되는 이유.
   `google_mobile_ads`는 ATT를 처리하지 않는다 — UMP는 GDPR용이고 ATT는 IDFA용으로
   별개다. ATT 없이는 iOS가 비개인화 광고만 받아서 eCPM이 크게 깎인다.
3. **SDK 초기화** — 첫 광고 요청이 두 답을 모두 알고 나가도록 마지막에.

배너는 이 과정이 끝나기 전에 그려질 수 있어서 `AdBanner`가 백오프 재시도를 한다.

동의창을 실제로 띄워 확인하는 방법은 [docs/consent-testing.md](docs/consent-testing.md)에
있다. 한국에서는 GDPR 창이 기본적으로 안 뜨고, 테스트 기기 해시가 없으면 조용히
넘어가서 "게시가 안 된 것"처럼 보이므로 그 문서를 먼저 볼 것.

## 출시 전 체크리스트

- [ ] AdMob 콘솔에서 앱 등록 → 실제 앱 ID + 광고 단위 3종(배너/전면/리워드) 발급
- [ ] AdMob 앱 ID 교체: `scripts/bootstrap.sh` 상단 두 변수 수정 후 `./scripts/bootstrap.sh`
      (재실행하면 기존 값을 덮어쓴다 — 안 바뀌면 그게 버그다)
- [x] 개인정보처리방침 페이지 (GDPR 메시지 게시의 선행 조건)
- [x] AdMob GDPR 메시지 "Sudoku Daily GDPR" 게시 (앱 2개, en+ko/ja/de,
      거부 버튼 전 국가 사용, 정책 URL 연결)
- [x] AdMob IDFA(ATT) 메시지 "Sudoku Daily IDFA" 게시 (iOS, en+ko/ja/de)
- [ ] 광고 단위 ID 교체 (`apps/sudoku/lib/app/app_config.dart` → `AppConfig.prod`)
      — 이건 **스토어 출시 직전에만**. 그 전까지는 테스트 단위 ID를 유지한다.
- [ ] 내 기기를 AdMob 테스트 기기로 등록 (실광고 자가 클릭 = 무효 트래픽, 계정 정지 사유)
- [ ] App Store Connect 앱 개인정보(App Privacy) 설문 — 광고 SDK가 식별자를 수집하므로 필수
- [ ] `app-ads.txt`를 도메인에 배포 (미설정 시 광고 단가 하락)
- [ ] Info.plist `SKAdNetworkItems` 전체 목록 추가
- [ ] Firebase 프로젝트 연결 후 Analytics/Remote Config 구현체를 `providers.dart`에 연결
- [ ] 스토어 리스팅 10개국어 이상 현지화
- [ ] 미디에이션(AppLovin/Unity/Meta)은 일 노출 수만 회 넘긴 뒤 추가

## 스토어 제출

문구·설문 답변·에셋 생성 절차는 [docs/store-listing.md](docs/store-listing.md).
Android 서명은 [docs/android-signing.md](docs/android-signing.md) —
키스토어는 리포에 없으니 백업 여부를 먼저 확인할 것.

```bash
cd apps/sudoku
tool/screenshots.sh          # 4개 언어 × 4컷, 1320x2868 (ASC 6.9" 규격)
tool/gen_store_assets.sh     # Play 아이콘 512 + 피처 그래픽 1024x500
```

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

## 라이선스

[GPL-3.0](LICENSE). Copyright (c) 2026 Yungoo Park (Pink Spider).
