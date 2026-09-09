# 동의 플로우 테스트 (GDPR + ATT)

앱이 광고를 요청하기 전에 두 가지 창을 거친다. 성격이 완전히 달라서
테스트 방법도 다르다.

| | GDPR 동의창 | ATT 프롬프트 |
|---|---|---|
| 무엇 | EEA·영국·스위스 사용자 동의 수집 (Google UMP) | Apple의 IDFA 접근 권한 |
| 어디서 뜨나 | 해당 지역에서만 | iOS 전 지역 |
| 한국에서 | **안 뜬다** (아래 설정 필요) | 그냥 뜬다 |
| 안 뜨면 | 유럽에서 광고 못 받음 | 비개인화 광고만 → eCPM 큰 손실 |

실행 순서와 그 이유는 `apps/sudoku/lib/app/bootstrap.dart`의 `_startAds()`에 있다.
요약하면 **UMP 동의 → ATT → SDK 초기화** 순이고, 세 위치가 전부 의미가 있다.

## 사전 조건

AdMob 콘솔에 메시지가 **게시(Publish)** 되어 있어야 한다. 저장만 하면 초안이라
앱에서 아무것도 안 뜬다. 둘 다 게시 완료된 상태다.

- 개인정보 보호 및 메시지 → 유럽 규정 → `Sudoku Daily GDPR`
- 개인정보 보호 및 메시지 → IDFA 설명 → `Sudoku Daily IDFA`

AdMob 콘솔은 **`developer.ygpark@gmail.com`** 계정에 있다.
`ceo@pink-spider.io`로 로그인하면 AdMob이 없어서 *가입 화면*이 뜨는데,
거기서 진행하면 엉뚱한 새 계정이 만들어지므로 계정을 먼저 확인할 것.

메시지를 방금 게시했다면 **반영까지 최대 1시간** 걸린다.

## GDPR 동의창 테스트

### 왜 그냥은 안 뜨나

UMP는 기기 위치로 동의 필요 여부를 판단하고, 한국은 대상이 아니라서 폼을
건너뛴다. 그래서 디버그 지역을 EEA로 강제해야 한다.

**함정**: 디버그 지역은 **UMP에 등록된 테스트 기기에서만 적용된다.**
기기 해시를 안 넘기면 강제 설정이 조용히 무시되고 아무 일도 일어나지 않는데,
이 증상이 "메시지를 게시 안 함"과 구별되지 않는다. 그래서 해시가 없으면
부트스트랩이 로그로 경고하도록 해뒀다.

### 순서

dev 플레이버는 이미 `forceEeaConsent: true`와 `resetConsentOnLaunch: true`로
설정돼 있다. 기기 해시만 넘기면 된다.

```bash
cd apps/sudoku

# 1) 일단 실행. 네이티브 로그에서 addTestDeviceHashedId 가 들어간 줄을 찾는다.
flutter run -t lib/main_dev.dart
```

로그는 대략 이렇게 생겼다(iOS는 Xcode 콘솔, Android는 logcat에도 나온다).

```
<UMP SDK> To enable debug mode for this device, set:
ConsentDebugSettings.Builder().addTestDeviceHashedId("ABCD1234...")
```

```bash
# 2) 그 해시를 넘겨 다시 실행하면 동의창이 뜬다.
flutter run -t lib/main_dev.dart \
  --dart-define=UMP_TEST_DEVICE_IDS=ABCD1234...

# 기기가 여럿이면 쉼표로 나열
flutter run -t lib/main_dev.dart \
  --dart-define=UMP_TEST_DEVICE_IDS=ABCD1234...,EF567890...
```

해시를 소스에 적지 않고 `--dart-define`으로 넘기는 이유는 기기 ID를 실수로
커밋하지 않기 위해서다.

### 확인할 것

동의창에 **Consent**와 **Do not consent** 버튼이 나란히 있고 아래에
**Manage options**가 있어야 한다. 거부를 동의만큼 쉽게 만드는 게 GDPR 요구사항이라
전 국가에 거부 버튼을 켜뒀다. 기기 언어를 한국어·일본어·독일어로 바꾸면
해당 언어로 나와야 한다(en/ko/ja/de 4개 언어 게시됨).

동의 철회도 확인할 것: 홈 화면 우측 상단 **개인정보 버튼** → UMP 개인정보 옵션 폼.
동의 요구 지역이 아니면 아무 일도 안 일어나는 게 정상이다.

### 반복 테스트

dev는 실행할 때마다 저장된 동의를 지운다(`resetConsentOnLaunch`). 이게 없으면
동의창이 한 번 뜨고 다시는 안 나온다. prod에서는 꺼져 있다.

## ATT 프롬프트 테스트

지역 설정이 필요 없다. iOS 기기에 설치하고 실행하면 첫 프레임 직후에 뜬다.

IDFA 메시지를 게시했으므로 **Google 설명 화면이 먼저** 나오고
(`Our app wants to stay free for you` → Continue), 그다음 iOS 시스템 창이 뜬다.

문구는 `apps/sudoku/tool/infoplist/<lang>.strings`에 있고
`tool/gen_infoplist_strings.sh`가 `ios/Runner/<lang>.lproj/`로 복사한다.

### 다시 띄우려면

ATT는 **앱 생애주기에 한 번만** 뜬다. 다시 보려면 앱을 삭제 후 재설치하거나,
설정 → 개인정보 보호 및 보안 → 추적에서 토글을 조작한다.

주의: 앱이 화면에 올라오기 전에 요청하면 iOS가 **조용히 거부**하고 그 거부는
되돌릴 수 없다. `_startAds()`가 `endOfFrame`을 기다리는 이유이므로,
이 순서를 바꾸지 말 것.

## 안 될 때

**아무 창도 안 뜬다** — 해시를 안 넘겼을 가능성이 가장 크다. 로그에서
`[consent] forcing EEA but no UMP test device id given` 경고를 확인한다.
그다음은 게시 여부와 반영 시간(최대 1시간).

**GDPR 창은 뜨는데 광고가 안 나온다** — 거부했다면 정상이다.
`[ads] consent withheld, ads disabled for this session` 로그를 확인한다.

**ATT 창이 안 뜬다** — 이미 한 번 응답했을 가능성. 앱 삭제 후 재설치.
iOS 시뮬레이터는 IDFA 동작이 실기기와 다르므로 실기기로 확인할 것.

**배너만 안 보인다** — SDK 초기화 전에 그려졌을 수 있는데, `AdBanner`가
백오프로 최대 5회 재시도하므로 몇 초 기다려 본다.

## 관련 파일

- `apps/sudoku/lib/app/bootstrap.dart` — 실행 순서 (`_startAds`)
- `apps/sudoku/lib/app/app_config.dart` — 플레이버별 테스트 설정
- `packages/core_ads/lib/src/consent_manager.dart` — UMP + ATT 호출
- `apps/sudoku/tool/infoplist/` — ATT 문구 (4개 언어)
- 개인정보처리방침: <https://pink-spider.github.io/sudoku-privacy/>
