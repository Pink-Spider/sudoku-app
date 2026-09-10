# Play 업로드 자동화 (fastlane supply)

AAB가 51MB라 브라우저 드래그앤드롭 말고는 올릴 방법이 없었다. 그걸 없애려고
Play Developer API 서비스 계정을 붙였다.

```bash
cd apps/sudoku/android
fastlane internal      # 내부 테스트 트랙
fastlane production    # 프로덕션 (초안으로만 올라간다)
```

`fastlane`은 Homebrew로 깔았다(`brew install fastlane`, 2.239.0). 시스템 Ruby 2.6은
최신 fastlane과 맞지 않아 gem 설치는 피했다.

## 현재 설정 (2026-09-10 구축)

| | |
|---|---|
| GCP 프로젝트 | `pink-spider-play` |
| 서비스 계정 | `play-publisher@pink-spider-play.iam.gserviceaccount.com` |
| 키 ID | `15deda715973b98d8164dd35eb467079bb1cdc32` |
| Play 권한 | Sudoku Daily 1개 앱, 6개 권한 (아래) |

서비스 계정 이메일은 **메일함이 없는 Google IAM 식별자**다. 사람 사용자와 달리
초대 메일·수락 절차가 없고 초대 즉시 `활성`이 된다.

부여한 권한 — 계정 전체가 아니라 `io.pinkspider.sudoku` 하나에만:

- ✅ 앱 정보 보기 / 앱 품질 정보 보기 (읽기 전용)
- ✅ 앱을 테스트 트랙으로 출시
- ✅ 프로덕션으로 출시, 기기 제외, Play 앱 서명 사용
- ❌ 관리자, 재무 데이터, 주문·구독 관리

프로덕션 트랙에 **draft로 올리는 것도 "프로덕션으로 출시" 권한을 요구한다.**
그래서 이 권한을 줬고, 대신 Fastfile이 `release_status: "draft"`로 고정해
실제 공개 버튼은 사람이 누르게 했다. 키를 잃으면 남이 프로덕션 버전을 바꿀 수
있다는 뜻이기도 하다.

검증:

```
$ fastlane run validate_play_store_json_key
Successfully established connection to Google Play Store.

$ fastlane run google_play_track_version_codes package_name:io.pinkspider.sudoku track:production
Found '9' version codes in track 'production'
```

## ⚠️ 서비스 계정 키

```
~/.pink-spider/secrets/sudoku/play-store-key.json
```

**리포 밖에 있다.** gitignore에만 기대면 `git clean -xdf` 한 번에 날아가서
업로드 키스토어와 같은 곳으로 뺐다([docs/android-signing.md](android-signing.md)).

Appfile이 찾는 순서: `$SUPPLY_JSON_KEY` → 위 경로 → `android/play-store-key.json`(예전).

이 키로 Sudoku Daily를 프로덕션에 올릴 수 있으니 키스토어와 같은 급으로 다뤄라.
1Password 같은 곳에 넣고, 유출되면 즉시 폐기하고 새로 만든다.

```bash
# 폐기
gcloud iam service-accounts keys list --iam-account=$SA_EMAIL
gcloud iam service-accounts keys delete <KEY_ID> --iam-account=$SA_EMAIL
```

## 처음부터 다시 만들 때

Google Cloud 프로젝트와 Play Console 양쪽을 건드려야 한다. Cloud Console 웹 UI는
브라우저 자동화에서 막혀서 gcloud CLI로 하는 게 빠르다.

### 1. gcloud 로그인

```bash
gcloud auth login          # 브라우저가 열린다. ceo@pink-spider.io로 로그인할 것
```

**`developer.ygpark@gmail.com`이 아니다.** Play Console 관리자는 `ceo@pink-spider.io`다.

### 2. 프로젝트 + API + 서비스 계정

```bash
PROJECT=pink-spider-play
SA=play-publisher

gcloud projects create "$PROJECT" --name="Pink Spider Play"
gcloud config set project "$PROJECT"
gcloud services enable androidpublisher.googleapis.com

gcloud iam service-accounts create "$SA" \
  --display-name="Play Publisher (fastlane supply)"

SA_EMAIL="$SA@$PROJECT.iam.gserviceaccount.com"
mkdir -p ~/.pink-spider/secrets/sudoku && chmod 700 ~/.pink-spider/secrets/sudoku
gcloud iam service-accounts keys create \
  ~/.pink-spider/secrets/sudoku/play-store-key.json \
  --iam-account="$SA_EMAIL"
chmod 600 ~/.pink-spider/secrets/sudoku/play-store-key.json
```

서비스 계정 자체에는 GCP IAM 역할을 줄 필요가 없다. 권한은 Play Console 쪽에서 준다.

### 3. Play Console에서 권한 부여

Play Console → **사용자 및 권한** → **신규 사용자 초대** → 위 `$SA_EMAIL` 입력.

앱 권한은 `Sudoku Daily: Logic Puzzle` 하나만 주고, 그 안에서도:

- ✅ 앱 정보 보기 / 앱 품질 정보 보기
- ✅ 앱을 테스트 트랙으로 출시
- ✅ 프로덕션으로 출시, 기기 제외, Play 앱 서명 사용
- ❌ 관리자, 재무 데이터, 주문·구독 관리

서비스 계정은 메일함이 없어서 초대 수락 절차가 없다. 초대 즉시 `활성`이 된다.

### 4. 확인

```bash
cd apps/sudoku/android
# 인증만 확인 (빌드·업로드 없음)
fastlane run validate_play_store_json_key

# 앱 접근까지 확인
fastlane run google_play_track_version_codes \
  package_name:io.pinkspider.sudoku track:production
```

## Fastfile이 하는 일

- **빌드는 flutter가 한다.** fastlane은 `flutter build appbundle`을 부르고 결과 AAB만
  올린다. Gradle을 fastlane이 직접 돌리면 flavor·dart-define이 새기 쉬워서 이렇게 했다.
- **`before_all`에서 `key.properties` 존재를 확인한다.** 이 파일이 없으면 릴리스가
  디버그 키로 서명되는데 빌드는 성공해서 눈치채기 어렵다. Play가 거부하고 나서야 안다.
- **`release_status: "draft"`가 기본이다.** `completed`로 올리면 심사 통과 즉시
  전체 사용자에게 공개된다. 초안으로 올리고 콘솔에서 출시 시점을 고르는 편이 안전하다.
  굳이 바꾸려면 `fastlane production status:completed`.
- 메타데이터·스크린샷·변경사항은 전부 `skip_upload_*`로 껐다. 스토어 문구는
  [docs/store-listing.md](store-listing.md)가 원본이고 콘솔에서 관리한다.
  fastlane이 덮어쓰면 다국어 문구가 통째로 날아간다.

## 자주 걸리는 것

| 증상 | 원인 |
|---|---|
| `Google Api Error: Invalid request - Package not found` | 서비스 계정에 그 앱 권한이 없거나, 반영 전(몇 분 기다린다) |
| `The caller does not have permission` | 그 트랙 권한이 없다. 프로덕션은 draft로 올릴 때도 '프로덕션으로 출시'가 필요하다 |
| `APK specifies a version code that has already been used` | `pubspec.yaml`의 `+N`을 올려야 한다 |
| 업로드는 되는데 콘솔에 안 보임 | 초안(draft)으로 올라갔다. 프로덕션 → 버전에서 확인 |
