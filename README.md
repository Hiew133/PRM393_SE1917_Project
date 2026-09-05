<h1 align="center">さくら — Sakura</h1>

<p align="center">
  Ứng dụng học tiếng Nhật cho người Việt: học chữ, học từ, luyện nghe<br/>
  và <b>luyện nói với AI</b> — tất cả trong một app Flutter.
</p>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.11-02569B?logo=flutter&logoColor=white" />
  <img alt="Dart" src="https://img.shields.io/badge/Dart-3-0175C2?logo=dart&logoColor=white" />
  <img alt="Firebase" src="https://img.shields.io/badge/Firebase-Auth%20%C2%B7%20Firestore%20%C2%B7%20Storage-FFCA28?logo=firebase&logoColor=black" />
  <img alt="Gemini" src="https://img.shields.io/badge/Gemini-qua%20Firebase%20AI%20Logic-4285F4?logo=googlegemini&logoColor=white" />
  <img alt="Platform" src="https://img.shields.io/badge/Android%20%C2%B7%20Web-lightgrey" />
</p>

<p align="center">
  <b>🌐 Dùng thử ngay trên web: <a href="https://sakura-nihon.web.app">sakura-nihon.web.app</a></b><br/>
  <sub>Mở bằng trình duyệt là chạy, không cần cài. Trên điện thoại có thể "Thêm vào màn hình chính" để dùng như app.</sub>
</p>

<p align="center">
  <b>📦 Tải bản Android: <a href="https://github.com/Hiew133/PRM393_SE1917_Project/releases/latest">Releases</a></b>
</p>

---

## Đây là gì

Hầu hết app học tiếng Nhật dạy bạn **nhận ra** tiếng Nhật. さくら tập trung vào
phần khó hơn: **tự sản sinh ra nó** — viết đúng nét chữ, nhớ từ đúng lúc sắp
quên, và mở miệng nói thành câu.

App có đủ vòng học khép kín: học bài → ôn theo SRS → tự kiểm tra → nói chuyện
với giáo viên AI → xem tiến độ. Kèm bảng quản trị cho giáo viên tự soạn đề thi
nói mà không cần đụng vào code.

## Tính năng

### 🗣 Luyện nói với AI — phần đáng chú ý nhất
- **会話 (hội thoại tự do)** — chọn tình huống, nói vào micro, AI nghe và đáp lại
  bằng tiếng Nhật. Nhân vật ảo **nhép miệng theo giọng đọc** (lip-sync theo trạng
  thái TTS).
- Người mới học nói ngắc ngứ không bị cắt câu: phiên nhận diện giọng tự mở lại
  khi ngừng nói giữa chừng.
- **Chế độ thi** — mô phỏng đề thi nói (JPD326, Nihon 1, Nihon 2): bốc đề, đóng
  vai, trả lời câu hỏi, tính điểm theo rubric (nội dung / câu hỏi / cách trình bày).
- **Chấm phát âm** — so khớp lời nói với đáp án chuẩn, chỉ ra chỗ lệch.
- **Phân tích sau buổi thi bằng AI**, lưu kèm vào lịch sử để xem lại.

### ✍️ Học chữ
- **Kana quiz** — nhận mặt chữ, và **chế độ viết**: hiện romaji, bạn vẽ chữ lên
  canvas, hệ thống **chấm theo từng nét** (dữ liệu KanjiVG đóng gói offline).
  Tắt được khung mẫu / số thứ tự / mũi tên để luyện trí nhớ thật.
- **Kanji** — bài học, canvas tập viết, parser SVG thứ tự nét.

### 📚 Học & ôn
- Bài học từ vựng, ngữ pháp, kanji theo chủ đề.
- **SRS 9 cấp** kiểu WaniKani (見習い → 弟子 → 達人 → 悟り → 燃焼済): thẻ nào sắp
  quên thì nổi lên trước.
- Ôn riêng từ vựng / ngữ pháp / kanji, có flashcard và nút tự đánh giá.

### 🎧 Luyện nghe
- Bài nghe N5 kèm audio đóng gói sẵn, câu hỏi, thẻ thông tin mở rộng.
- Đánh dấu yêu thích, theo dõi bài đã hoàn thành.

### 🎮 & phần còn lại
- **Thủ môn bắt bóng** — quiz trắc nghiệm dạng game, đúng thì ghi bàn, sai thì bị chặn.
- **Gia sư AI** gọi được từ bất kỳ màn nào (bottom sheet).
- **Dashboard** — mục tiêu ngày, thẻ học tiếp, tiến độ từng kỹ năng.
- **3 vai trò**: Admin / Customer / Guest. Khách xem được phần lớn nội dung, các
  tính năng cần lưu tiến độ thì hiện dialog mời đăng nhập.
- **Trang quản trị** — soạn đề thi nói, ngân hàng câu hỏi, ngân hàng tình huống,
  CRUD nội dung, thống kê, cấu hình AI.
- Chống dò mật khẩu: đếm số lần đăng nhập sai và khoá tài khoản.

## Kỹ thuật đáng nói

- **Không có API key trong app.** Mọi lời gọi Gemini đi qua **Firebase AI Logic**
  + **App Check**, nên key không nằm trong bundle để ai đó rút ra.
- **Font bundle sẵn** (Inter, Noto Sans JP, DM Sans, Lexend) thay vì `google_fonts`
  tải runtime — mở app không phải chờ fetch font qua mạng.
- **TTS đa nền tảng** — bản Android dùng `flutter_tts`, bản web có engine riêng
  (`web_tts_engine_web.dart`) qua cơ chế conditional import, cộng thêm Gemini TTS.
- **Kiến trúc feature-first**: `lib/features/<tính năng>/` chứa screen + widget +
  service + model của riêng nó; `lib/core/` giữ theme, service dùng chung, tiện ích.
- Chạy được cả **Android** lẫn **Web** (Firebase Hosting, site `sakura-nihon`).

## Cấu trúc

```
nihon/
  lib/
    core/          theme, service dùng chung (AI, TTS, auth, SRS, vai trò), widget chung
    data/          model (VocabCard, SrsCard, SrsStage, Skill) + dữ liệu mẫu
    features/      auth · dashboard · lessons · review · listening · speaking
                   · kana_quiz · chat · games · admin · profile · progress
    firebase_options.dart
  assets/          audio · fonts · images · kana_svg (KanjiVG)
```

## Chạy thử

```bash
cd nihon
flutter pub get
flutter run
```

Cần một project Firebase của riêng bạn (Auth, Firestore, Storage, App Check,
AI Logic) — chạy `flutterfire configure` để sinh lại `lib/firebase_options.dart`
và `android/app/google-services.json`.

App Check được bật Enforced, nên build/deploy cần truyền reCAPTCHA site key
(web) hoặc debug token (APK sideload) — **không hard-code vào repo**. Các lệnh
đầy đủ nằm trong [`nihon/BUILD.md`](nihon/BUILD.md).

```bash
cp appcheck.web.example.json appcheck.web.local.json          # điền site key
cp appcheck.android.example.json appcheck.android.local.json  # điền debug token
flutter build web --dart-define-from-file=appcheck.web.local.json
flutter build apk --release --dart-define-from-file=appcheck.android.local.json
```

> Đồ án môn **PRM393 – Mobile Programming**, lớp SE1917.
