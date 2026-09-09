# 스토어 등록 정보 (ASC + Play Console)

콘솔에 붙여넣을 문구와 설문 답변. **앱 동작이 바뀌면 여기부터 고치고**
개인정보처리방침(<https://pink-spider.github.io/sudoku-privacy/>)과 함께 맞출 것.

## 에셋

| 파일 | 크기 | 어디에 |
|---|---|---|
| `apps/sudoku/build/screenshots/<locale>-*.png` | 1320×2868 | ASC 6.9" / Play 폰 |
| `apps/sudoku/build/screenshots-tablet/<locale>-*.png` | 1668×2420 | Play 7"·10" 태블릿 (**필수**) |
| `apps/sudoku/build/store/icon-512.png` | 512×512 | Play 아이콘 |
| `apps/sudoku/build/store/feature-graphic.png` | 1024×500 | Play 피처 그래픽 (필수) |
| 앱 아이콘 1024 | 번들 내장 | ASC가 빌드에서 자동 추출 |

생성:

```bash
cd apps/sudoku
tool/screenshots.sh                          # 폰: 1320x2868
tool/screenshots.sh "iPad Pro 11-inch (M4)"  # 태블릿: 1668x2420
tool/gen_store_assets.sh                     # Play 아이콘 + 피처 그래픽
```

**Play는 7인치·10인치 태블릿 스크린샷이 둘 다 필수다**(폰만으로는 게시가 막힌다).
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

- 스토어 등록정보, 앱 콘텐츠 선언 11/11 완료
- **내부 테스트 트랙 활성**, 0.1.0 (8) 출시됨, 테스터 목록 `Sudoku Daily 테스터`
- 참여 링크는 내부 테스트 → 테스터 탭의 "링크 복사"
  (`https://play.google.com/apps/internaltest/4699101214901903640`)
- 신규 설치 크기 9.96MB (AAB 파일은 49MB지만 Play가 기기별로 분할 배포)

**주의: 콘솔 작업은 `ceo@pink-spider.io`로 해야 한다.**
`developer.ygpark@gmail.com`은 앱 생성 권한이 없다.

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
