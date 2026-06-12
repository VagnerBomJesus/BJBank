import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mbway_provider.dart';
import '../../models/money_request_model.dart';
import '../../services/supabase_money_request_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

/// Money requests inbox: received requests (approve / decline) and sent ones.
class MoneyRequestsScreen extends StatefulWidget {
  const MoneyRequestsScreen({super.key});

  @override
  State<MoneyRequestsScreen> createState() => _MoneyRequestsScreenState();
}

class _MoneyRequestsScreenState extends State<MoneyRequestsScreen> {
  final _service = SupabaseMoneyRequestService();
  bool _loading = true;
  List<MoneyRequest> _received = [];
  List<MoneyRequest> _sent = [];
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final received = await _service.obterRecebidos();
      final sent = await _service.obterEnviados();
      if (!mounted) return;
      setState(() {
        _received = received;
        _sent = sent;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack('Erro ao carregar: $e');
    }
  }

  Future<void> _approve(MoneyRequest r) async {
    setState(() => _busyId = r.id);
    try {
      final mbway = context.read<MbWayProvider>();
      final senderName = context.read<AuthProvider>().user?.name ?? 'Utilizador';
      final ok = await mbway.initiateMbWayPayment(
        recipientPhone: r.requesterPhone,
        recipientName: r.requesterName,
        amount: r.amount,
        description: r.description ?? 'Pedido MB WAY',
        senderName: senderName,
      );
      if (!ok) {
        _snack(mbway.errorMessage ?? 'Falha no pagamento');
        return;
      }
      await _service.marcarAprovado(r.id);
      _snack('Pedido aprovado e pago.', success: true);
      await _load();
    } catch (e) {
      _snack('Erro: $e');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _decline(MoneyRequest r) async {
    setState(() => _busyId = r.id);
    try {
      await _service.marcarRecusado(r.id);
      _snack('Pedido recusado.');
      await _load();
    } catch (e) {
      _snack('Erro: $e');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  void _snack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? BJBankColors.success : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: BJBankColors.surface,
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Pedidos'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Recebidos'),
              Tab(text: 'Enviados'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _load,
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _receivedList(),
                  _sentList(),
                ],
              ),
      ),
    );
  }

  Widget _receivedList() {
    if (_received.isEmpty) return _empty('Sem pedidos recebidos');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(BJBankSpacing.md),
        itemCount: _received.length,
        separatorBuilder: (_, __) => const SizedBox(height: BJBankSpacing.sm),
        itemBuilder: (context, i) => _receivedCard(_received[i]),
      ),
    );
  }

  Widget _sentList() {
    if (_sent.isEmpty) return _empty('Não enviaste pedidos');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(BJBankSpacing.md),
        itemCount: _sent.length,
        separatorBuilder: (_, __) => const SizedBox(height: BJBankSpacing.sm),
        itemBuilder: (context, i) => _sentCard(_sent[i]),
      ),
    );
  }

  Widget _receivedCard(MoneyRequest r) {
    final busy = _busyId == r.id;
    return Container(
      padding: const EdgeInsets.all(BJBankSpacing.md),
      decoration: BoxDecoration(
        color: BJBankColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: BJBankColors.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: BJBankColors.mbwayRed.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.smartphone_rounded,
                    color: BJBankColors.mbwayRed, size: 20),
              ),
              const SizedBox(width: BJBankSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${r.requesterName} pediu-te',
                        style: BJBankTypography.bodyMedium.copyWith(
                          color: BJBankColors.onSurface,
                          fontWeight: FontWeight.w600,
                        )),
                    if (r.description != null && r.description!.isNotEmpty)
                      Text(r.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BJBankTypography.bodySmall.copyWith(
                            color: BJBankColors.onSurfaceVariant,
                          )),
                  ],
                ),
              ),
              Text(r.formattedAmount,
                  style: BJBankTypography.valueMedium.copyWith(
                    color: BJBankColors.onSurface,
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
          const SizedBox(height: BJBankSpacing.sm),
          if (r.isPending)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : () => _decline(r),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: BJBankColors.error,
                      side: BorderSide(
                          color: BJBankColors.error.withValues(alpha: 0.4)),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('Recusar'),
                  ),
                ),
                const SizedBox(width: BJBankSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: busy ? null : () => _approve(r),
                    style: FilledButton.styleFrom(
                      backgroundColor: BJBankColors.primary,
                      shape: const StadiumBorder(),
                    ),
                    child: busy
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Aprovar e pagar'),
                  ),
                ),
              ],
            )
          else
            _statusChip(r.status),
        ],
      ),
    );
  }

  Widget _sentCard(MoneyRequest r) {
    return Container(
      padding: const EdgeInsets.all(BJBankSpacing.md),
      decoration: BoxDecoration(
        color: BJBankColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: BJBankColors.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: BJBankColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.call_made_rounded,
                color: BJBankColors.primary, size: 20),
          ),
          const SizedBox(width: BJBankSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Para ${r.payerPhone}',
                    style: BJBankTypography.bodyMedium.copyWith(
                      color: BJBankColors.onSurface,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 2),
                _statusChip(r.status),
              ],
            ),
          ),
          Text(r.formattedAmount,
              style: BJBankTypography.valueMedium.copyWith(
                color: BJBankColors.onSurface,
                fontWeight: FontWeight.w700,
              )),
        ],
      ),
    );
  }

  Widget _statusChip(MoneyRequestStatus status) {
    late Color c;
    late String label;
    switch (status) {
      case MoneyRequestStatus.pending:
        c = BJBankColors.warning;
        label = 'Pendente';
        break;
      case MoneyRequestStatus.approved:
        c = BJBankColors.success;
        label = 'Aprovado';
        break;
      case MoneyRequestStatus.declined:
        c = BJBankColors.error;
        label = 'Recusado';
        break;
      case MoneyRequestStatus.cancelled:
        c = BJBankColors.onSurfaceVariant;
        label = 'Cancelado';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: BJBankSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: BJBankTypography.labelSmall.copyWith(
            color: c,
            fontWeight: FontWeight.w700,
          )),
    );
  }

  Widget _empty(String msg) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(Icons.inbox_rounded,
            size: 56, color: BJBankColors.outline.withValues(alpha: 0.5)),
        const SizedBox(height: BJBankSpacing.md),
        Center(
          child: Text(msg,
              style: BJBankTypography.bodyMedium.copyWith(
                color: BJBankColors.onSurfaceVariant,
              )),
        ),
      ],
    );
  }
}
