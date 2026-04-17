import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_preference_model.dart';

/// Notification Preference Service
///
/// Manages notification preferences with Firestore backend.
/// Handles CRUD operations for user notification settings.
class NotificationPreferenceService {
  // Singleton
  static final NotificationPreferenceService _instance =
      NotificationPreferenceService._internal();
  factory NotificationPreferenceService() => _instance;
  NotificationPreferenceService._internal();

  // Firestore
  final _firestore = FirebaseFirestore.instance;

  // Collection reference helper
  String _getPreferencesCollection(String userId) =>
      'users/$userId/notificationPreferences';

  /// Get all notification preferences for user
  Future<List<NotificationPreference>> getPreferences(String userId) async {
    try {
      debugPrint('Fetching notification preferences for user: $userId');

      final snapshot = await _firestore
          .collection(_getPreferencesCollection(userId))
          .get();

      final preferences = snapshot.docs
          .map((doc) => NotificationPreference.fromJson(doc.data()))
          .toList();

      debugPrint('Found ${preferences.length} notification preferences');
      return preferences;
    } catch (e) {
      debugPrint('Error fetching notification preferences: $e');
      rethrow;
    }
  }

  /// Get preference for specific type
  Future<NotificationPreference?> getPreferenceByType(
    String userId,
    NotificationType type,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_getPreferencesCollection(userId))
          .where('type', isEqualTo: type.name)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return NotificationPreference.fromJson(snapshot.docs.first.data());
    } catch (e) {
      debugPrint('Error fetching preference by type: $e');
      rethrow;
    }
  }

  /// Save or update notification preference
  Future<void> savePreference(
    String userId,
    NotificationPreference preference,
  ) async {
    try {
      debugPrint('Saving notification preference: ${preference.type}');

      final data = preference.toJson();
      await _firestore
          .collection(_getPreferencesCollection(userId))
          .doc(preference.id)
          .set(data);

      debugPrint('Notification preference saved: ${preference.type}');
    } catch (e) {
      debugPrint('Error saving notification preference: $e');
      rethrow;
    }
  }

  /// Update preference field
  Future<void> updatePreference(
    String userId,
    String preferenceId,
    Map<String, dynamic> updates,
  ) async {
    try {
      debugPrint('Updating notification preference: $preferenceId');

      updates['updatedAt'] = DateTime.now().toIso8601String();

      await _firestore
          .collection(_getPreferencesCollection(userId))
          .doc(preferenceId)
          .update(updates);

      debugPrint('Notification preference updated: $preferenceId');
    } catch (e) {
      debugPrint('Error updating notification preference: $e');
      rethrow;
    }
  }

  /// Toggle notification enabled status
  Future<void> toggleNotificationEnabled(
    String userId,
    String preferenceId,
    bool enabled,
  ) async {
    try {
      await updatePreference(userId, preferenceId, {
        'enabled': enabled,
      });
    } catch (e) {
      debugPrint('Error toggling notification: $e');
      rethrow;
    }
  }

  /// Toggle sound enabled
  Future<void> toggleSoundEnabled(
    String userId,
    String preferenceId,
    bool soundEnabled,
  ) async {
    try {
      await updatePreference(userId, preferenceId, {
        'soundEnabled': soundEnabled,
      });
    } catch (e) {
      debugPrint('Error toggling sound: $e');
      rethrow;
    }
  }

  /// Toggle vibration enabled
  Future<void> toggleVibrationEnabled(
    String userId,
    String preferenceId,
    bool vibrationEnabled,
  ) async {
    try {
      await updatePreference(userId, preferenceId, {
        'vibrationEnabled': vibrationEnabled,
      });
    } catch (e) {
      debugPrint('Error toggling vibration: $e');
      rethrow;
    }
  }

  /// Set quiet hours
  Future<void> setQuietHours(
    String userId,
    String preferenceId,
    String startTime,
    String endTime,
  ) async {
    try {
      await updatePreference(userId, preferenceId, {
        'quietHoursStart': startTime,
        'quietHoursEnd': endTime,
      });
    } catch (e) {
      debugPrint('Error setting quiet hours: $e');
      rethrow;
    }
  }

  /// Clear quiet hours
  Future<void> clearQuietHours(String userId, String preferenceId) async {
    try {
      await updatePreference(userId, preferenceId, {
        'quietHoursStart': null,
        'quietHoursEnd': null,
      });
    } catch (e) {
      debugPrint('Error clearing quiet hours: $e');
      rethrow;
    }
  }

  /// Initialize default preferences for new user
  Future<void> initializeDefaultPreferences(String userId) async {
    try {
      debugPrint('Initializing default notification preferences for: $userId');

      final batch = _firestore.batch();
      final now = DateTime.now();

      // Create default preferences for each notification type
      for (final type in NotificationType.values) {
        final docRef = _firestore
            .collection(_getPreferencesCollection(userId))
            .doc('pref_${type.name}_$userId');

        final preference = NotificationPreference(
          id: docRef.id,
          userId: userId,
          type: type,
          enabled: true,
          soundEnabled: true,
          vibrationEnabled: true,
          createdAt: now,
          updatedAt: now,
        );

        batch.set(docRef, preference.toJson());
      }

      await batch.commit();
      debugPrint('Default notification preferences initialized');
    } catch (e) {
      debugPrint('Error initializing default preferences: $e');
      rethrow;
    }
  }

  /// Stream notification preferences for real-time updates
  Stream<List<NotificationPreference>> streamPreferences(String userId) {
    try {
      return _firestore
          .collection(_getPreferencesCollection(userId))
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => NotificationPreference.fromJson(doc.data()))
              .toList());
    } catch (e) {
      debugPrint('Error streaming preferences: $e');
      rethrow;
    }
  }

  /// Check if notification should be sent based on preferences
  Future<bool> shouldSendNotification(
    String userId,
    NotificationType type,
  ) async {
    try {
      final preference = await getPreferenceByType(userId, type);
      if (preference == null) {
        return true; // Default to true if no preference exists
      }
      return preference.shouldSendNotification();
    } catch (e) {
      debugPrint('Error checking if notification should be sent: $e');
      return true; // Default to true on error
    }
  }

  /// Delete preference
  Future<void> deletePreference(String userId, String preferenceId) async {
    try {
      debugPrint('Deleting notification preference: $preferenceId');

      await _firestore
          .collection(_getPreferencesCollection(userId))
          .doc(preferenceId)
          .delete();

      debugPrint('Notification preference deleted: $preferenceId');
    } catch (e) {
      debugPrint('Error deleting notification preference: $e');
      rethrow;
    }
  }
}
