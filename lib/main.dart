import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:oqs/oqs.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'services/pqc_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations (portrait only)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    // Continue without Firebase for development
  }

  // Initialize liboqs (Open Quantum Safe native library)
  try {
    LibOQSLoader.loadLibrary();
    PqcService.isLiboqsAvailable = true;
    debugPrint('liboqs initialized — modo produção PQC activo');
  } catch (e) {
    debugPrint('liboqs não disponível, modo simulação: $e');
    PqcService.isLiboqsAvailable = false;
  }

  // Initialize PQC Service
  try {
    final pqcService = PqcService();
    await pqcService.initialize();
    debugPrint('PQC Service initialized successfully');
  } catch (e) {
    debugPrint('PQC Service initialization failed: $e');
  }

  // Setup background message handler for Firebase Cloud Messaging
  setupBackgroundMessageHandler();

  // Initialize Firebase Cloud Messaging (Push Notifications)
  try {
    await NotificationService.initialize();
    debugPrint('Firebase Cloud Messaging initialized successfully');
  } catch (e) {
    debugPrint('Firebase Cloud Messaging initialization failed: $e');
  }

  runApp(const BJBankApp());
}
