# Android 릴리스 서명

## ⚠️ 먼저 백업할 것

```
apps/sudoku/android/app/upload-keystore.jks   업로드 키
apps/sudoku/android/key.properties            별칭과 비밀번호
```

**둘 다 git에 없다**(`.gitignore` 처리됨). 이 맥이 죽으면 같이 사라진다.
1Password 같은 곳에 지금 넣어둘 것.

잃어버렸을 때: Play 앱 서명에 가입되어 있으면 Google에 업로드 키 재설정을
요청할 수 있다(앱 서명 키는 Google이 보관하므로 앱은 살아남는다). 가입되어
있지 않으면 **그 앱은 영영 업데이트할 수 없고** 새 패키지명으로 다시 출시해야
한다. 그래서 신규 앱은 Play 앱 서명에 반드시 가입한다(요즘은 기본값).

현재 키 지문(SHA-256):

```
48:49:98:3D:95:8B:13:A4:83:32:CF:76:E2:56:B4:5B:80:8A:63:4E:4B:03:9A:4D:70:A9:23:32:06:7A:17:20
```

- 형식 PKCS12(JKS는 폐기 예정), RSA 2048, 별칭 `upload`
- 유효기간 10000일 (2054-01까지). Play는 2033-10 이후까지 유효할 것을 요구한다.
- 앱마다 별도 키를 쓴다. firedom 등 다른 앱 키를 재사용하지 않는다.

## 빌드

```bash
cd apps/sudoku
flutter build appbundle --release -t lib/main_prod.dart
# → build/app/outputs/bundle/release/app-release.aab
```

Play에는 APK가 아니라 **AAB**를 올린다. 파일이 50MB 정도로 크게 보이지만
모든 ABI가 들어 있기 때문이고, Play가 기기별로 쪼개서 배포하므로 실제 다운로드
용량은 그보다 훨씬 작다.

## 어떻게 연결돼 있나

`android/app/build.gradle.kts`가 `android/key.properties`를 읽는다.
파일이 **없으면 디버그 키로 서명하고 경고만 남긴다** — 새로 클론했거나 시크릿이
없는 CI에서도 빌드는 되게 하기 위해서다. 대신 그 산출물은 Play에 못 올린다.
업로드가 "서명이 잘못됐다"고 거부되면 이 경고부터 확인할 것.

`key.properties` 형식:

```properties
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=upload-keystore.jks
```

`storeFile`은 `android/app/` 기준 상대경로다.

## R8 (코드 축소)

릴리스 빌드는 `isMinifyEnabled`로 R8을 켠다. `app/proguard-rules.pro`에 세 덩어리:

- `com.google.android.gms.ads.**`, `com.google.android.ump.**` — 광고·UMP SDK가
  자기 클래스를 리플렉션으로 참조한다.
- `io.flutter.embedding.**` — 매니페스트와 생성 코드에서 참조된다.
- `-dontwarn com.google.android.play.core.**` — Flutter 임베딩이 쓰지도 않는
  지연 컴포넌트 API를 참조해서, 이게 없으면 R8이 "Missing class"로 **빌드를
  실패시킨다**. 실제로 처음 빌드가 여기서 깨졌다.

## 새 키가 필요할 때 (2호 앱 등)

```bash
cd apps/<앱>/android
PW="$(openssl rand -base64 24 | tr -d '/+=' | head -c 28)"
keytool -genkeypair -keystore app/upload-keystore.jks -storetype PKCS12 \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload \
  -storepass "$PW" -keypass "$PW" \
  -dname "CN=Yungoo Park, OU=Pink Spider, O=Pink Spider, L=Seoul, C=KR"
cat > key.properties <<EOF
storePassword=$PW
keyPassword=$PW
keyAlias=upload
storeFile=upload-keystore.jks
EOF
chmod 600 key.properties app/upload-keystore.jks
```

만든 직후 `git check-ignore -v android/key.properties android/app/*.jks`로
무시되는지 확인하고, 바로 백업할 것.
