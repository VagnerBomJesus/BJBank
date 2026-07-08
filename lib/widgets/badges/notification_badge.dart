import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';

/// Notification Badge Widget
///
/// Exibe um badge com contador para notificações.
/// Cores e ícones adaptam-se ao tipo de notificação.
///
/// Tipos suportados:
/// - [NotificationType.alert]: Vermelho (erro/urgente)
/// - [NotificationType.warning]: Laranja (aviso)
/// - [NotificationType.info]: Azul (informação)
/// - [NotificationType.success]: Verde (sucesso)
///
/// Exemplo:
/// ```dart
/// NotificationBadge(
///   count: 5,
///   type: NotificationType.alert,
/// )
/// ```
enum NotificationType {
  alert,    // Vermelho - urgente/erro
  warning,  // Laranja - aviso
  info,     // Azul - informação
  success,  // Verde - sucesso
}

class NotificationBadge extends StatefulWidget {
  const NotificationBadge({
    super.key,
    required this.count,
    this.type = NotificationType.alert,
    this.size = 20,
    this.showPulse = false,
    this.onTap,
  });

  /// Número de notificações
  final int count;

  /// Tipo de notificação (define cor)
  final NotificationType type;

  /// Tamanho do badge
  final double size;

  /// Ativar animação de pulse
  final bool showPulse;

  /// Callback ao clicar no badge
  final VoidCallback? onTap;

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Setup pulse animation
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.showPulse) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(NotificationBadge oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reinicia pulse se mudou
    if (oldWidget.showPulse != widget.showPulse) {
      if (widget.showPulse) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Retorna cor baseado no tipo
  Color _getColor() {
    switch (widget.type) {
      case NotificationType.alert:
        return BJBankColors.error;
      case NotificationType.warning:
        return BJBankColors.warning;
      case NotificationType.info:
        return BJBankColors.info;
      case NotificationType.success:
        return BJBankColors.success;
    }
  }

  /// Retorna cor background (light)
  Color _getBackgroundColor() {
    switch (widget.type) {
      case NotificationType.alert:
        return BJBankColors.errorLight;
      case NotificationType.warning:
        return BJBankColors.warningLight;
      case NotificationType.info:
        return BJBankColors.infoLight;
      case NotificationType.success:
        return BJBankColors.successLight;
    }
  }

  /// Retorna ícone baseado no tipo
  IconData _getIcon() {
    switch (widget.type) {
      case NotificationType.alert:
        return Icons.error_outline;
      case NotificationType.warning:
        return Icons.warning_outlined;
      case NotificationType.info:
        return Icons.info_outlined;
      case NotificationType.success:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Se count é 0, retorna empty
    if (widget.count == 0) {
      return const SizedBox.shrink();
    }

    // Display: máximo "9+"
    final displayCount = widget.count > 9 ? '9+' : '${widget.count}';

    return GestureDetector(
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _pulseAnimation,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            border: Border.all(
              color: _getColor(),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(widget.size / 2),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ícone
              Icon(
                _getIcon(),
                size: widget.size * 0.6,
                color: _getColor(),
              ),

              // Contador (badge)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BJBankSpacing.xxs,
                    vertical: BJBankSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: _getColor(),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    displayCount,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple Badge para mostrar apenas contador sem ícone
///
/// Exemplo:
/// ```dart
/// SimpleNotificationBadge(count: 3)
/// ```
class SimpleNotificationBadge extends StatelessWidget {
  const SimpleNotificationBadge({
    super.key,
    required this.count,
    this.backgroundColor = BJBankColors.error,
    this.textColor = Colors.white,
    this.size = 20,
  });

  /// Número a exibir
  final int count;

  /// Cor de background
  final Color backgroundColor;

  /// Cor do texto
  final Color textColor;

  /// Tamanho do badge
  final double size;

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return const SizedBox.shrink();
    }

    final displayCount = count > 99 ? '99+' : '$count';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Center(
        child: Text(
          displayCount,
          style: TextStyle(
            color: textColor,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
