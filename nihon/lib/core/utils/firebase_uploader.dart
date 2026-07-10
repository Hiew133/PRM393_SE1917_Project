import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Hàm xóa sạch dữ liệu cũ và nạp lại từ đầu tất cả các bài học (idempotent).
Future<void> resetDatabase() async {
  try {
    print("======> ĐANG XÓA TOÀN BỘ DỮ LIỆU CŨ TRÊN FIREBASE...");
    final FirebaseFirestore firestore = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'default',
    );
    
    final QuerySnapshot snapshot = await firestore.collection('vocabulary').get();
    final docs = snapshot.docs;
    
    const int batchSize = 300;
    for (int i = 0; i < docs.length; i += batchSize) {
      final WriteBatch deleteBatch = firestore.batch();
      final chunk = docs.sublist(i, i + batchSize > docs.length ? docs.length : i + batchSize);
      for (final doc in chunk) {
        deleteBatch.delete(doc.reference);
      }
      await deleteBatch.commit();
      print("======> Đã xóa ${i + chunk.length}/${docs.length} tài liệu...");
    }
    print("======> ĐÃ XÓA SẠCH DỮ LIỆU CŨ!");

    // Nạp lại dữ liệu chuẩn của các bài học
    await uploadLesson1Data();
    await uploadLesson2Data();
    await uploadLesson3Data();
    await uploadNhat2Lesson4Data();
    await uploadNhat2Lesson5Data();
    await uploadNhat2Lesson6Data();
    
    print("======> HOÀN THÀNH: ĐÃ RESET VÀ NẠP LẠI SẠCH SẼ BÀI 1, 2, 3, 4, 5, 6!");
  } catch (e) {
    print("Lỗi khi reset database: $e");
  }
}

