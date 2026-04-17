import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notification_preference_model.dart';
import '../services/notification_preference_service.dart';

/// Notification Provider for managing notification preferences
///
/// Manages:
/// - Real-time notification preference updates
/// - Preference creation and updates
/// - Quiet hours management
/// - Sound and vibration settings
class NotificationProvider extends ChangeNotifier {
  final NotificationPreferenceService _preferenceService =
      NotificationPreferenceService();

  List<NotificationPreference> _preferences = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _preferencesSubscription;
  String? _currentUserId;

  // Getters
  List<NotificationPreference> get preferences => _preferences;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasPreferences => _preferences.isNotEmpty;

  // Filtered getters
  List<NotificationPreference> get enabledPreferences =>
      _preferences.where((p) => p.enabled).toList();

  NotificationPreference? getPreferenceByType(NotificationType type) {
    try {
      return _preferences.firstWhere((p) => p.type == type);
    } catch (e) {
      return null;
    }
  }

  /// Initialize provider and listen to preferences for user
  void initialize(String userId) {
    _currentUserId = userId;
    _listenToPreferences(userId);
    _ensureDefaultPreferences(userId);
  }

  /// Listen to real-time preference updates
  void _listenToPreferences(String userId) {
    _preferencesSubscription?.cancel();
    _preferencesSubscription =
        _preferenceService.streamPreferences(userId).listen(
      (preferences) {
        _preferences = preferences;
        if (_preferences.isNotEmpty && _errorMessage != null) {
          _errorMessage = null;
        }
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error streaming preferences: $error');
        _errorMessage = 'Erro ao carregar preferências';
        notifyListeners();
      },
    );
  }

  /// Ensure default preferences exist for new user
  Future<void> _ensureDefaultPreferences(String userId) async {
    try {
      final preferences = await _preferenceService.getPreferences(userId);
      if (preferences.isEmpty) {
        await _preferenceService.initializeDefaultPreferences(userId);
      }
    } catch (e) {
      debugPrint('Error ensuring default preferences: $e');
    }
  }

  /// Load preferences for user
  Future<void> loadPreferences(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _preferences =
          await _preferenceService.getPreferences(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao carregar preferências: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Toggle notification enabled
  Future<bool> toggleNotificationEnabled(
    NotificationType type,
    bool enabled,
  ) async {
    if (_currentUserId == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final preference = getPreferenceByType(type);
      if (preference == null) {
        _isLoading = false;
        _errorMessage = 'Preferência não encontrada';
        notifyListeners();
        return false;
      }

      await _preferenceService.toggleNotificationEnabled(
        _currentUserId!,
        preference.id,
        enabled,
      );

      // Update local state
      final index = _preferences
          .indexWhere((p) => p.type == type);
      if (index != -1) {
        _preferences[index] = _preferences[index].copyWith(enabled: enabled);
        notifyListeners();
      }

      _isLoading = false;
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Toggle sound enabled
  Future<bool> toggleSoundEnabled(
    NotificationType type,
    bool soundEnabled,
  ) async {
    if (_currentUserId == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final preference = getPreferenceByType(type);
      if (preference == null) {
        _isLoading = false;
        return false;
      }

      await _preferenceService.toggleSoundEnabled(
        _currentUserId!,
        preference.id,
        soundEnabled,
      );

      final index = _preferences.indexWhere((p) => p.type == type);
      if (index != -1) {
        _preferences[index] =
            _preferences[index].copyWith(soundEnabled: soundEnabled);
        notifyListeners();
      }

      _isLoading = false;
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Toggle vibration enabled
  Future<bool> toggleVibrationEnabled(
    NotificationType type,
    bool vibrationEnabled,
  ) async {
    if (_currentUserId == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final preference = getPreferenceByType(type);
      if (preference == null) {
        _isLoading = false;
        return false;
      }

      await _preferenceService.toggleVibrationEnabled(
        _currentUserId!,
        preference.id,
        vibrationEnabled,
      );

      final index = _preferences.indexWhere((p) => p.type == type);
      if (index != -1) {
        _preferences[index] = _preferences[index]
            .copyWith(vibrationEnabled: vibrationEnabled);
        notifyListeners();
      }

      _isLoading = false;
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Set quiet hours
  Future<bool> setQuietHours(
    NotificationType type,
    String startTime,
    String endTime,
  ) async {
    if (_currentUserId == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final preference = getPreferenceByType(type);
      if (preference == null) {
        _isLoading = false;
        return false;
      }

      await _preferenceService.setQuietHours(
        _currentUserId!,
        preference.id,
        startTime,
        endTime,
      );

      final index = _preferences.indexWhere((p) => p.type == type);
      if (index != -1) {
        _preferences[index] = _preferences[index].copyWith(
          quietHoursStart: startTime,
          quietHoursEnd: endTime,
        );
        notifyListeners();
      }

      _isLoading = false;
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro ao definir horário silencioso: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Clear quiet hours
  Future<bool> clearQuietHours(NotificationType type) async {
    if (_currentUserId == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final preference = getPreferenceByType(type);
      if (preference == null) {
        _isLoading = false;
        return false;
      }

      await _preferenceService.clearQuietHours(
        _currentUserId!,
        preference.id,
      );

      final index = _preferences.indexWhere((p) => p.type == type);
      if (index != -1) {
        _preferences[index] = _preferences[index].copyWith(
          quietHoursStart: null,
          quietHoursEnd: null,
        );
        notifyListeners();
      }

      _isLoading = false;
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Check if notification should be sent
  Future<bool> shouldSendNotification(NotificationType type) async {
    if (_currentUserId == null) return false;

    try {
      return await _preferenceService.shouldSendNotification(
        _currentUserId!,
        type,
      );
    } catch (e) {
      debugPrint('Error checking if notification should be sent: $e');
      return true; // Default to true on error
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Refresh preferences
  Future<void> refreshPreferences() async {
    if (_currentUserId != null) {
      await loadPreferences(_currentUserId!);
    }
  }

  @override
  void dispose() {
    _preferencesSubscription?.cancel();
    super.dispose();
  }
}
