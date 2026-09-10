# 스토어 등록 정보 (ASC + Play Console)

콘솔에 붙여넣을 문구와 설문 답변. **앱 동작이 바뀌면 여기부터 고치고**
개인정보처리방침(<https://pink-spider.github.io/sudoku-privacy/>)과 함께 맞출 것.

## 에셋

| 파일 | 크기 | 어디에 |
|---|---|---|
| `apps/sudoku/build/screenshots/<locale>-*.png` | 1320×2868 | ASC 6.9" / Play 폰 |
| `apps/sudoku/build/screenshots-tablet/<locale>-*.png` | 1668×2420 | Play 7"·10" 태블릿 (**필수**) |
| `apps/sudoku/build/screenshots-ipad13/<locale>-*.png` | 2064×2752 | ASC iPad 13" (**필수**) |
| `apps/sudoku/build/store/icon-512.png` | 512×512 | Play 아이콘 |
| `apps/sudoku/build/store/feature-graphic.png` | 1024×500 | Play 피처 그래픽 (필수) |
| 앱 아이콘 1024 | 번들 내장 | ASC가 빌드에서 자동 추출 |

생성:

```bash
cd apps/sudoku
tool/screenshots.sh                          # 폰: 1320x2868
tool/screenshots.sh "iPad Pro 11-inch (M4)"  # Play 태블릿: 1668x2420
tool/screenshots.sh "iPad Pro 13-inch (M4)"  # ASC iPad: 2064x2752
tool/gen_store_assets.sh                     # Play 아이콘 + 피처 그래픽
```

**Play는 7인치·10인치 태블릿 스크린샷이 둘 다 필수다**(폰만으로는 게시가 막힌다).
**ASC도 iPad 스크린샷이 필수다** — `TARGETED_DEVICE_FAMILY = "1,2"`(iPhone+iPad)이라
iPad 13" 슬롯을 채워야 심사에 넣을 수 있다. 이 슬롯은 2064×2752만 받으므로
Play용 11인치 샷(1668×2420)은 쓸 수 없다. 한 번 올리면 나머지 iPad 크기에는
자동 적용된다(iPhone 6.9" → 6.5"/6.3"/… 도 마찬가지).
같은 하네스에 기기만 바꿔 찍으면 되고, `takeScreenshot`은 Flutter 표면만 캡처하므로
iOS 상태바가 안 들어간다. 그래서 iOS 시뮬레이터로 찍어도 Play에 그대로 쓸 수 있다.

스크린샷은 시드 고정이라 다시 찍어도 같은 보드가 나온다. 화면이 바뀌어서
달라진 것인지 구분하기 위해서다. 광고는 `NoopAdService`라 테스트 광고가
찍히지 않는다(테스트 광고가 박힌 스크린샷은 심사에서 문제가 된다).

## 공통

- 번들 ID / 패키지명: `io.pinkspider.sudoku`
- 지원 URL: <https://pink-spider.github.io/sudoku-privacy/> (전용 페이지 생기면 교체)
- 개인정보처리방침 URL: <https://pink-spider.github.io/sudoku-privacy/>
- **개발자 웹사이트: `https://pink-spider.github.io`** — app-ads.txt가 이 값으로
  연결된다. ASC는 마케팅 URL, Play는 스토어 등록정보의 웹사이트 필드.
  비워 두면 app-ads.txt가 있어도 크롤러가 못 찾아 단가가 떨어진다.
- 카테고리: 게임 → 퍼즐 (Play) / 게임, 퍼즐·보드 (ASC)
- 저작권: `2026 Yungoo Park`
- 가격: 무료, 인앱결제 없음, 광고 포함

## App Store Connect

**이름 (30자)** `Sudoku Daily: Logic Puzzle`
**부제 (30자)** `Daily challenge & smart hints`

**키워드 (100자, 쉼표 구분, 공백 없이)**

```
sudoku,daily,logic,puzzle,number,brain,offline,killer,classic,training,solver,hint,zen,free
```

이름·부제에 이미 있는 단어는 키워드에 중복하지 않는 게 원칙이지만, Apple이
이름의 단어도 색인하므로 `sudoku`만 안전하게 남겼다.

**프로모션 텍스트 (170자, 심사 없이 교체 가능)**

```
A fresh daily puzzle, four difficulty levels, and hints that explain the
logic instead of just handing you the answer. No sign-up, plays offline.
```

**설명**

```
Sudoku Daily is classic 9x9 sudoku, built to be played every day.

A NEW PUZZLE EVERY DAY
Everyone gets the same daily challenge, so you can compare how you did.

FOUR DIFFICULTIES
Easy, Medium, Hard and Expert. Difficulty is measured by the solving
techniques a puzzle actually requires, not by how many numbers are
missing, so a level always feels the way it should.

HINTS THAT TEACH
Stuck? A hint points at the cell and explains why that number belongs
there, so you finish the puzzle knowing something you did not know
before.

BUILT FOR COMFORTABLE PLAY
- Pencil marks with automatic clean-up as you solve
- Undo, erase, and mistake tracking
- Row, column and box highlighting
- Light and dark themes
- Your game is saved automatically, so you can stop mid-puzzle

FREE AND OFFLINE
No account, no sign-up, and no internet needed to play. Puzzles are
generated on your device, so you will never run out.

Ads keep the app free. Watch one if you want an extra hint, another
chance after running out of mistakes, or an hour with no ads at all.
```

## Google Play Console

**앱 이름 (30자)** `Sudoku Daily: Logic Puzzle`

**간단한 설명 (80자)**

```
A sudoku puzzle every day. Four difficulties and hints that explain the logic.
```

> 처음에 "A **new** sudoku every day..."로 넣었더니 Play가
> *"매장 상태나 프로그램을 나타내는 키워드를 사용하면 안 됩니다"* 경고를 띄웠다.
> `new`, `best`, `top`, `#1`, `sale`, `free` 같은 홍보성 단어는 간단한 설명에서
> 피할 것. 저장은 되지만 **Play 홍보 대상에서 제외될 수 있다.**

**자세한 설명** — ASC 설명과 동일하게 사용.

## 현지화 문구

한국어·일본어·독일어. Play는 30자 제한이 없고 ASC 이름은 30자 제한이 있다.

### 한국어

- 이름 `스도쿠 데일리: 로직 퍼즐`
- 부제 `매일 새 퍼즐과 풀이 힌트`
- 간단한 설명 `매일 새로운 스도쿠. 4단계 난이도와 이유를 설명해 주는 힌트.`
- 키워드 `스도쿠,데일리,퍼즐,숫자,두뇌,오프라인,킬러,클래식,논리,무료`

```
스도쿠 데일리는 매일 즐기도록 만든 클래식 9x9 스도쿠입니다.

매일 새로운 퍼즐
전 세계 이용자가 같은 오늘의 퍼즐을 풉니다.

4단계 난이도
쉬움, 보통, 어려움, 전문가. 난이도는 빈칸 개수가 아니라 그 퍼즐을 푸는 데
실제로 필요한 풀이 기법으로 정해집니다. 그래서 난이도가 이름값을 합니다.

가르쳐 주는 힌트
막히면 힌트가 칸을 짚어 주고, 왜 그 숫자가 들어가는지 이유를 설명합니다.
답만 보고 넘어가는 대신 하나 배우고 넘어갑니다.

편안한 플레이
- 정답 입력 시 자동 정리되는 메모(연필 표시)
- 되돌리기, 지우기, 실수 횟수 표시
- 행·열·박스 강조
- 라이트/다크 테마
- 자동 저장되어 퍼즐 도중에 나가도 됩니다

무료, 오프라인
계정도 가입도 필요 없고 인터넷 없이 즐길 수 있습니다. 퍼즐은 기기에서
생성되므로 떨어지지 않습니다.

광고 덕분에 앱을 무료로 유지합니다. 힌트를 더 받거나, 실수를 모두 쓴 뒤
이어서 하거나, 1시간 동안 광고를 끄고 싶을 때만 시청하면 됩니다.
```

### 日本語

- 名前 `ナンプレ デイリー: 数字パズル`
- サブタイトル `毎日の問題と解き方ヒント`
- 簡単な説明 `毎日新しいナンプレ。4段階の難易度と理由を教えるヒント。`
- キーワード `ナンプレ,数独,デイリー,パズル,数字,脳トレ,オフライン,無料,ロジック`

```
ナンプレ デイリーは、毎日遊べるように作られたクラシックな9x9の数独です。

毎日新しい問題
世界中のプレイヤーが同じ「今日の問題」に挑戦します。

4段階の難易度
かんたん、ふつう、むずかしい、エキスパート。難易度は空きマスの数ではなく、
その問題を解くために実際に必要な解法で決まります。

教えてくれるヒント
行き詰まったら、ヒントがマスを示し、なぜその数字が入るのかを説明します。
答えを見るだけでなく、解き方が身につきます。

快適に遊べる工夫
- 正解を入力すると自動で整理されるメモ機能
- 元に戻す、消去、ミス回数の表示
- 行・列・ブロックのハイライト
- ライトテーマとダークテーマ
- 自動保存されるので途中でやめても大丈夫

無料・オフライン
アカウント登録は不要で、インターネットがなくても遊べます。問題は端末で
生成されるため、尽きることがありません。

広告のおかげでアプリを無料で提供できます。ヒントの追加、ミス超過後の
コンティニュー、1時間の広告非表示が必要なときだけご覧ください。
```

### Deutsch

- Name `Sudoku Daily: Logikrätsel`
- Untertitel `Tagesrätsel & clevere Tipps`
- Kurzbeschreibung `Jeden Tag ein neues Sudoku. Vier Stufen und Tipps, die die Logik erklären.`
- Keywords `sudoku,täglich,rätsel,zahlen,logik,gehirn,offline,killer,klassisch,kostenlos`

```
Sudoku Daily ist klassisches 9x9-Sudoku, gemacht für jeden Tag.

JEDEN TAG EIN NEUES RÄTSEL
Alle bekommen dasselbe Tagesrätsel.

VIER SCHWIERIGKEITSGRADE
Leicht, Mittel, Schwer und Experte. Die Schwierigkeit richtet sich danach,
welche Lösetechniken ein Rätsel tatsächlich verlangt, nicht danach, wie
viele Felder leer sind.

TIPPS, DIE ETWAS BEIBRINGEN
Wenn Sie nicht weiterkommen, zeigt ein Tipp das Feld und erklärt, warum
diese Zahl dorthin gehört.

ANGENEHM ZU SPIELEN
- Notizen, die sich beim Lösen automatisch bereinigen
- Rückgängig, Löschen und Fehleranzeige
- Hervorhebung von Zeile, Spalte und Block
- Helles und dunkles Design
- Automatisches Speichern, Sie können jederzeit aufhören

KOSTENLOS UND OFFLINE
Kein Konto, keine Anmeldung, keine Internetverbindung nötig. Die Rätsel
entstehen auf Ihrem Gerät und gehen nie aus.

Werbung hält die App kostenlos. Sehen Sie eine an, wenn Sie einen
zusätzlichen Tipp möchten, nach aufgebrauchten Fehlern weiterspielen
wollen oder eine Stunde ohne Werbung wünschen.
```

## App Store: 앱 개인정보 (App Privacy)

심사 필수. 앱은 자체적으로 아무것도 수집하지 않고, **AdMob SDK가 수집하는
것만** 신고하면 된다.

**"데이터를 사용해 사용자를 추적함" → 예.** 개인화 광고가 Apple 정의의
추적에 해당한다. ATT 프롬프트를 띄우는 이유이기도 하다.

추적에 사용되는 데이터 / 사용자와 연결되지 않은 데이터:

| 카테고리 | 항목 | 목적 |
|---|---|---|
| 식별자 | 기기 ID (IDFA) | 서드파티 광고 |
| 사용 데이터 | 제품 상호작용, 광고 데이터 | 서드파티 광고 |
| 위치 | 대략적 위치 (IP 기반) | 서드파티 광고 |

**"사용자와 연결된 데이터"는 없다** — 계정이 없어 신원에 결합할 수단이 없다.

연령 등급: **4+**. 폭력·성적 콘텐츠·도박 요소 없음.

## Play: 데이터 보안 (Data safety)

| 질문 | 답 |
|---|---|
| 데이터 수집 | 예 (AdMob SDK) |
| 제3자 공유 | 예 (Google 및 광고 파트너) |
| 전송 중 암호화 | 예 |
| 삭제 요청 수단 | 계정이 없어 해당 없음, 앱 삭제 시 로컬 데이터 소멸 |

수집 항목: 위치(대략적), 앱 활동(앱 내 검색·상호작용), 기기 또는 기타 ID.
목적은 모두 **광고 또는 마케팅**. 필수 여부는 "선택 사항 아님"(SDK가 수집).

> AdMob의 데이터 보안 신고 권장값은 Google이 별도 문서로 관리한다.
> 제출 직전에 최신판을 확인하고 위 표와 대조할 것.

기타 Play 설정:

- **광고 포함: 예** (누락 시 정책 위반)
- 콘텐츠 등급 설문 → 전체 이용가 예상
- 타겟 연령: 13세 이상 (아동 대상 아님 → 아동 대상으로 신고하면 개인화 광고가
  막혀 eCPM이 급락한다)
- 정부 앱 아님, 금융 앱 아님

## Play Console 등록 상태 (2026-09-09)

앱 생성됨: `Sudoku Daily: Logic Puzzle` / `io.pinkspider.sudoku`
개발자 계정 `Pink Spider` (8732421573193870105), 앱 ID `4972306507413189771`.

- 스토어 등록정보, 앱 콘텐츠 선언 완료
- **2026-09-10 13:20 프로덕션 검토 제출 완료.** 1.0.0 (9), 전체 출시(단계적 출시 아님),
  국가/지역 **177개**, 상태 `검토 중인 변경사항`. 검토는 보통 7일 이내.
- 내부 테스트 트랙, 0.1.0 (8) 출시됨, 테스터 목록 `Sudoku Daily 테스터`
- 참여 링크는 내부 테스트 → 테스터 탭의 "링크 복사"
  (`https://play.google.com/apps/internaltest/4699101214901903640`)
- 신규 설치 크기 9.96MB (AAB 파일은 49MB지만 Play가 기기별로 분할 배포)

**주의: 콘솔 작업은 `ceo@pink-spider.io`로 해야 한다.**
`developer.ygpark@gmail.com`은 앱 생성 권한이 없다.

## App Store Connect 등록 상태 (2026-09-10, 심사 제출됨)

Apple ID `6810079534`, 번들 `io.pinkspider.sudoku`, SKU `sudoku-daily`.

- 앱이 수집하는 개인정보: **게시 완료**. 4개 유형(대략적 위치·기기 ID·제품 상호 작용·
  광고 데이터) 전부 `타사 광고` / `신원에 연결 안 됨` / `추적 목적으로 사용됨`.
- 앱 정보: 부제, 카테고리(게임 → 퍼즐·보드), 콘텐츠 권한(타사 콘텐츠 없음) 저장 완료.
- 연령 등급: **4+** (브라질 A12, 베트남 00+). 1단계에서 `광고`만 "예".
  한국은 GRAC 등급분류번호(RCN)를 넣을 수 있는 링크가 뜨지만 자체등급분류로 배포 가능.
- 가격: 무료($0.00), 175개 국가/지역 전체 사용 가능.
- 1.0 버전: 프로모션 텍스트·설명·키워드·지원/마케팅 URL·저작권, iPhone 6.9" 4장,
  iPad 13" 4장, 빌드 1.0.0 (9) 연결, 심사 노트 작성, 로그인 불필요 체크 해제.
- **4개 언어(en/ko/ja/de)** 전부 이름·부제·프로모션 텍스트·설명·키워드 + 언어별
  스크린샷(iPhone 6.9" 4장, iPad 13" 4장)까지 입력됨.
- **2026-09-10 13:10 심사 제출 완료.** 상태 `심사 대기 중`,
  제출 ID `f6a83cac-b189-4bfd-8d2a-fd76b2b357f5`, 제출자 ParkYungoo.
  심사는 최대 48시간. 결과는 이메일로 온다. 앱 심사 페이지에서 `제출 취소` 가능.
- 출시 방식은 **자동 출시**(심사 통과 즉시 App Store 공개)로 두었다.
  수동으로 바꾸려면 심사 통과 전에 버전 페이지의 "App Store 버전 출시"에서 변경.

### 콘솔 자동화 메모

ASC 텍스트 필드는 React 컨트롤드 인풋이라 키 입력을 흉내내면 **한글 받침이
깨진다**("풉니다" → "�니다", "킬러" → "킴러"/"키러"). 다국어 문구는 반드시
네이티브 setter로 넣고 input/change 이벤트를 직접 쏠 것:

```js
const setter = Object.getOwnPropertyDescriptor(
  el.tagName === 'TEXTAREA' ? HTMLTextAreaElement.prototype : HTMLInputElement.prototype,
  'value').set;
setter.call(el, value);
el.dispatchEvent(new Event('input', {bubbles: true}));
el.dispatchEvent(new Event('change', {bubbles: true}));
```

필드 이름: `name`, `subtitle`(앱 정보) / `promotionalText`, `description`,
`keywords`, `supportUrl`, `marketingUrl`, `copyright`, `notes`,
`contactFirstName`, `contactLastName`, `contactPhone`, `contactEmail`(버전 정보).

### 프로덕션 출시에서 걸렸던 것

1. **프로덕션 트랙에 국가/지역이 0개**여서 릴리스 검토 단계가 오류로 막힌다.
   내부 테스트 트랙의 국가 설정은 프로덕션에 상속되지 않는다.
   프로덕션 → 국가/지역 탭에서 헤더 체크박스로 전체 선택 후 저장.
2. **"불완전한 광고 ID 선언"** — targetSdk 33+ 앱은 광고 ID 사용 여부를 신고해야
   전송이 열린다. AdMob을 쓰면 매니페스트에 `com.google.android.gms.permission.AD_ID`가
   자동 병합되므로 **예** + 목적은 **광고 또는 마케팅**만 체크
   (앱 기능·애널리틱스·맞춤설정 등은 해당 없음 — Firebase 미연결, 계정 없음).
   위치: 모니터링 및 개선 → 정책 및 프로그램 → 앱 콘텐츠 → 광고 ID.

**AAB는 51.7MB라 브라우저 드래그앤드롭으로만 올릴 수 있다**(자동화 업로드 한도 초과).
반복하려면 Play Developer API 서비스 계정 + `fastlane supply`를 붙일 것.

## 2026-09-10 Play 거부 — 원인과 수정

프로덕션 1.0.0 (9)가 **거부**됐다. 두 가지 정책 위반이었고 둘 다 실제 결함이었다.

### 1. 손상된 기능 — "앱이 열리지만 계속 비정상 종료됩니다"

릴리스 빌드가 **Dart 코드가 실행되기도 전에** 죽었다:

```
Unable to get provider androidx.startup.InitializationProvider
Caused by: Failed to create an instance of androidx.work.impl.WorkDatabase
  at androidx.work.WorkManagerInitializer
```

`google_mobile_ads`가 오프라인 광고 핑용으로 `androidx.work`를 끌고 오는데,
WorkManager는 Room이 생성한 `WorkDatabase_Impl`을 **이름으로** 찾는다.
R8이 그 이름을 바꿔버려서 앱이 시작 즉시 죽었다.

**디버그 빌드에서는 R8이 안 돌아 절대 재현되지 않는다.** bootstrap.sh도 debug만
빌드해서 여기까지 왔다. → `android/app/proguard-rules.pro`에 keep 규칙 추가.

**릴리스 APK를 에뮬레이터에 올려 보지 않으면 이 부류는 못 잡는다:**

```bash
flutter build apk --release -t lib/main_prod.dart
adb install -r build/app/outputs/flutter-apk/app-release.apk
adb logcat -c && adb shell am start -n io.pinkspider.sudoku/.MainActivity
adb shell pidof io.pinkspider.sudoku    # 비어 있으면 죽은 것
adb logcat -d | grep -A20 "FATAL EXCEPTION"
```

### 2. 혼동을 야기하는 주장 — "설치된 아이콘 또는 이름이 스토어와 다릅니다"

둘 다 틀렸었다:

| | 거부 시점 | 수정 후 |
|---|---|---|
| 런처 아이콘 | **Flutter 기본 파란 로고** | 스도쿠 격자 (스토어 아이콘과 동일 SVG) |
| 앱 내 AppBar | `Sudoku` | `Sudoku Daily` |
| 런처 이름 | `Sudoku Daily` | 그대로 |
| 스토어 등록정보 | `Sudoku Daily: Logic Puzzle` | 그대로 |

`tool/gen_icons.sh`가 **iOS AppIcon만** 만들고 Android mipmap은 손대지 않아서,
7월 Flutter 템플릿 아이콘이 그대로 배포됐다. iOS는 멀쩡했다.
→ 스크립트에 Android 런처 아이콘 + adaptive icon 생성 추가.

앱 내 타이틀은 `lib/l10n/app_*.arb`의 `appTitle`이다(`AppConfig.appName`은 아무
데서도 쓰이지 않는 죽은 필드다). 4개 언어 모두 스토어 이름에 맞췄다.

### 재제출 (2026-09-10 15:45~16:05)

`1.0.0+10`으로 올려 양쪽 다 다시 제출했다.

| | 상태 |
|---|---|
| Play | 검토 중. `fastlane production skip_build:true`로 53초 만에 업로드 |
| App Store | 심사 대기 중. 빌드 9 제출을 취소하고 10으로 교체 |

- **Play는 versionCode를 재사용할 수 없다.** 9는 거부됐어도 소모된 번호다.
- **ASC는 심사 시작 전이면 제출을 취소할 수 있다**(앱 심사 → 제출 → 제출 취소).
  취소하면 버전이 `개발자가 취소함`이 되고 메타데이터는 그대로 남는다.
  빌드만 교체(9 삭제 → 10 추가)하고 다시 제출하면 된다.
  빌드 행의 삭제 버튼은 hover해야 보이고 `aria-label="삭제"`다.
- 업로드 직후에는 ASC 빌드 목록에 안 뜬다. 처리에 5~15분 걸리고
  TestFlight 탭에서 `제출 준비 완료`가 되면 그때 선택할 수 있다.
- **Fastfile의 `before_all` 가드도 새 시크릿 경로를 보도록 고쳤다.**
  리포 밖으로 옮기면서 놓쳐서 첫 업로드가 "key.properties가 없다"로 막혔다.

### 재제출 전 체크

```bash
cd apps/sudoku
bash tool/gen_icons.sh                       # 아이콘 재생성(iOS+Android)
flutter build apk --release -t lib/main_prod.dart
# 위 adb 절차로 크래시 없음 + 런처 아이콘/이름 눈으로 확인
```

## 제출 전 남은 것

- [x] 실제 광고 단위 ID로 교체 (`AppConfig.prod`). dev는 테스트 단위 유지.
- [ ] **AdMob "광고 게재가 제한됨" 해제** — 신규 앱은 스토어 등록정보와 연결될
      때까지 게재가 제한된다. AdMob 앱 목록에서 "스토어 추가"로 Play/App Store
      리스팅을 연결할 것. 이걸 안 하면 실제 광고 단위를 넣어도 채워지지 않는다.
- [x] `app-ads.txt` — 이미 배포되어 있고 게시자 ID가 같아 그대로 적용된다
      (<https://pink-spider.github.io/app-ads.txt>, `pub-6329038356545416`).
      앱마다 파일을 따로 만들 필요는 없다. 대신 위의 **개발자 웹사이트**를
      두 스토어 리스팅에 반드시 넣을 것 — 그게 크롤러의 유일한 연결 고리다.
- [ ] 지원 URL을 개인정보처리방침이 아닌 전용 페이지로 분리
- [x] Play 태블릿 스크린샷 (선택이 아니라 **필수**였다)
- [x] Android 릴리스 서명 키 — [docs/android-signing.md](android-signing.md).
      **키스토어와 key.properties는 git에 없으니 지금 백업할 것.**
- [ ] Play 앱 서명 가입 (신규 앱 기본값, 업로드 키 분실 시 유일한 복구 수단)
