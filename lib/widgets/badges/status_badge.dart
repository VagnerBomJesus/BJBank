import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';

/// Status Enum - Estados possíveis
enum StatusType {
  pending,    // Pendente - Laranja
  approved,   // Aprovado - Verde
  completed,  // Completado - Azul
  failed,     // Falha - Vermelho
  cancelled,  // Cancelado - Cinzento
  overdue,    // Vencido - Vermelho intenso
}

/// Status Badge Widget
///
/// Exibe o status de uma transação, fatura, empréstimo, etc.
/// Com cor, ícone e label correspondentes.
///
/// Exemplo:
/// ```dart
/// StatusBadge(
///   status: StatusType.completed,
/// )
/// ```
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.compact = false,
    this.showLabel = true,
  });

  /// Status a exibir
  final StatusType status;

  /// Versão compacta (só ícone)
  final bool compact;

  /// Mostrar label
  final bool showLabel;

  /// Retorna cor baseado no status
  Color _getColor() {
    switch (status) {
      case StatusType.pending:
        return BJBankColors.warning;
      case StatusType.approved:
        return BJBankColors.success;
      case StatusType.completed:
        return BJBankColors.info;
      case StatusType.failed:
        return BJBankColors.error;
      case StatusType.cancelled:
        return Colors.grey;
      case StatusType.overdue:
        return BJBankColors.errorDark;
    }
  }

  /// Retorna cor background (light)
  Color _getBackgroundColor() {
    switch (status) {
      case StatusType.pending:
        return BJBankColors.warningLight;
      case StatusType.approved:
        return BJBankColors.successLight;
      case StatusType.completed:
        return BJBankColors.infoLight;
      case StatusType.failed:
        return BJBankColors.errorLight;
      case StatusType.cancelled:
        return Colors.grey.withValues(alpha: 0.1);
      case StatusType.overdue:
        return BJBankColors.errorLight;
    }
  }

  /// Retorna ícone baseado no status
  IconData _getIcon() {
    switch (status) {
      case StatusType.pending:
        return Icons.schedule_outlined;
      case StatusType.approved:
        return Icons.check_circle_outline;
      case StatusType.completed:
        return Icons.verified_outlined;
      case StatusType.failed:
        return Icons.cancel_outlined;
      case StatusType.cancelled:
        return Icons.block_outlined;
      case StatusType.overdue:
        return Icons.warning_amber_outlined;
    }
  }

  /// Retorna label em português
  String _getLabel() {
    switch (status) {
      case StatusType.pending:
        return 'Pendente';
      case StatusType.approved:
        return 'Aprovado';
      case StatusType.completed:
        return 'Completado';
      case StatusType.failed:
        return 'Falha';
      case StatusType.cancelled:
        return 'Cancelado';
      case StatusType.overdue:
        return 'Vencido';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompact();
    }
    return _buildFull();
  }

  /// Build full version com label
  Widget _buildFull() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BJBankSpacing.sm,
        vertical: BJBankSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        border: Border.all(
          color: _getColor().withValues(alpha: 0.5),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(BJBankSpacing.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(),
            size: 14,
            color: _getColor(),
          ),
          if (showLabel) ...[
            const SizedBox(width: BJBankSpacing.xs),
            Text(
              _getLabel(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _getColor(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build compact version (só ícone)
  Widget _buildCompact() {
    return Container(
      padding: const EdgeInsets.all(BJBankSpacing.xxs),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        _getIcon(),
        size: 14,
        color: _getColor(),
      ),
    );
  }
}

/// Status Badge Horizontal
///
/// Versão horizontal com progresso visual
///
/// Exemplo:
/// ```dart
/// HorizontalStatusBadge(
///   status: StatusType.pending,
///   label: 'Transferência',
/// )
/// ```
class HorizontalStatusBadge extends StatelessWidget {
  const HorizontalStatusBadge({
    super.key,
    required this.status,
    required this.label,
  });

  final StatusType status;
  final String label;

  /// Retorna cor baseado no status
  Color _getColor() {
    switch (status) {
      case StatusType.pending:
        return Colors.orange;
      case StatusType.approved:
        return Colors.green;
      case StatusType.completed:
        return Colors.blue;
      case StatusType.failed:
        return Colors.red;
      case StatusType.cancelled:
        return Colors.grey;
      case StatusType.overdue:
        return Colors.red.shade700;
    }
  }

  /// Retorna ícone
  IconData _getIcon() {
    switch (status) {
      case StatusType.pending:
        return Icons.schedule_outlined;
      case StatusType.approved:
        return Icons.check_circle_outline;
      case StatusType.completed:
        return Icons.verified_outlined;
      case StatusType.failed:
        return Icons.cancel_outlined;
      case StatusType.cancelled:
        return Icons.block_outlined;
      case StatusType.overdue:
        return Icons.warning_amber_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          _getIcon(),
          size: 16,
          color: _getColor(),
        ),
        const SizedBox(width: BJBankSpacing.xs),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        Text(
          _getStatusLabel(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _getColor(),
          ),
        ),
      ],
    );
  }

  String _getStatusLabel() {
    switch (status) {
      case StatusType.pending:
        return 'Pendente';
      case StatusType.approved:
        return 'Aprovado';
      case StatusType.completed:
        return 'Completo';
      case StatusType.failed:
        return 'Falha';
      case StatusType.cancelled:
        return 'Cancelado';
      case StatusType.overdue:
        return 'Vencido';
    }
  }
}

/// Status Pill Badge
///
/// Formato tipo "pill" (cápsula)
///
/// Exemplo:
/// ```dart
/// StatusPillBadge(status: StatusType.completed)
/// ```
class StatusPillBadge extends StatelessWidget {
  const StatusPillBadge({
    super.key,
    required this.status,
  });

  final StatusType status;

  /// Retorna cor
  Color _getColor() {
    switch (status) {
      case StatusType.pending:
        return Colors.orange;
      case StatusType.approved:
        return Colors.green;
      case StatusType.completed:
        return Colors.blue;
      case StatusType.failed:
        return Colors.red;
      case StatusType.cancelled:
        return Colors.grey;
      case StatusType.overdue:
        return Colors.red.shade700;
    }
  }

  /// Retorna label
  String _getLabel() {
    switch (status) {
      case StatusType.pending:
        return 'Pendente';
      case StatusType.approved:
        return 'Aprovado';
      case StatusType.completed:
        return 'Completo';
      case StatusType.failed:
        return 'Falha';
      case StatusType.cancelled:
        return 'Cancelado';
      case StatusType.overdue:
        return 'Vencido';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: _getColor().withValues(alpha: 0.2),
        border: Border.all(
          color: _getColor(),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _getLabel(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _getColor(),
        ),
      ),
    );
  }
}

/// Status Line Indicator
///
/// Indicador visual em forma de linha
///
/// Exemplo:
/// ```dart
/// StatusLineIndicator(status: StatusType.completed)
/// ```
class StatusLineIndicator extends StatelessWidget {
  const StatusLineIndicator({
    super.key,
    required this.status,
    this.height = 4,
  });

  final StatusType status;
  final double height;

  Color _getColor() {
    switch (status) {
      case StatusType.pending:
        return Colors.orange;
      case StatusType.approved:
        return Colors.green;
      case StatusType.completed:
        return Colors.blue;
      case StatusType.failed:
        return Colors.red;
      case StatusType.cancelled:
        return Colors.grey;
      case StatusType.overdue:
        return Colors.red.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: _getColor(),
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}
