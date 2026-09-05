# Build & deploy

App Check được bật **Enforced** cho Firebase AI Logic: request không kèm token
hợp lệ sẽ bị chặn, nên mọi tính năng AI phụ thuộc phần cấu hình dưới đây.

**Không hard-code token vào repo.** Chép `appcheck.example.json` thành
`appcheck.local.json` (đã gitignore), điền giá trị thật, rồi truyền bằng
`--dart-define-from-file`.

```bash
cp appcheck.example.json appcheck.local.json
```

---

## Web — reCAPTCHA v3

Bản web **không dùng debug token**. Debug token đặt trong `web/index.html` sẽ đi
thẳng vào bản deploy và ai xem source trang cũng đọc được.

Lấy site key: Firebase Console → App Check → app **web** → reCAPTCHA v3 → chép
*site key* (miễn phí). Điền vào `RECAPTCHA_SITE_KEY` trong `appcheck.local.json`.

```bash
flutter build web --dart-define-from-file=appcheck.local.json
```

```bash
firebase deploy --only hosting
```

Kiểm tra sau khi deploy — không được thấy dòng nào:

```bash
curl -s https://sakura-nihon.web.app | grep APPCHECK_DEBUG_TOKEN
```

---

## Android — APK gửi tay (sideload)

APK cài ngoài Google Play thì **Play Integrity luôn fail**, nên bản demo phải
dùng debug provider. Token sẽ nằm trong APK và moi ra được bằng
`unzip -p app.apk | grep -a <uuid>` — chấp nhận điều đó, nên:

- Dùng **một token riêng cho bản demo**, khác token máy dev.
- Đổi token khi phát hành bản mới; token cũ xoá trong Console là chết ngay.
- Bản lên Google Play thì **KHÔNG** bật `USE_DEBUG_APPCHECK` — Play Integrity lo.

Đăng ký token: Firebase Console → App Check → app `com.example.layout` →
Manage debug tokens → Add → dán UUID. Rồi điền UUID đó vào
`APP_CHECK_DEBUG_TOKEN` và đặt `USE_DEBUG_APPCHECK: true` trong
`appcheck.local.json`.

```bash
flutter build apk --release --dart-define-from-file=appcheck.local.json
```

File ra ở `build/app/outputs/flutter-apk/app-release.apk` — đổi tên rồi đính vào
GitHub Releases, **đừng commit vào repo**.

---

## Máy dev

Mỗi máy một token riêng, thu hồi được từng cái.

Cách 1 — để SDK tự sinh: chạy app với `APP_CHECK_DEBUG_TOKEN` bỏ trống, xem log
tìm dòng App Check in ra UUID, chép vào Console → Manage debug tokens.

Cách 2 — tự chọn trước một UUID, đăng ký trong Console, rồi:

```bash
flutter run --dart-define-from-file=appcheck.local.json
```

---

## Nếu bị chặn hết

Triệu chứng: app mở được, nhưng mọi tính năng AI báo lỗi; log có
`App Check activate failed` hoặc request trả 403.

Thứ tự kiểm: token đã đăng ký đúng **app** chưa (token đăng ký cho app Android
KHÔNG áp dụng cho web, và ngược lại) → có truyền `--dart-define-from-file`
không → `USE_DEBUG_APPCHECK` có đúng `true` cho bản release sideload không.
