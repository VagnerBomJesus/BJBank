import 'package:cloud_firestore/cloud_firestore.dart';

/// Firebase Configuration for BJBank
/// Centralizes Firestore database instance configuration
class FirebaseConfig {
  FirebaseConfig._();

  /// The named Firestore database ID for this project.
  /// The project uses a named database 'dbbjbank' instead of '(default)'.
  static const String databaseId = 'dbbjbank';

  /// Get the configured Firestore instance pointing to the named database
  static FirebaseFirestore get firestore {
    return FirebaseFirestore.instanceFor(
      app: FirebaseFirestore.instance.app,
      databaseId: databaseId,
    );
  }
}