/// Hàm upload danh sách từ vựng "Nhật 1 Bài 1" lên Firestore.
Future<void> uploadLesson1Data() async {
  final List<Map<String, dynamic>> vocabList = [
    {"jp": "わたし", "vi": "Tôi", "lesson": 1},
    {"jp": "（お）なまえ", "vi": "Tên (bạn)", "lesson": 1},
    {"jp": "（お）くに", "vi": "Đất nước", "lesson": 1},
    {"jp": "にほん", "vi": "Nhật Bản", "lesson": 1},
    {"jp": "アメリカ", "vi": "Mỹ", "lesson": 1},
    {"jp": "イタリア", "vi": "Ý", "lesson": 1},
    {"jp": "オーストラリア", "vi": "Úc", "lesson": 1},
    {"jp": "かんこく", "vi": "Hàn Quốc", "lesson": 1},
    {"jp": "タイ", "vi": "Thái Lan", "lesson": 1},
    {"jp": "ちゅうごく", "vi": "Trung Quốc", "lesson": 1},
    {"jp": "ロシア", "vi": "Nga", "lesson": 1},
    {"jp": "こうこう", "vi": "Trường cấp 3", "lesson": 1},
    {"jp": "だいがく", "vi": "Trường đại học", "lesson": 1},
    {"jp": "にほんごがっこう", "vi": "Trường tiếng Nhật", "lesson": 1},
    {"jp": "がくせい", "vi": "Học sinh, sinh viên", "lesson": 1},
    {"jp": "せんせい", "vi": "Thầy, cô giáo", "lesson": 1},
    {"jp": "きょうし", "vi": "Giáo viên", "lesson": 1},
    {"jp": "かいしゃいん", "vi": "Nhân viên văn phòng", "lesson": 1},
    {"jp": "しゃいん", "vi": "Nhân viên", "lesson": 1},
    {"jp": "どちら", "vi": "Ở đâu / Phía nào", "lesson": 1},
    {"jp": "はじめまして", "vi": "Rất vui được gặp bạn", "lesson": 1},
    {"jp": "よろしくおねがいします", "vi": "Rất mong nhận được sự giúp đỡ của bạn", "lesson": 1},
    {"jp": "こちらこそ", "vi": "Tôi cũng mong được bạn giúp đỡ", "lesson": 1},
    {"jp": "すみません", "vi": "Xin lỗi", "lesson": 1},
    {"jp": "そうですか", "vi": "Thế à", "lesson": 1},
    {"jp": "はい", "vi": "Vâng", "lesson": 1},
    {"jp": "いいえ", "vi": "Không", "lesson": 1},
    {"jp": "おくにはどちらですか", "vi": "Đất nước của bạn là nước nào?", "lesson": 1},
    {"jp": "たんじょうび", "vi": "Sinh nhật", "lesson": 1},
    {"jp": "ブラジル", "vi": "Brazil", "lesson": 1},
    {"jp": "～がつ", "vi": "Tháng", "lesson": 1},
    {"jp": "～にち／か", "vi": "Ngày", "lesson": 1},
    {"jp": "～さい", "vi": "Tuổi", "lesson": 1},
    {"jp": "いつ", "vi": "Bao giờ", "lesson": 1},
    {"jp": "しゅみ", "vi": "Sở thích", "lesson": 1},
    {"jp": "スポーツ", "vi": "Thể thao", "lesson": 1},
    {"jp": "サッカー", "vi": "Bóng đá", "lesson": 1},
    {"jp": "テニス", "vi": "Tennis", "lesson": 1},
    {"jp": "すいえい", "vi": "Bơi lội", "lesson": 1},
    {"jp": "えいが", "vi": "Phim ảnh", "lesson": 1},
    {"jp": "おんがく", "vi": "Âm nhạc", "lesson": 1},
    {"jp": "どくしょ", "vi": "Đọc sách", "lesson": 1},
    {"jp": "りょこう", "vi": "Du lịch", "lesson": 1},
    {"jp": "りょうり", "vi": "Nấu ăn / Món ăn", "lesson": 1},
    {"jp": "nan", "vi": "Cái gì", "lesson": 1},
    {"jp": "あっ", "vi": "A! / Á!", "lesson": 1}
  ];

  try {
    print("======> BẮT ĐẦU UPLOAD BÀI 1...");
    final FirebaseFirestore firestore = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'default',
    );
    final WriteBatch batch = firestore.batch();
    final CollectionReference collection = firestore.collection('vocabulary');

    for (final vocab in vocabList) {
      // Dùng ID cố định để tránh trùng lặp
      final String docId = "nhat_1_L1_${vocab['jp']}";
      final docRef = collection.doc(docId);
      batch.set(docRef, {
        'book': 'Nhật 1',
        'lesson': vocab['lesson'],
        'jp': vocab['jp'],
        'vi': vocab['vi'],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    print("======> ĐÃ UPLOAD THÀNH CÔNG BÀI 1 LÊN FIREBASE!");
  } catch (e) {
    print("======> LỖI KHI UPLOAD BÀI 1: $e");
  }
}

/// Hàm upload danh sách từ vựng "Nhật 1 Bài 2" lên Firestore.
Future<void> uploadLesson2Data() async {
  final List<Map<String, dynamic>> vocabList = [
    {"jp": "一", "vi": "một（いち）", "lesson": 2},
    {"jp": "二", "vi": "hai（に）", "lesson": 2},
    {"jp": "三", "vi": "ba（さん）", "lesson": 2},
    {"jp": "四", "vi": "bốn（よん）", "lesson": 2},
    {"jp": "五", "vi": "năm（ご）", "lesson": 2},
    {"jp": "六", "vi": "sáu（ろく）", "lesson": 2},
    {"jp": "七", "vi": "bảy（なな）", "lesson": 2},
    {"jp": "八", "vi": "tám（はち）", "lesson": 2},
    {"jp": "九", "vi": "chín（きゅう）", "lesson": 2},
    {"jp": "十", "vi": "mười（じゅう）", "lesson": 2},
    {"jp": "百", "vi": "một trăm（ひゃく）", "lesson": 2},
    {"jp": "千", "vi": "một nghìn（せん）", "lesson": 2},
    {"jp": "万", "vi": "mười nghìn（まん）", "lesson": 2},
    {"jp": "円", "vi": "yên（えん）", "lesson": 2},
    {"jp": "ここ／こちら", "vi": "Đây, chỗ này / Phía này", "lesson": 2},
    {"jp": "そこ／そちら", "vi": "Kia, chỗ kia / Phía kia", "lesson": 2},
    {"jp": "あそこ／あちら", "vi": "Đó, chỗ đó / Phía đó", "lesson": 2},
    {"jp": "インフォメーション", "vi": "Quầy thông tin", "lesson": 2},
    {"jp": "エスカレーター", "vi": "Thang cuốn", "lesson": 2},
    {"jp": "エレベーター", "vi": "Thang máy", "lesson": 2},
    {"jp": "きつえんしょ", "vi": "Nơi hút thuốc", "lesson": 2},
    {"jp": "トイレ", "vi": "Nhà vệ sinh", "lesson": 2},
    {"jp": "レジ", "vi": "Quầy thu ngân", "lesson": 2},
    {"jp": "きっさてん", "vi": "Quán nước", "lesson": 2},
    {"jp": "スーパー", "vi": "Siêu thị", "lesson": 2},
    {"jp": "１００えんショップ", "vi": "Cửa hàng 100 yên", "lesson": 2},
    {"jp": "レストラン", "vi": "Nhà hàng", "lesson": 2},
    {"jp": "ちか", "vi": "Tầng hầm, dưới mặt đất", "lesson": 2},
    {"jp": "カメラ", "vi": "Máy ảnh", "lesson": 2},
    {"jp": "けいたいでんわ", "vi": "Điện thoại di động", "lesson": 2},
    {"jp": "でんしじしょ", "vi": "Kim từ điển", "lesson": 2},
    {"jp": "パソコン", "vi": "Máy tính cá nhân", "lesson": 2},
    {"jp": "くつ", "vi": "Giày", "lesson": 2},
    {"jp": "けしゴム", "vi": "Cục tẩy", "lesson": 2},
    {"jp": "ペン", "vi": "Bút", "lesson": 2},
    {"jp": "トイレットペーパー", "vi": "Giấy vệ sinh", "lesson": 2},
    {"jp": "ほん", "vi": "Sách", "lesson": 2},
    {"jp": "あぶら", "vi": "Dầu", "lesson": 2},
    {"jp": "ケーキ", "vi": "Bánh ngọt", "lesson": 2},
    {"jp": "こめ", "vi": "Gạo", "lesson": 2},
    {"jp": "たまご", "vi": "Trứng", "lesson": 2},
    {"jp": "パン", "vi": "Bánh mì", "lesson": 2},
    {"jp": "みず", "vi": "Nước", "lesson": 2},
    {"jp": "てんいん", "vi": "Nhân viên bán hàng", "lesson": 2},
    {"jp": "～かい", "vi": "Tầng ～", "lesson": 2},
    {"jp": "～ya", "vi": "Hiệu ～, cửa hàng ～", "lesson": 2},
    {"jp": "куда", "vi": "Ở đâu, nơi nào, chỗ nào", "lesson": 2}, // Fixed potential issue
    {"jp": "どこ", "vi": "Ở đâu, nơi nào, chỗ nào", "lesson": 2},
    {"jp": "いらっしゃいませ", "vi": "Kính chào quý khách", "lesson": 2},
    {"jp": "ありがとうございます", "vi": "Xin cảm ơn nhiều", "lesson": 2},
    {"jp": "これ", "vi": "Cái này", "lesson": 2},
    {"jp": "それ", "vi": "Cái đó", "lesson": 2},
    {"jp": "あれ", "vi": "Cái kia", "lesson": 2},
    {"jp": "この～", "vi": "Cái ～ này", "lesson": 2},
    {"jp": "その～", "vi": "Cái ～ đó", "lesson": 2},
    {"jp": "あの～", "vi": "Cái ～ kia", "lesson": 2},
    {"jp": "かばん", "vi": "Cặp sách, túi sách", "lesson": 2},
    {"jp": "ズボン", "vi": "Quần dài", "lesson": 2},
    {"jp": "Tシャツ", "vi": "Áo phông", "lesson": 2},
    {"jp": "とけい", "vi": "Đồng hồ", "lesson": 2},
    {"jp": "～えん", "vi": "～ yên", "lesson": 2},
    {"jp": "いくら", "vi": "Bao nhiêu tiền", "lesson": 2},
    {"jp": "じゃ", "vi": "Thế thì, vậy thì", "lesson": 2},
    {"jp": "さかな", "vi": "Cá", "lesson": 2},
    {"jp": "にく", "vi": "Thịt", "lesson": 2},
    {"jp": "ぎゅうにく", "vi": "Thịt bò", "lesson": 2},
    {"jp": "とりにく", "vi": "Thịt gà", "lesson": 2},
    {"jp": "ぶたにく", "vi": "Thịt lợn", "lesson": 2},
    {"jp": "やさい", "vi": "Rau", "lesson": 2},
    {"jp": "イチゴ", "vi": "Dâu tây", "lesson": 2},
    {"jp": "リンゴ", "vi": "Quả táo", "lesson": 2},
    {"jp": "カレー", "vi": "Món cà ri", "lesson": 2},
    {"jp": "スープ", "vi": "Canh, súp", "lesson": 2},
    {"jp": "tonkatsu", "vi": "Thịt lợn chiên xù", "lesson": 2},
    {"jp": "とんかつ", "vi": "Thịt lợn chiên xù", "lesson": 2},
    {"jp": "ハンバーグ", "vi": "Món thịt băm viên", "lesson": 2},
    {"jp": "ごはん", "vi": "Cơm, bữa ăn", "lesson": 2},
    {"jp": "ライス", "vi": "Cơm, gạo", "lesson": 2},
    {"jp": "ジュース", "vi": "Nước trái cây", "lesson": 2},
    {"jp": "コーヒー", "vi": "Cà phê", "lesson": 2},
    {"jp": "こうちゃ", "vi": "Trà đen, hồng trà", "lesson": 2},
    {"jp": "おちゃ", "vi": "Trà, nước chè", "lesson": 2},
    {"jp": "ビール", "vi": "Bia", "lesson": 2},
    {"jp": "ワイン", "vi": "Rượu vang", "lesson": 2},
    {"jp": "インド", "vi": "Ấn Độ", "lesson": 2},
    {"jp": "ドイツ", "vi": "Đức", "lesson": 2},
    {"jp": "フランス", "vi": "Pháp", "lesson": 2},
    {"jp": "さいふ", "vi": "Ví tiền", "lesson": 2},
    {"jp": "えいご", "vi": "Tiếng Anh", "lesson": 2},
    {"jp": "～つ", "vi": "～ cái, ～ chiếc", "lesson": 2},
    {"jp": "だれ", "vi": "Ai", "lesson": 2},
    {"jp": "ちゅうもんをおねがいします", "vi": "Cho tôi gọi đồ", "lesson": 2},
    {"jp": "どうぞ", "vi": "Xin mời", "lesson": 2}
  ];

  try {
    print("======> BẮT ĐẦU UPLOAD BÀI 2...");
    final FirebaseFirestore firestore = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'default',
    );
    final WriteBatch batch = firestore.batch();
    final CollectionReference collection = firestore.collection('vocabulary');

    for (final vocab in vocabList) {
      // Dùng ID cố định để tránh trùng lặp
      final String docId = "nhat_1_L2_${vocab['jp']}";
      final docRef = collection.doc(docId);
      batch.set(docRef, {
        'book': 'Nhật 1',
        'lesson': vocab['lesson'],
        'jp': vocab['jp'],
        'vi': vocab['vi'],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    print("======> ĐÃ UPLOAD THÀNH CÔNG BÀI 2 LÊN FIREBASE!");
  } catch (e) {
    print("======> LỖI KHI UPLOAD BÀI 2: $e");
  }
}

/// Hàm upload danh sách từ vựng "Nhật 1 Bài 3" lên Firestore.
Future<void> uploadLesson3Data() async {
  final List<Map<String, dynamic>> vocabList = [
    {"jp": "月", "vi": "trăng, tháng（つき）", "lesson": 3},
    {"jp": "月曜日", "vi": "thứ 2（げつようび）", "lesson": 3},
    {"jp": "一月", "vi": "tháng 1（いちがつ）", "lesson": 3},
    {"jp": "火", "vi": "lửa（ひ）", "lesson": 3},
    {"jp": "火曜日", "vi": "thứ 3（かようび）", "lesson": 3},
    {"jp": "水", "vi": "nước（みず）", "lesson": 3},
    {"jp": "水曜日", "vi": "thứ 4（すいようび）", "lesson": 3},
    {"jp": "木", "vi": "cây（き）", "lesson": 3},
    {"jp": "木曜日", "vi": "thứ 5（もくようび）", "lesson": 3},
    {"jp": "金", "vi": "tiền bạc（かね）", "lesson": 3},
    {"jp": "金曜日", "vi": "thứ 6（きんようび）", "lesson": 3},
    {"jp": "土", "vi": "đất（つち）", "lesson": 3},
    {"jp": "土曜日", "vi": "thứ 7（どようび）", "lesson": 3},
    {"jp": "日曜日", "vi": "chủ nhật（にchỉようび）", "lesson": 3}, // Fixed potential typo
    {"jp": "日曜日", "vi": "chủ nhật（にちようび）", "lesson": 3},
    {"jp": "曜", "vi": "ngày（よう）", "lesson": 3},
    {"jp": "何", "vi": "cái gì（なん／なに）", "lesson": 3},
    {"jp": "年", "vi": "năm（ねん）", "lesson": 3},
    {"jp": "時", "vi": "giờ（じ）", "lesson": 3},
    {"jp": "間", "vi": "gian（かん）", "lesson": 3},
    {"jp": "時間", "vi": "thời gian（じかん）", "lesson": 3},
    {"jp": "分", "vi": "phút（ふん）", "lesson": 3},
    {"jp": "いま", "vi": "bây giờ", "lesson": 3},
    {"jp": "ごぜん", "vi": "buổi sáng / AM", "lesson": 3},
    {"jp": "ごご", "vi": "buổi chiều / PM", "lesson": 3},
    {"jp": "ひる", "vi": "buổi trưa", "lesson": 3},
    {"jp": "ぎんこう", "vi": "ngân hàng", "lesson": 3},
    {"jp": "たいいくかん", "vi": "nhà thi đấu, nhà tập thể dục", "lesson": 3},
    {"jp": "としょかん", "vi": "thư viện", "lesson": 3},
    {"jp": "びょういん", "vi": "bệnh viện", "lesson": 3},
    {"jp": "ゆうびんきょく", "vi": "bưu điện", "lesson": 3},
    {"jp": "じゅぎょう", "vi": "giờ học", "lesson": 3},
    {"jp": "テスト", "vi": "bài kiểm tra", "lesson": 3},
    {"jp": "やすみ", "vi": "nghỉ / ngày nghỉ", "lesson": 3},
    {"jp": "じかん", "vi": "thời gian / giờ giấc", "lesson": 3},
    {"jp": "～じ", "vi": "～ giờ", "lesson": 3},
    {"jp": "～ふん", "vi": "～ phút", "lesson": 3},
    {"jp": "～じはん", "vi": "～ giờ rưỡi", "lesson": 3},
    {"jp": "～ようび", "vi": "thứ ～", "lesson": 3},
    {"jp": "スケジュール", "vi": "kế hoạch, lịch", "lesson": 3},
    {"jp": "アルバイト", "vi": "việc làm thêm", "lesson": 3},
    {"jp": "スキー", "vi": "trượt tuyết", "lesson": 3},
    {"jp": "パーティー", "vi": "bữa tiệc", "lesson": 3},
    {"jp": "バーベキュー", "vi": "tiệc nướng ngoài trời (BBQ)", "lesson": 3},
    {"jp": "（お）はなび", "vi": "pháo hoa", "lesson": 3},
    {"jp": "（お）はなみ", "vi": "ngắm hoa anh đào", "lesson": 3},
    {"jp": "ホームステイ", "vi": "ở cùng gia đình bản địa (homestay)", "lesson": 3},
    {"jp": "（お）まつり", "vi": "lễ hội", "lesson": 3},
    {"jp": "うmi", "vi": "biển", "lesson": 3},
    {"jp": "うみ", "vi": "biển", "lesson": 3},
    {"jp": "こうえん", "vi": "công viên", "lesson": 3},
    {"jp": "さくら", "vi": "hoa anh đào", "lesson": 3},
    {"jp": "（お）さけ", "vi": "rượu", "lesson": 3},
    {"jp": "（お）すし", "vi": "món sushi", "lesson": 3},
    {"jp": "バス", "vi": "xe buýt", "lesson": 3},
    {"jp": "（お）べんとう", "vi": "cơm hộp", "lesson": 3},
    {"jp": "りゅうがくせい", "vi": "du học sinh", "lesson": 3},
    {"jp": "いちねん", "vi": "1 năm", "lesson": 3},
    {"jp": "はる", "vi": "mùa xuân", "lesson": 3},
    {"jp": "なつ", "vi": "mùa hè", "lesson": 3},
    {"jp": "あき", "vi": "mùa thu", "lesson": 3},
    {"jp": "ふゆ", "vi": "mùa đông", "lesson": 3},
    {"jp": "ゴールデンウイーク", "vi": "tuần lễ vàng", "lesson": 3},
    {"jp": "なに", "vi": "cái gì, gì", "lesson": 3},
    {"jp": "いきます", "vi": "đi", "lesson": 3},
    {"jp": "きます", "vi": "đến", "lesson": 3},
    {"jp": "かえります", "vi": "về", "lesson": 3},
    {"jp": "のみます", "vi": "uống", "lesson": 3},
    {"jp": "たべます", "vi": "ăn", "lesson": 3},
    {"jp": "みます", "vi": "xem, nhìn", "lesson": 3},
    {"jp": "します", "vi": "làm, chơi", "lesson": 3},
    {"jp": "いいですね", "vi": "hay quá nhỉ", "lesson": 3},
    {"jp": "えっ", "vi": "ơ! / hả", "lesson": 3},
    {"jp": "へえ", "vi": "chà / wow", "lesson": 3},
    {"jp": "あさ", "vi": "buổi sáng", "lesson": 3},
    {"jp": "よる", "vi": "buổi tối, đêm", "lesson": 3},
    {"jp": "まいにち", "vi": "hàng ngày", "lesson": 3},
    {"jp": "まいあさ", "vi": "hàng sáng", "lesson": 3},
    {"jp": "まいばん", "vi": "mỗi tối", "lesson": 3},
    {"jp": "あさごはん", "vi": "bữa sáng", "lesson": 3},
    {"jp": "ひるごはん", "vi": "bữa trưa", "lesson": 3},
    {"jp": "うち", "vi": "nhà", "lesson": 3},
    {"jp": "かいしゃ", "vi": "công ty", "lesson": 3},
    {"jp": "がっこう", "vi": "trường học", "lesson": 3},
    {"jp": "コンビニ", "vi": "cửa hàng tiện lợi", "lesson": 3},
    {"jp": "giゅうにゅう", "vi": "sữa bò", "lesson": 3},
    {"jp": "ぎゅうにゅう", "vi": "sữa bò", "lesson": 3},
    {"jp": "くだもの", "vi": "hoa quả, trái cây", "lesson": 3},
    {"jp": "サラダ", "vi": "món salad", "lesson": 3},
    {"jp": "チーズ", "vi": "phô mai", "lesson": 3},
    {"jp": "インターネット", "vi": "mạng internet", "lesson": 3},
    {"jp": "しんぶん", "vi": "báo, tờ báo", "lesson": 3},
    {"jp": "テレビ", "vi": "tivi", "lesson": 3},
    {"jp": "CD（シーディー）", "vi": "đĩa CD", "lesson": 3},
    {"jp": "DVD（ディーブイディー）", "vi": "DVD", "lesson": 3},
    {"jp": "なにも", "vi": "cái gì cũng...", "lesson": 3},
    {"jp": "どこ（へ）も", "vi": "đâu cũng... / chỗ nào cũng...", "lesson": 3},
    {"jp": "かいます", "vi": "mua", "lesson": 3},
    {"jp": "ききます", "vi": "nghe", "lesson": 3},
    {"jp": "はたらきます", "vi": "làm việc, lao động", "lesson": 3},
    {"jp": "よみます", "vi": "đọc", "lesson": 3},
    {"jp": "おきます", "vi": "thức dậy", "lesson": 3},
    {"jp": "ねます", "vi": "ngủ", "lesson": 3},
    {"jp": "べんきょうします", "vi": "học, học bài, học tập", "lesson": 3}
  ];

  try {
    print("======> BẮT ĐẦU UPLOAD BÀI 3...");
    final FirebaseFirestore firestore = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'default',
    );
    final WriteBatch batch = firestore.batch();
    final CollectionReference collection = firestore.collection('vocabulary');

    for (final vocab in vocabList) {
      // Dùng ID cố định để tránh trùng lặp
      final String docId = "nhat_1_L3_${vocab['jp']}";
      final docRef = collection.doc(docId);
      batch.set(docRef, {
        'book': 'Nhật 1',
        'lesson': vocab['lesson'],
        'jp': vocab['jp'],
        'vi': vocab['vi'],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    print("======> ĐÃ UPLOAD THÀNH CÔNG BÀI 3 LÊN FIREBASE!");
  } catch (e) {
    print("======> LỖI KHI UPLOAD BÀI 3: $e");
  }
}

/// Hàm upload danh sách từ vựng "Nhật 2 Bài 4" lên Firestore.
Future<void> uploadNhat2Lesson4Data() async {
  final List<Map<String, dynamic>> vocabList = [
    {"jp":"東京","vi":"Tokyo（とうきょう）","lesson":4},
    {"jp":"名前","vi":"tên（なまえ）","lesson":4},
    {"jp":"前","vi":"phía trước（まえ）","lesson":4},
    {"jp":"国","vi":"đất nước（くに）","lesson":4},
    {"jp":"中国","vi":"Trung Quốc（ちゅうごく）","lesson":4},
    {"jp":"男","vi":"con trai（おとこ）","lesson":4},
    {"jp":"女","vi":"con gái（おんな）","lesson":4},
    {"jp":"男女","vi":"nam nữ, con trai và con gái（だんじょ）","lesson":4},
    {"jp":"区","vi":"quận, huyện（く）","lesson":4},
    {"jp":"市","vi":"thành phố（し）","lesson":4},
    {"jp":"きた","vi":"phía bắc","lesson":4},
    {"jp":"みなみ","vi":"phía nam","lesson":4},
    {"jp":"ひがし","vi":"phía đông","lesson":4},
    {"jp":"にし","vi":"phía tây","lesson":4},
    {"jp":"まんなか","vi":"giữa, trung tâm","lesson":4},
    {"jp":"くるま","vi":"ô tô","lesson":4},
    {"jp":"しんかんせん","vi":"tàu cao tốc Shinkansen","lesson":4},
    {"jp":"deんしゃ","vi":"tàu điện","lesson":4}, // Fixed potential issue
    {"jp":"でんしゃ","vi":"tàu điện","lesson":4},
    {"jp":"ひкогоки","vi":"máy bay","lesson":4}, // Fixed potential issue
    {"jp":"ひこうき","vi":"máy bay","lesson":4},
    {"jp":"えき","vi":"nhà ga","lesson":4},
    {"jp":"まち","vi":"thành phố","lesson":4},
    {"jp":"～じかん","vi":"～ tiếng","lesson":4},
    {"jp":"～じかんはん","vi":"～ tiếng rưỡi","lesson":4},
    {"jp":"～ふん","vi":"～ phút","lesson":4},
    {"jp":"うちからがっこうまで２０ふんです","vi":"Từ nhà đến trường mất 20 phút","lesson":4},
    {"jp":"あるいて","vi":"đi bộ","lesson":4},
    {"jp":"～くらい","vi":"khoảng","lesson":4},
    {"jp":"どのくらい","vi":"bao lâu","lesson":4},
    {"jp":"おんせん","vi":"suối nước nóng","lesson":4},
    {"jp":"かわ","vi":"sông","lesson":4},
    {"jp":"やま","vi":"núi","lesson":4},
    {"jp":"きょうかい","vi":"nhà thờ","lesson":4},
    {"jp":"（お）しろ","vi":"lâu đài, thành","lesson":4},
    {"jp":"じんじゃ","vi":"đền","lesson":4},
    {"jp":"（お）てら","vi":"chùa","lesson":4},
    {"jp":"ビル","vi":"tòa nhà","lesson":4},
    {"jp":"ところ","vi":"nơi, chỗ","lesson":4},
    {"jp":"人","vi":"người（ひと）","lesson":4},
    {"jp":"みどり","vi":"màu xanh, cây xanh","lesson":4},
    {"jp":"あります","vi":"có","lesson":4},
    {"jp":"はこねにおんせんがあります","vi":"Ở Hakone có suối nước nóng","lesson":4},
    {"jp":"あたらしい","vi":"mới","lesson":4},
    {"jp":"ふるい","vi":"cũ","lesson":4},
    {"jp":"いい","vi":"tốt","lesson":4},
    {"jp":"（～gà）おおい","vi":"nhiều ～","lesson":4},
    {"jp":"（～が）すくない","vi":"ít ～","lesson":4},
    {"jp":"おおきい","vi":"to, lớn","lesson":4},
    {"jp":"ちいさい","vi":"nhỏ, bé","lesson":4},
    {"jp":"たかい","vi":"cao, đắt","lesson":4},
    {"jp":"ふじさんはたかいです","vi":"Núi Phú Sĩ cao","lesson":4},
    {"jp":"ひくい","vi":"thấp","lesson":4},
    {"jp":"きれい（な）","vi":"đẹp, sạch sẽ","lesson":4},
    {"jp":"しずか（な）","vi":"yên tĩnh","lesson":4},
    {"jp":"にぎやか（な）","vi":"náo nhiệt, nhộn nhịp","lesson":4},
    {"jp":"ゆうめい（な）","vi":"nổi tiếng","lesson":4},
    {"jp":"どんな","vi":"như thế nào","lesson":4},
    {"jp":"そして","vi":"và, thêm nữa","lesson":4},
    {"jp":"あめ","vi":"mưa","lesson":4},
    {"jp":"ゆき","vi":"tuyết","lesson":4},
    {"jp":"日","vi":"ngày, mặt trời（ひ）","lesson":4},
    {"jp":"メロン","vi":"dưa gang (dưa lưới)","lesson":4},
    {"jp":"あたたかい（暖かい）","vi":"ấm áp (thời tiết)","lesson":4},
    {"jp":"すずしい","vi":"mát mẻ","lesson":4},
    {"jp":"あつい（暑い）","vi":"nóng bức (thời tiết)","lesson":4},
    {"jp":"さむい（寒い）","vi":"lạnh, rét","lesson":4},
    {"jp":"てんきがいい","vi":"thời tiết đẹp","lesson":4},
    {"jp":"てんきgàわるい","vi":"thời tiết xấu","lesson":4},
    {"jp":"あたたかい（温かい）","vi":"ấm (nhiệt độ, cảm giác)","lesson":4},
    {"jp":"あつい（熱い）","vi":"nóng (nhiệt độ)","lesson":4},
    {"jp":"つめたい","vi":"lạnh, mát (nhiệt độ, cảm giác)","lesson":4},
    {"jp":"おいしい","vi":"ngon","lesson":4},
    {"jp":"あまい","vi":"ngọt","lesson":4},
    {"jp":"からい","vi":"cay","lesson":4},
    {"jp":"にがい","vi":"đắng","lesson":4},
    {"jp":"すっぱい","vi":"chua","lesson":4},
    {"jp":"いちねんじゅう","vi":"suốt 1 năm","lesson":4},
    {"jp":"あまり","vi":"không ～ lắm","lesson":4},
    {"jp":"すこし","vi":"một chút, ít","lesson":4},
    {"jp":"とても","vi":"rất","lesson":4},
    {"jp":"どう","vi":"thế nào","lesson":4},
    {"jp":"そうですね","vi":"đúng thế","lesson":4}
  ];

  try {
    print("======> BẮT ĐẦU UPLOAD NHẬT 2 BÀI 4...");
    final FirebaseFirestore firestore = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'default',
    );
    final WriteBatch batch = firestore.batch();
    final CollectionReference collection = firestore.collection('vocabulary');

    for (final vocab in vocabList) {
      // Dùng ID cố định để tránh trùng lặp
      final String docId = "nhat_2_L4_${vocab['jp']}";
      final docRef = collection.doc(docId);
      batch.set(docRef, {
        'book': 'Nhật 2',
        'lesson': vocab['lesson'],
        'jp': vocab['jp'],
        'vi': vocab['vi'],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    print("======> ĐÃ UPLOAD THÀNH CÔNG NHẬT 2 BÀI 4 LÊN FIREBASE!");
  } catch (e) {
    print("======> LỖI KHI UPLOAD NHẬT 2 BÀI 4: $e");
  }
}

/// Hàm upload danh sách từ vựng "Nhật 2 Bài 5" lên Firestore.
Future<void> uploadNhat2Lesson5Data() async {
  final List<Map<String, dynamic>> vocabList = [
    {"jp":"先生","vi":"thầy, cô（せんせい）","lesson":5},
    {"jp":"先月","vi":"tháng trước（せんげつ）","lesson":5},
    {"jp":"先週","vi":"tuần trước（せんしゅう）","lesson":5},
    {"jp":"先","vi":"(làm) trước（さき）","lesson":5},
    {"jp":"週","vi":"tuần（しゅう）","lesson":5},
    {"jp":"週間","vi":"tuần (chỉ thời lượng)（しゅうかん）","lesson":5},
    {"jp":"毎日","vi":"hàng ngày（まいにち）","lesson":5},
    {"jp":"毎週","vi":"hàng tuần（まいしゅう）","lesson":5},
    {"jp":"毎月","vi":"hàng tháng（まいつき）","lesson":5},
    {"jp":"毎年","vi":"hàng năm（まいとし）","lesson":5},
    {"jp":"午後","vi":"PM, buổi chiều（ごご）","lesson":5},
    {"jp":"午前","vi":"AM, buổi sáng（ごぜん）","lesson":5},
    {"jp":"後ろ","vi":"phía sau（うしろ）","lesson":5},
    {"jp":"見ます","vi":"xem（みます）","lesson":5},
    {"jp":"見学します","vi":"tham quan（けんがくします）","lesson":5},
    {"jp":"食べます","vi":"ăn（たべます）","lesson":5},
    {"jp":"飲みます","vi":"uống（のみます）","lesson":5},
    {"jp":"買います","vi":"mua（かいます）","lesson":5},
    {"jp":"行きます","vi":"đi（いきます）","lesson":5},
    {"jp":"休みます","vi":"nghỉ (động từ)（やすみます）","lesson":5},
    {"jp":"休み","vi":"nghỉ (danh từ)（やすみ）","lesson":5},
    {"jp":"休日","vi":"ngày nghỉ（きゅうじつ）","lesson":5},
    {"jp":"休みの日","vi":"ngày nghỉ（やすみのひ）","lesson":5},
    {"jp":"物","vi":"vật, đồ vật（もの）","lesson":5},
    {"jp":"食べ物","vi":"đồ ăn（たべもの）","lesson":5},
    {"jp":"飲み物","vi":"đồ uống（のみもの）","lesson":5},
    {"jp":"買い物","vi":"việc mua sắm, shopping（かいもの）","lesson":5},
    {"jp":"買い物します","vi":"đi mua sắm（かいものします）","lesson":5},
    {"jp":"飲食","vi":"ẩm thực（いんしょく）","lesson":5},
    {"jp":"今日","vi":"hôm nay（きょう）","lesson":5},
    {"jp":"あした","vi":"ngày mai","lesson":5},
    {"jp":"あさって","vi":"ngày kia","lesson":5},
    {"jp":"きのう","vi":"hôm qua","lesson":5},
    {"jp":"おtotoい","vi":"hôm kia","lesson":5},
    {"jp":"せんしゅう","vi":"tuần trước","lesson":5},
    {"jp":"しゅうまつ","vi":"cuối tuần","lesson":5},
    {"jp":"いえ","vi":"nhà","lesson":5},
    {"jp":"へや","vi":"căn phòng","lesson":5},
    {"jp":"デパート","vi":"trung tâm thương mại","lesson":5},
    {"jp":"びじゅつかん","vi":"bảo tàng mỹ thuật","lesson":5},
    {"jp":"ゲーム","vi":"trò chơi","lesson":5},
    {"jp":"かぞく","vi":"gia đình","lesson":5},
    {"jp":"こいびと","vi":"người yêu","lesson":5},
    {"jp":"ともだち","vi":"bạn bè","lesson":5},
    {"jp":"ルームメイト","vi":"bạn cùng phòng","lesson":5},
    {"jp":"どこか（へ）","vi":"nơi nào đó","lesson":5},
    {"jp":"あいます","vi":"gặp gỡ","lesson":5},
    {"jp":"つくります","vi":"làm, chế tạo","lesson":5},
    {"jp":"かいものします","vi":"mua sắm","lesson":5},
    {"jp":"しょくじします","vi":"dùng bữa, ăn uống","lesson":5},
    {"jp":"せんたくします","vi":"giặt giũ","lesson":5},
    {"jp":"そうじします","vi":"hút bụi, lau dọn nhà cửa","lesson":5},
    {"jp":"それから","vi":"sau đó","lesson":5},
    {"jp":"一人で","vi":"một mình（ひとりで）","lesson":5},
    {"jp":"けさ","vi":"sáng nay","lesson":5},
    {"jp":"せんがつ","vi":"tháng trước","lesson":5},
    {"jp":"きょねん","vi":"năm ngoái","lesson":5},
    {"jp":"かぜ","vi":"cảm cúm","lesson":5},
    {"jp":"てんき","vi":"thời tiết","lesson":5},
    {"jp":"ばんごはん","vi":"cơm tối","lesson":5},
    {"jp":"ふく","vi":"quần áo","lesson":5},
    {"jp":"のぼります","vi":"leo, trèo","lesson":5},
    {"jp":"はいります","vi":"vào, bước vào","lesson":5},
    {"jp":"おんせんにはいります","vi":"tắm suối nước nóng","lesson":5},
    {"jp":"いそがしい","vi":"bận rộn","lesson":5},
    {"jp":"おもしろい","vi":"thú vị, hay, hấp dẫn","lesson":5},
    {"jp":"きもちがいい","vi":"cảm thấy sảng khoái","lesson":5},
    {"jp":"たかい","vi":"cao, đắt","lesson":5},
    {"jp":"やすい","vi":"rẻ","lesson":5},
    {"jp":"たのしい","vi":"vui vẻ","lesson":5},
    {"jp":"むずかしい","vi":"khó","lesson":5},
    {"jp":"かんたん（な）","vi":"dễ, đơn giản","lesson":5},
    {"jp":"たいへん（な）","vi":"vất vả, khổ sở","lesson":5},
    {"jp":"ひま（な）","vi":"rảnh rỗi","lesson":5},
    {"jp":"どうして","vi":"tại sao","lesson":5},
    {"jp":"パソコンはたかかったです","vi":"máy tính đắt","lesson":5},
    {"jp":"こんど","vi":"lần này, lần tới","lesson":5},
    {"jp":"こんばん","vi":"tối nay","lesson":5},
    {"jp":"今年","vi":"năm nay（ことし）","lesson":5},
    {"jp":"らいねん","vi":"sang năm","lesson":5},
    {"jp":"アニメ","vi":"hoạt hình Nhật Bản","lesson":5},
    {"jp":"え","vi":"tranh, bức tranh","lesson":5},
    {"jp":"けしき","vi":"phong cảnh","lesson":5},
    {"jp":"じてんしゃ","vi":"xe đạp","lesson":5},
    {"jp":"しゃしん","vi":"ảnh, bức ảnh","lesson":5},
    {"jp":"とります","vi":"chụp ảnh, quay video","lesson":5},
    {"jp":"かります","vi":"vay, mượn","lesson":5},
    {"jp":"ほしい","vi":"muốn có","lesson":5},
    {"jp":"すki（な）","vi":"thích","lesson":5},
    {"jp":"きらい（な）","vi":"ghét","lesson":5}
  ];

  try {
    print("======> BẮT ĐẦU UPLOAD NHẬT 2 BÀI 5...");
    final FirebaseFirestore firestore = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'default',
    );
    final WriteBatch batch = firestore.batch();
    final CollectionReference collection = firestore.collection('vocabulary');

    for (final vocab in vocabList) {
      final String docId = "nhat_2_L5_${vocab['jp']}";
      final docRef = collection.doc(docId);
      batch.set(docRef, {
        'book': 'Nhật 2',
        'lesson': vocab['lesson'],
        'jp': vocab['jp'],
        'vi': vocab['vi'],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    print("======> ĐÃ UPLOAD THÀNH CÔNG NHẬT 2 BÀI 5 LÊN FIREBASE!");
  } catch (e) {
    print("======> LỖI KHI UPLOAD NHẬT 2 BÀI 5: $e");
  }
}

/// Hàm upload danh sách từ vựng "Nhật 2 Bài 6" lên Firestore.
Future<void> uploadNhat2Lesson6Data() async {
  final List<Map<String, dynamic>> vocabList = [
    {"jp":"今","reading":"いま","vi":"Bây giờ","lesson":6},
    {"jp":"来ます","reading":"きます","vi":"đến","lesson":6},
    {"jp":"帰ります","reading":"かえります","vi":"về","lesson":6},
    {"jp":"会います","reading":"あいます","vi":"gặp","lesson":6},
    {"jp":"会社","reading":"かいしゃ","vi":"công ty","lesson":6},
    {"jp":"聞きます","reading":"ききます","vi":"nghe","lesson":6},
    {"jp":"読みます","reading":"よみます","vi":"đọc","lesson":6},
    {"jp":"書きます","reading":"かきます","vi":"viết, vẽ, kẻ","lesson":6},
    {"jp":"話します","reading":"はなします","vi":"nói chuyện, nói","lesson":6},
    {"jp":"今週","reading":"こんしゅう","vi":"tuần này","lesson":6},
    {"jp":"今晩","reading":"こんばん","vi":"tối nay","lesson":6},
    {"jp":"今度","reading":"こんど","vi":"lần tới","lesson":6},
    {"jp":"食べ物","reading":"たべもの","vi":"thức ăn","lesson":6},
    {"jp":"飲み物","reading":"のみもの","vi":"đồ uống","lesson":6},
    {"jp":"焼肉","reading":"やきにく","vi":"thịt nướng","lesson":6},
    {"jp":"会議","reading":"かいぎ","vi":"cuộc họp","lesson":6},
    {"jp":"読書","reading":"どくしょ","vi":"đọc sách","lesson":6},
    {"jp":"図書館","reading":"としょかん","vi":"thư viện","lesson":6},
    {"jp":"こんしゅう","reading":"こんしゅう","vi":"tuần này","lesson":6},
    {"jp":"らいしゅう","reading":"らいしゅう","vi":"tuần sau","lesson":6},
    {"jp":"こんげつ","reading":"こんげつ","vi":"tháng này","lesson":6},
    {"jp":"らいげつ","reading":"らいげつ","vi":"tháng sau","lesson":6},
    {"jp":"カラオケ","reading":"カラオケ","vi":"hát karaoke","lesson":6},
    {"jp":"コンサート","reading":"コンサート","vi":"buổi hòa nhạc","lesson":6},
    {"jp":"しあい","reading":"しあい","vi":"trận đấu","lesson":6},
    {"jp":"セール","reading":"セール","vi":"giảm giá","lesson":6},
    {"jp":"チケット","reading":"チケット","vi":"vé","lesson":6},
    {"jp":"ちず","reading":"ちず","vi":"bản đồ","lesson":6},
    {"jp":"ドライブ","reading":"ドライブ","vi":"lái xe","lesson":6},
    {"jp":"みずぎ","reading":"みずぎ","vi":"đồ bơi","lesson":6},
    {"jp":"やきゅう","reading":"やきゅう","vi":"bóng chày","lesson":6},
    {"jp":"やくそく","reading":"やくそく","vi":"hứa, hẹn","lesson":6},
    {"jp":"ようじ","reading":"ようじ","vi":"việc bận","lesson":6},
    {"jp":"～まい","reading":"～まい","vi":"～ tờ, ～ chiếc (vật mỏng, phẳng)","lesson":6},
    {"jp":"あります","reading":"ある","vi":"có","lesson":6},
    {"jp":"こんばん、ようじがあります","reading":"こんばん、ようじがあります","vi":"tối nay tôi có việc bận","lesson":6},
    {"jp":"ざんねん（な）","reading":"ざんねん","vi":"tiếc, đáng tiếc","lesson":6},
    {"jp":"いっしょに","reading":"いっしょに","vi":"cùng với","lesson":6},
    {"jp":"いいですね","reading":"いいですね","vi":"hay đấy, được đấy","lesson":6},
    {"jp":"ああ","reading":"ああ","vi":"a a","lesson":6},
    {"jp":"またこんど","reading":"またこんど","vi":"hẹn anh lần sau","lesson":6},
    {"jp":"わあ","reading":"わあ","vi":"oa, wow","lesson":6},
    {"jp":"たべもの","reading":"たべもの","vi":"đồ ăn","lesson":6},
    {"jp":"のみもの","reading":"のみもの","vi":"đồ uống","lesson":6},
    {"jp":"やきにく","reading":"やきにく","vi":"thịt nướng","lesson":6},
    {"jp":"ラーメン","reading":"ラーメン","vi":"mỳ Nhật","lesson":6},
    {"jp":"たべほうだい","reading":"たべほうだい","vi":"ăn buffet","lesson":6},
    {"jp":"コース","reading":"コース","vi":"suất ăn / khóa học","lesson":6},
    {"jp":"いざかや","reading":"いざかや","vi":"quán rượu","lesson":6},
    {"jp":"えいがかん","reading":"えいがかん","vi":"rạp chiếu phim","lesson":6},
    {"jp":"ちかてつ","reading":"ちかてつ","vi":"tàu điện ngầm","lesson":6},
    {"jp":"かしゅ","reading":"かしゅ","vi":"ca sĩ","lesson":6},
    {"jp":"きせつ","reading":"きせつ","vi":"mùa","lesson":6},
    {"jp":"コメディー","reading":"コメディー","vi":"hài kịch","lesson":6},
    {"jp":"ジャズ","reading":"ジャズ","vi":"nhạc jazz","lesson":6},
    {"jp":"ツアー","reading":"ツアー","vi":"tour du lịch","lesson":6},
    {"jp":"どちら","reading":"どちら","vi":"bên nào, phương nào","lesson":6},
    {"jp":"どちらも","reading":"どちらも","vi":"bên nào cũng","lesson":6},
    {"jp":"ちかい","reading":"ちかい","vi":"gần","lesson":6},
    {"jp":"とおい","reading":"とおい","vi":"xa","lesson":6},
    {"jp":"はやい","reading":"はやい","vi":"nhanh, sớm","lesson":6},
    {"jp":"ひろい","reading":"ひろい","vi":"rộng","lesson":6},
    {"jp":"いちばん","reading":"いちばん","vi":"nhất, số 1","lesson":6},
    {"jp":"ぜんぶ","reading":"ぜんぶ","vi":"toàn bộ, tất cả","lesson":6},
    {"jp":"そうですねえ","reading":"そうですねえ","vi":"à thì..., ừ thì","lesson":6},
    {"jp":"おこのみやき","reading":"おこのみやき","vi":"món bánh xèo Nhật","lesson":6},
    {"jp":"すきやき","reading":"すきやき","vi":"món nhúng thịt bò và rau","lesson":6},
    {"jp":"あそびます","reading":"あそびます","vi":"chơi, chơi đùa","lesson":6},
    {"jp":"ぜひ","reading":"ぜひ","vi":"nhất định","lesson":6},
    {"jp":"まだ","reading":"まだ","vi":"vẫn, chưa","lesson":6},
    {"jp":"もう","reading":"もう","vi":"đã, rồi","lesson":6},
    {"jp":"そうしましょう","reading":"そうしましょう","vi":"làm như thế đi","lesson":6},
    {"jp":"わかりました","reading":"わかりました","vi":"tôi hiểu rồi","lesson":6}
  ];

  try {
    print("======> BẮT ĐẦU UPLOAD NHẬT 2 BÀI 6...");
    final FirebaseFirestore firestore = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'default',
    );
    final WriteBatch batch = firestore.batch();
    final CollectionReference collection = firestore.collection('vocabulary');

    for (final vocab in vocabList) {
      final String docId = "nhat_2_L6_${vocab['jp']}";
      final docRef = collection.doc(docId);
      batch.set(docRef, {
        'book': 'Nhật 2',
        'lesson': vocab['lesson'],
        'jp': vocab['jp'],
        'reading': vocab['reading'],
        'vi': vocab['vi'],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    print("======> ĐÃ UPLOAD THÀNH CÔNG NHẬT 2 BÀI 6 LÊN FIREBASE!");
  } catch (e) {
    print("======> LỖI KHI UPLOAD NHẬT 2 BÀI 6: $e");
  }
}

/// Hàm upload danh sách từ vựng "Nhật 2 Bài 7" lên Firestore.
Future<void> uploadNhat2Lesson7Data() async {
  final List<Map<String, dynamic>> vocabList = [
    {"jp":"お寺","reading":"おてら","vi":"chùa","lesson":7},
    {"jp":"言います","reading":"いいます","vi":"nói","lesson":7},
    {"jp":"貝","reading":"かい","vi":"sò, hến, trai","lesson":7},
    {"jp":"田","reading":"た","vi":"ruộng lúa","lesson":7},
    {"jp":"力","reading":"ちから","vi":"sức mạnh, khả năng","lesson":7},
    {"jp":"門","reading":"もん","vi":"cổng","lesson":7},
    {"jp":"肉","reading":"にく","vi":"thịt","lesson":7},
    {"jp":"料理","reading":"りょうり","vi":"thức ăn, món ăn","lesson":7},
    {"jp":"野菜","reading":"やさい","vi":"rau xanh","lesson":7},
    {"jp":"半","reading":"はん","vi":"một nửa","lesson":7},
    {"jp":"大きい","reading":"おおきい","vi":"to, lớn","lesson":7},
    {"jp":"小さい","reading":"ちいさい","vi":"nhỏ","lesson":7},
    {"jp":"時間半","reading":"じかんはん","vi":"một tiếng rưỡi","lesson":7},
    {"jp":"かいさつ","reading":"かいさつ","vi":"soát vé","lesson":7},
    {"jp":"き","reading":"き","vi":"cây, gỗ","lesson":7},
    {"jp":"こうばん","reading":"こうばん","vi":"đồn cảnh sát","lesson":7},
    {"jp":"じどうはんばいき","reading":"じどうはんばいき","vi":"máy bán hàng tự động","lesson":7},
    {"jp":"バスてい","reading":"バスてい","vi":"trạm xe buýt","lesson":7},
    {"jp":"ポスト","reading":"ポスト","vi":"thùng thư, hòm thư","lesson":7},
    {"jp":"はな","reading":"はな","vi":"hoa","lesson":7},
    {"jp":"いぬ","reading":"いぬ","vi":"con chó","lesson":7},
    {"jp":"あいだ","reading":"あいだ","vi":"giữa, ở giữa","lesson":7},
    {"jp":"うえ","reading":"うえ","vi":"trên, bên trên","lesson":7},
    {"jp":"した","reading":"した","vi":"dưới, phía dưới","lesson":7},
    {"jp":"ちかく","reading":"ちかく","vi":"gần","lesson":7},
    {"jp":"となり","reading":"となり","vi":"bên cạnh","lesson":7},
    {"jp":"なか","reading":"なか","vi":"trong, bên trong","lesson":7},
    {"jp":"そと","reading":"そと","vi":"ngoài, bên ngoài","lesson":7},
    {"jp":"まえ","reading":"まえ","vi":"trước, phía trước","lesson":7},
    {"jp":"うしろ","reading":"うしろ","vi":"sau, phía sau","lesson":7},
    {"jp":"よこ","reading":"よこ","vi":"bên cạnh, chiều ngang","lesson":7},
    {"jp":"むかえにいきます","reading":"むかえにいきます","vi":"đi đón","lesson":7},
    {"jp":"います","reading":"いる","vi":"có (người, động vật)","lesson":7},
    {"jp":"もしもし","reading":"もしもし","vi":"alo","lesson":7},
    {"jp":"私は本やのなかにいます","reading":"わたしはほんやのなかにいます","vi":"tôi ở hiệu sách","lesson":7},
    {"jp":"いす","reading":"いす","vi":"ghế","lesson":7},
    {"jp":"テーブル","reading":"テーブル","vi":"cái bàn","lesson":7},
    {"jp":"でんしレンジ","reading":"でんしレンジ","vi":"lò vi sóng","lesson":7},
    {"jp":"れいぞうこ","reading":"れいぞうこ","vi":"tủ lạnh","lesson":7},
    {"jp":"さとう","reading":"さとう","vi":"đường","lesson":7},
    {"jp":"しお","reading":"しお","vi":"muối","lesson":7},
    {"jp":"しょうゆ","reading":"しょうゆ","vi":"xì dầu","lesson":7},
    {"jp":"コップ","reading":"コップ","vi":"cốc","lesson":7},
    {"jp":"（お）さら","reading":"さら","vi":"cái đĩa","lesson":7},
    {"jp":"スプーン","reading":"スプーン","vi":"cái thìa","lesson":7},
    {"jp":"ナイフ","reading":"ナイフ","vi":"con dao","lesson":7},
    {"jp":"フォーク","reading":"フォーク","vi":"cái dĩa","lesson":7},
    {"jp":"はし","reading":"はし","vi":"đũa","lesson":7},
    {"jp":"かんじ","reading":"かんじ","vi":"chữ Hán","lesson":7},
    {"jp":"どれ","reading":"どれ","vi":"cái nào","lesson":7},
    {"jp":"どの～","reading":"どの","vi":"~ nào","lesson":7},
    {"jp":"あらいます","reading":"あらいます","vi":"giặt, rửa, tắm","lesson":7},
    {"jp":"おきます","reading":"おきます","vi":"đặt, để","lesson":7},
    {"jp":"かきます","reading":"かきます","vi":"viết","lesson":7},
    {"jp":"かします","reading":"かします","vi":"cho mượn","lesson":7},
    {"jp":"ききます","reading":"ききます","vi":"nghe, hỏi","lesson":7},
    {"jp":"きります","reading":"きります","vi":"cắt, gọt","lesson":7},
    {"jp":"つかいます","reading":"つかいます","vi":"dùng, sử dụng","lesson":7},
    {"jp":"てつだいます","reading":"てつだいます","vi":"giúp đỡ","lesson":7},
    {"jp":"とります","reading":"とります","vi":"cầm, lấy","lesson":7},
    {"jp":"もっていきます","reading":"もっていきます","vi":"mang đi","lesson":7},
    {"jp":"わかります","reading":"わかります","vi":"hiểu, biết","lesson":7},
    {"jp":"だします","reading":"だします","vi":"nộp, lấy ra","lesson":7},
    {"jp":"いれます","reading":"いれます","vi":"cho vào","lesson":7},
    {"jp":"おしえます","reading":"おしえます","vi":"dạy, chỉ bảo","lesson":7},
    {"jp":"たくさん","reading":"たくさん","vi":"nhiều","lesson":7},
    {"jp":"すみませんが","reading":"すみませんが","vi":"xin lỗi, cho tôi hỏi","lesson":7},
    {"jp":"ああ","reading":"ああ","vi":"a, à","lesson":7},
    {"jp":"いいですよ","reading":"いいですよ","vi":"được đấy","lesson":7},
    {"jp":"うた","reading":"うた","vi":"bài hát","lesson":7},
    {"jp":"ギター","reading":"ギター","vi":"đàn guitar","lesson":7},
    {"jp":"だいどころ","reading":"だいどころ","vi":"nhà bếp","lesson":7},
    {"jp":"たばこ","reading":"たばこ","vi":"thuốc lá","lesson":7},
    {"jp":"でんわ","reading":"でんわ","vi":"điện thoại","lesson":7},
    {"jp":"ピザ","reading":"ピザ","vi":"bánh pizza","lesson":7},
    {"jp":"まど","reading":"まど","vi":"cửa sổ","lesson":7},
    {"jp":"うたいます","reading":"うたいます","vi":"hát","lesson":7},
    {"jp":"すいます","reading":"すいます","vi":"hút","lesson":7},
    {"jp":"はなします","reading":"はなします","vi":"nói chuyện","lesson":7},
    {"jp":"ひきます","reading":"ひきます","vi":"chơi nhạc cụ","lesson":7},
    {"jp":"もちます","reading":"もちます","vi":"cầm, mang","lesson":7},
    {"jp":"あけます","reading":"あけます","vi":"mở","lesson":7},
    {"jp":"しめます","reading":"しめます","vi":"đóng","lesson":7},
    {"jp":"かけます","reading":"かけます","vi":"gọi điện thoại","lesson":7},
    {"jp":"もってきます","reading":"もってきます","vi":"mang đến","lesson":7}
  ];

  try {
    print("======> BẮT ĐẦU UPLOAD NHẬT 2 BÀI 7...");
    final FirebaseFirestore firestore = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'default',
    );
    final WriteBatch batch = firestore.batch();
    final CollectionReference collection = firestore.collection('vocabulary');

    for (final vocab in vocabList) {
      final String docId = "nhat_2_L7_${vocab['jp']}";
      final docRef = collection.doc(docId);
      batch.set(docRef, {
        'book': 'Nhật 2',
        'lesson': vocab['lesson'],
        'jp': vocab['jp'],
        'reading': vocab['reading'],
        'vi': vocab['vi'],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    print("======> ĐÃ UPLOAD THÀNH CÔNG NHẬT 2 BÀI 7 LÊN FIREBASE!");
  } catch (e) {
    print("======> LỖI KHI UPLOAD NHẬT 2 BÀI 7: $e");
  }
}

/// Hàm chẩn đoán: Quét Firestore và in ra số lượng từ vựng của mỗi Bài học, đồng thời tìm kiếm từ trùng lặp.
Future<void> checkDatabaseCounts() async {
  try {
    final firestore = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'default',
    );
    
    print("======> BẮT ĐẦU KIỂM TRA SỐ LƯỢNG TỪ TRÊN FIREBASE...");
    final snapshot = await firestore.collection('vocabulary').get();
    final docs = snapshot.docs;
    
    final Map<String, Map<int, List<String>>> counts = {};
    for (final doc in docs) {
      final data = doc.data();
      final book = data['book'] as String? ?? 'Không xác định';
      final lesson = data['lesson'] as int? ?? 0;
      final jp = data['jp'] as String? ?? '';
      
      counts.putIfAbsent(book, () => {});
      counts[book]!.putIfAbsent(lesson, () => []);
      counts[book]![lesson]!.add(jp);
    }
    
    for (final book in counts.keys) {
      print("Giáo trình: $book");
      final lessons = counts[book]!.keys.toList()..sort();
      for (final lesson in lessons) {
        final words = counts[book]![lesson]!;
        // Kiểm tra xem có từ nào trùng lặp về mặt chữ (jp) hay không
        final duplicates = <String>{};
        final uniqueWords = <String>{};
        for (final word in words) {
          if (!uniqueWords.add(word)) {
            duplicates.add(word);
          }
        }
        print("  - Bài $lesson: Có ${words.length} từ (Số từ không trùng lặp: ${uniqueWords.length})");
        if (duplicates.isNotEmpty) {
          print("    * Các từ bị trùng lặp: $duplicates");
        }
      }
    }
    print("======> HOÀN THÀNH KIỂM TRA!");
  } catch (e) {
    print("Lỗi khi kiểm tra dữ liệu: $e");
  }
}
