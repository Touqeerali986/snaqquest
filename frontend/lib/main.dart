import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var firebaseReady = true;
  try {
    await Firebase.initializeApp();
  } catch (_) {
    firebaseReady = false;
  }

  runApp(SnaqQuestApp(firebaseReady: firebaseReady));
}
