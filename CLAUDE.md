# CLAUDE.md

Hướng dẫn cho Claude Code khi làm việc trong repo này.

## Repo này là gì

App Flutter học tiếng Nhật **さくら**. Toàn bộ code nằm trong `nihon/` — chạy
mọi lệnh `flutter` từ trong đó, không phải từ gốc repo.

Chạy được cả **Android** và **Web** (Firebase Hosting, site `sakura-nihon`,
https://sakura-nihon.web.app). Backend là Firebase: Auth, Firestore, Storage,
App Check, AI Logic.

Comment và text UI viết bằng **tiếng Việt** — giữ đúng quy ước đó khi sửa file
có sẵn.

## Lệnh

```bash
cd nihon
flutter pub get
flutter run
flutter analyze lib/          # 112 issue lint có sẵn, chỉ quan tâm dòng "error"
```

Build và deploy cần truyền cấu hình App Check — xem [`nihon/BUILD.md`](nihon/BUILD.md).
Không có test suite.

## ⚠️ AI backend — đọc trước khi đụng vào tính năng AI

**Hiện tại dùng `FirebaseAI.googleAI()` (Gemini Developer API), KHÔNG phải
Vertex AI.** Lý do: project đang ở **gói free (Spark)**, mà Vertex AI bắt buộc
gói **Blaze**. Gọi `vertexAI()` trên gói free trả:

```
403 This API method requires billing to be enabled.
```

Lỗi này từng làm chết toàn bộ tính năng AI trên cả web lẫn APK.

### Nếu sau này nâng lên Blaze và muốn quay lại Vertex

Hai backend dùng **tên model khác nhau** — đổi provider mà quên đổi model là 404.
Phải sửa đồng bộ ba chỗ:

| Chỗ | Developer API (`googleAI`) — hiện tại | Vertex AI (`vertexAI`) |
| --- | --- | --- |
| Provider, 5 call site | `FirebaseAI.googleAI()` | `FirebaseAI.vertexAI()` |
| `lib/core/config/api_config.dart` | `gemini-flash-latest` | tên tường minh, ví dụ `gemini-2.5-flash` — **alias `-latest` KHÔNG tồn tại bên Vertex** |
| `lib/core/services/gemini_tts_service.dart` | `gemini-2.5-flash-preview-tts` | `gemini-2.5-flash-tts` (không có `-preview-`) |

Năm call site của provider:

```
lib/core/services/gemini_tts_service.dart
lib/features/chat/ai_chat_screen.dart
lib/features/lessons/kanji_study_screen.dart
lib/features/speaking/services/ai_conversation_service.dart   (2 chỗ)
```

Cả hai tên model đều override được lúc build mà không phải sửa code:

```bash
flutter build web --dart-define=GEMINI_MODEL=gemini-2.5-flash --dart-define=GEMINI_TTS_MODEL=gemini-2.5-flash-tts
```

### Kiểm tra nhanh model nào còn sống

Đừng đoán — tên model bị Google gỡ khá thường xuyên (`gemini-2.5-flash` đã bị
gỡ với thông báo *"no longer available to new users"*). Mở
https://sakura-nihon.web.app rồi chạy trong console trình duyệt: lấy App Check
token qua `exchangeRecaptchaEnterpriseToken`, POST thử
`firebasevertexai.googleapis.com/v1beta/projects/<project>/models/<model>:generateContent`.
Đường dẫn có `locations/us-central1` là Vertex, không có là Developer API.

### Chẩn đoán lỗi AI

`ai_conversation_service.dart` map lỗi theo thứ tự — **thứ tự này quan trọng**:
nhánh billing và nhánh model-bị-gỡ phải đứng TRƯỚC nhánh App Check, vì lỗi
billing cũng là 403 và từng bị báo nhầm thành "App Check chưa cài", khiến
người sửa đi tìm sai chỗ mất nhiều giờ.

Trước khi kết luận "do App Check", hãy xác minh App Check thật sự hỏng: gọi
`exchangeRecaptchaEnterpriseToken` xem có trả 200 kèm JWT không.

## Bí mật

**Không hard-code token vào repo.** Giá trị thật nằm trong `nihon/appcheck.*.local.json`
(đã gitignore), truyền qua `--dart-define-from-file`.

Web và Android dùng **file riêng**: `String.fromEnvironment` biên dịch thành
hằng số trong bundle ở mọi target, nên build web bằng file chứa
`APP_CHECK_DEBUG_TOKEN` sẽ đẩy token Android vào `main.dart.js` cho cả thiên hạ đọc.

Không commit APK (`*.apk` đã gitignore) — phát hành qua GitHub Releases. Token
debug moi được từ APK bằng `unzip | grep`, nên dùng token riêng cho bản demo và
đổi mỗi lần phát hành.

Các chuỗi `AIza...` trong `firebase_options.dart` và `google-services.json` là
**config client công khai của Firebase, KHÔNG phải secret** — chúng vốn được
thiết kế để nằm trong app, bảo vệ bằng Security Rules + App Check. Đừng xoá.
