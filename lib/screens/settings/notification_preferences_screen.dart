import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/notification_preference_model.dart';
import '../../providers/notification_provider.dart';
import '../../theme/spacing.dart';

/// Notification Preferences Screen
///
/// Allows users to customize notification settings for different types:
/// - Enable/disable notifications per type
/// - Sound settings
/// - Vibration settings
/// - Quiet hours configuration
class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({Key? key}) : super(key: key);

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  // Track changes before saving
  late Map<NotificationType, NotificationPreference> _pendingChanges;

  @override
  void initState() {
    super.initState();
    _initializePendingChanges();
  }

  void _initializePendingChanges() {
    final preferences =
        context.read<NotificationProvider>().preferences;
    _pendingChanges = {
      for (final pref in preferences) pref.type: pref,
    };
  }

  void _updatePendingChange(NotificationPreference preference) {
    setState(() {
      _pendingChanges[preference.type] = preference;
    });
  }

  Future<void> _saveAllChanges() async {
    final provider = context.read<NotificationProvider>();
    bool allSuccess = true;

    for (final preference in _pendingChanges.values) {
      final originalPref = provider.getPreferenceByType(preference.type);
      if (originalPref == null) continue;

      // Only save if something changed
      if (originalPref != preference) {
        // Apply all the changes through provider methods
        if (originalPref.enabled != preference.enabled) {
          final success = await provider.toggleNotificationEnabled(
            preference.type,
            preference.enabled,
          );
          allSuccess = allSuccess && success;
        }

        if (originalPref.soundEnabled != preference.soundEnabled) {
          final success = await provider.toggleSoundEnabled(
            preference.type,
            preference.soundEnabled,
          );
          allSuccess = allSuccess && success;
        }

        if (originalPref.vibrationEnabled != preference.vibrationEnabled) {
          final success = await provider.toggleVibrationEnabled(
            preference.type,
            preference.vibrationEnabled,
          );
          allSuccess = allSuccess && success;
        }

        if (originalPref.quietHoursStart != preference.quietHoursStart ||
            originalPref.quietHoursEnd != preference.quietHoursEnd) {
          if (preference.quietHoursStart != null &&
              preference.quietHoursEnd != null) {
            final success = await provider.setQuietHours(
              preference.type,
              preference.quietHoursStart!,
              preference.quietHoursEnd!,
            );
            allSuccess = allSuccess && success;
          } else {
            final success = await provider.clearQuietHours(preference.type);
            allSuccess = allSuccess && success;
          }
        }
      }
    }

    if (mounted) {
      if (allSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferências salvas com sucesso'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        // Reinitialize to reflect saved state
        _initializePendingChanges();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao salvar preferências'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferências de Notificações'),
        elevation: 0,
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.preferences.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.preferences.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: BJBankSpacing.md),
                  Text(
                    'Nenhuma preferência disponível',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(BJBankSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Instructions
                Container(
                  padding: const EdgeInsets.all(BJBankSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      SizedBox(width: BJBankSpacing.sm),
                      Expanded(
                        child: Text(
                          'Configure como deseja receber notificações para cada tipo',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: BJBankSpacing.md),

                // Notification preferences list
                ..._pendingChanges.entries.map((entry) {
                  final pref = entry.value;

                  return _NotificationPreferenceCard(
                    preference: pref,
                    isDark: isDark,
                    onChanged: _updatePendingChange,
                  );
                }),

                SizedBox(height: BJBankSpacing.lg),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: provider.isLoading ? null : _saveAllChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(
                        vertical: BJBankSpacing.md,
                      ),
                    ),
                    child: provider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Guardar Preferências',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Individual notification preference card
class _NotificationPreferenceCard extends StatefulWidget {
  final NotificationPreference preference;
  final bool isDark;
  final Function(NotificationPreference) onChanged;

  const _NotificationPreferenceCard({
    required this.preference,
    required this.isDark,
    required this.onChanged,
    Key? key,
  }) : super(key: key);

  @override
  State<_NotificationPreferenceCard> createState() =>
      _NotificationPreferenceCardState();
}

class _NotificationPreferenceCardState extends State<_NotificationPreferenceCard> {
  late NotificationPreference _currentPref;
  late bool _showQuietHours;

  @override
  void initState() {
    super.initState();
    _currentPref = widget.preference;
    _showQuietHours =
        _currentPref.quietHoursStart != null && _currentPref.quietHoursEnd != null;
  }

  void _updatePreference(NotificationPreference newPref) {
    setState(() {
      _currentPref = newPref;
    });
    widget.onChanged(newPref);
  }

  Future<void> _pickStartTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: _parseTime(_currentPref.quietHoursStart ?? '22:00'),
    );

    if (result != null) {
      final timeString = '${result.hour.toString().padLeft(2, '0')}:${result.minute.toString().padLeft(2, '0')}';
      _updatePreference(
        _currentPref.copyWith(quietHoursStart: timeString),
      );
    }
  }

  Future<void> _pickEndTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: _parseTime(_currentPref.quietHoursEnd ?? '07:00'),
    );

    if (result != null) {
      final timeString = '${result.hour.toString().padLeft(2, '0')}:${result.minute.toString().padLeft(2, '0')}';
      _updatePreference(
        _currentPref.copyWith(quietHoursEnd: timeString),
      );
    }
  }

  TimeOfDay _parseTime(String timeString) {
    final parts = timeString.split(':');
    if (parts.length != 2) return TimeOfDay.now();
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: BJBankSpacing.md),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: Text(
          _currentPref.getTypeIcon(),
          style: const TextStyle(fontSize: 24),
        ),
        title: Text(
          _currentPref.getTypeLabel(),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: _currentPref.enabled
            ? const Text('Ativado')
            : const Text(
                'Desativado',
                style: TextStyle(color: Colors.grey),
              ),
        children: [
          Padding(
            padding: const EdgeInsets.all(BJBankSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enable/Disable toggle
                SwitchListTile(
                  title: const Text('Ativar notificações'),
                  value: _currentPref.enabled,
                  onChanged: (value) {
                    _updatePreference(_currentPref.copyWith(enabled: value));
                  },
                  contentPadding: EdgeInsets.zero,
                ),

                if (_currentPref.enabled) ...[
                  Divider(height: BJBankSpacing.md),

                  // Sound toggle
                  SwitchListTile(
                    title: const Text('Som de notificação'),
                    value: _currentPref.soundEnabled,
                    onChanged: (value) {
                      _updatePreference(
                        _currentPref.copyWith(soundEnabled: value),
                      );
                    },
                    contentPadding: EdgeInsets.zero,
                  ),

                  SizedBox(height: BJBankSpacing.sm),

                  // Vibration toggle
                  SwitchListTile(
                    title: const Text('Vibração'),
                    value: _currentPref.vibrationEnabled,
                    onChanged: (value) {
                      _updatePreference(
                        _currentPref.copyWith(vibrationEnabled: value),
                      );
                    },
                    contentPadding: EdgeInsets.zero,
                  ),

                  Divider(height: BJBankSpacing.md),

                  // Quiet hours section
                  SwitchListTile(
                    title: const Text('Horário silencioso'),
                    subtitle: const Text('Não enviar notificações num horário específico'),
                    value: _showQuietHours,
                    onChanged: (value) {
                      setState(() {
                        _showQuietHours = value;
                      });

                      if (value) {
                        _updatePreference(
                          _currentPref.copyWith(
                            quietHoursStart: '22:00',
                            quietHoursEnd: '07:00',
                          ),
                        );
                      } else {
                        _updatePreference(
                          _currentPref.copyWith(
                            quietHoursStart: null,
                            quietHoursEnd: null,
                          ),
                        );
                      }
                    },
                    contentPadding: EdgeInsets.zero,
                  ),

                  if (_showQuietHours) ...[
                    SizedBox(height: BJBankSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _TimePickerButton(
                            label: 'Início',
                            time: _currentPref.quietHoursStart ?? '22:00',
                            onTap: _pickStartTime,
                          ),
                        ),
                        SizedBox(width: BJBankSpacing.md),
                        Expanded(
                          child: _TimePickerButton(
                            label: 'Fim',
                            time: _currentPref.quietHoursEnd ?? '07:00',
                            onTap: _pickEndTime,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Time picker button widget
class _TimePickerButton extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;

  const _TimePickerButton({
    required this.label,
    required this.time,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: BJBankSpacing.md,
          vertical: BJBankSpacing.sm,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: BJBankSpacing.xs),
            Text(
              time,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
