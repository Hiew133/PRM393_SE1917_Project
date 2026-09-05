# Build & deploy

App Check bật **Enforced** cho Firebase AI Logic: request không kèm token hợp lệ
sẽ bị chặn, nên mọi tính năng AI phụ thuộc phần cấu hình dưới đây.

**Không hard-code token vào repo.** Giá trị thật nằm trong file `*.local.json`
(đã gitignore), truyền vào lúc build bằng `--dart-define-from-file`.

## ⚠️ Web và Android dùng file RIÊNG — đừng gộp

`String.fromEnvironment` biên dịch thành **hằng số trong bundle**, ở mọi target,
kể cả target không dùng tới nó. Nếu build web bằng file có
`APP_CHECK_DEBUG_TOKEN` thì token Android sẽ nằm trong `main.dart.js` và ai tải
trang cũng đọc được — đúng cái lỗi ta vừa đi sửa.

| Build | File | Chứa |
| --- | --- | --- |
| Web | `appcheck.web.local.json` | chỉ `RECAPTCHA_SITE_KEY` |
| APK | `appcheck.android.local.json` | `APP_CHECK_DEBUG_TOKEN`, `USE_DEBUG_APPCHECK` |

```bash
cp appcheck.web.example.json appcheck.web.local.json
cp appcheck.android.example.json appcheck.android.local.json
```

---

## Web — reCAPTCHA v3

Bản web **không dùng debug token**. Site key lấy ở Firebase Console → App Check
→ app **web** → reCAPTCHA (chọn **Score based v3**, KHÔNG phải v2, cũng không
phải Enterprise — code dùng `ReCaptchaV3Provider`). Nhớ khai đủ domain
`sakura-nihon.web.app`, `sakura-nihon.firebaseapp.com`, `localhost`.

Site key là **public** (nó nằm trong JS của trang). Secret key thì ở lại
Console, không bao giờ đưa vào repo.

```bash
flutter build web --dart-define-from-file=appcheck.web.local.json
```

```bash
firebase deploy --only hosting
```

Kiểm tra sau khi deploy — cả hai lệnh phải không ra gì:

```bash
curl -s https://sakura-nihon.web.app | grep APPCHECK_DEBUG_TOKEN
```

```bash
curl -s https://sakura-nihon.web.app/main.dart.js | grep -oE "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"
```

---

## Android — APK gửi tay (sideload)

APK cài ngoài Google Play thì **Play Integrity luôn fail**, nên bản demo phải
dùng debug provider. Token sẽ nằm trong APK và moi ra được bằng
`unzip -p app.apk | grep -a <uuid>` — chấp nhận điều đó, nên:

- Dùng **một token riêng cho bản demo**, khác token máy dev.
- Đổi token mỗi lần phát hành; token cũ xoá trong Console là chết ngay.
- Bản lên Google Play thì **KHÔNG** bật `USE_DEBUG_APPCHECK` — Play Integrity lo.

Đăng ký token: Console → App Check → app `com.example.layout` → Manage debug
tokens → Add → dán UUID.

```bash
flutter build apk --release --dart-define-from-file=appcheck.android.local.json
```

File ra ở `build/app/outputs/flutter-apk/app-release.apk` — đổi tên rồi đính vào
GitHub Releases, **đừng commit vào repo** (`*.apk` đã gitignore).

Kiểm tra token đúng đã vào APK:

```bash
unzip -p build/app/outputs/flutter-apk/app-release.apk | grep -ac "<uuid-moi>"
```

---

## Máy dev

Mỗi máy một token riêng, thu hồi được từng cái.

Cách 1 — để SDK tự sinh: chạy app với `APP_CHECK_DEBUG_TOKEN` bỏ trống, xem log
tìm UUID App Check in ra, chép vào Console → Manage debug tokens.

Cách 2 — tự chọn trước một UUID, đăng ký trong Console, rồi:

```bash
flutter run --dart-define-from-file=appcheck.android.local.json
```

---

## Nếu bị chặn hết

Triệu chứng: app mở được nhưng mọi tính năng AI báo lỗi; log có
`App Check activate failed`, hoặc request trả 403.

Thứ tự kiểm: token đăng ký đúng **app** chưa (token của app Android KHÔNG áp
dụng cho web và ngược lại) → có truyền `--dart-define-from-file` không → đúng
file cho đúng target không → `USE_DEBUG_APPCHECK` có `true` cho bản release
sideload không → reCAPTCHA có phải **v3** và đã khai domain chưa.
