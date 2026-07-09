import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'app.dart';
import 'core/utils/firebase_uploader.dart'; // Import uploader helper

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  //await uploadNhat2Lesson7Data();
  //await checkDatabaseCounts();

  runApp(const SakuraApp());
}
