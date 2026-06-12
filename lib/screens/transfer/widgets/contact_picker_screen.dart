import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../../models/mbway_contact_model.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';

/// A contact chosen by the user (from frequent MB WAY contacts or the phone).
class PickedContact {
  const PickedContact({required this.name, required this.phone, this.photo});
  final String name;
  final String phone;
  final Uint8List? photo;
}

/// Lets the user pick a recipient: frequent MB WAY contacts (with photo/initials)
/// or import from the device's phone contacts (name, number, photo).
class ContactPickerScreen extends StatefulWidget {
  const ContactPickerScreen({super.key, this.frequent = const []});

  final List<MbWayContact> frequent;

  @override
  State<ContactPickerScreen> createState() => _ContactPickerScreenState();
}

class _ContactPickerScreenState extends State<ContactPickerScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _loadingDevice = false;
  bool _deviceLoaded = false;
  String? _deviceError;
  List<_DeviceContact> _device = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
        () => setState(() => _query = _searchController.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDeviceContacts() async {
    setState(() {
      _loadingDevice = true;
      _deviceError = null;
    });
    try {
      final granted = await FlutterContacts.requestPermission(readonly: true);
      if (!granted) {
        setState(() {
          _deviceError = 'Permissão de contactos negada.';
          _loadingDevice = false;
        });
        return;
      }
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withThumbnail: true,
      );
      final list = <_DeviceContact>[];
      for (final c in contacts) {
        if (c.phones.isEmpty) continue;
        list.add(_DeviceContact(
          name: c.displayName,
          phone: c.phones.first.number,
          photo: c.thumbnail,
        ));
      }
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      setState(() {
        _device = list;
        _deviceLoaded = true;
        _loadingDevice = false;
      });
    } catch (e) {
      setState(() {
        _deviceError = 'Erro ao aceder aos contactos: $e';
        _loadingDevice = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final freq = widget.frequent
        .where((c) =>
            _query.isEmpty ||
            c.name.toLowerCase().contains(_query) ||
            c.phone.contains(_query))
        .toList();
    final dev = _device
        .where((c) =>
            _query.isEmpty ||
            c.name.toLowerCase().contains(_query) ||
            c.phone.contains(_query))
        .toList();

    return Scaffold(
      backgroundColor: BJBankColors.surface,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Escolher contacto'),
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(BJBankSpacing.md),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Procurar por nome ou número',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: BJBankColors.surfaceVariant.withValues(alpha: 0.5),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: BJBankSpacing.sm),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: BJBankSpacing.lg),
              children: [
                if (freq.isNotEmpty) ...[
                  _sectionTitle('Frequentes'),
                  for (final c in freq)
                    _row(
                      name: c.name,
                      phone: c.formattedPhone,
                      initials: c.initials,
                      onTap: () => Navigator.pop(
                        context,
                        PickedContact(name: c.name, phone: c.phone),
                      ),
                    ),
                ],

                _sectionTitle('Contactos do telemóvel'),
                if (!_deviceLoaded && _deviceError == null)
                  Padding(
                    padding: const EdgeInsets.all(BJBankSpacing.md),
                    child: OutlinedButton.icon(
                      onPressed: _loadingDevice ? null : _loadDeviceContacts,
                      icon: _loadingDevice
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.contacts_rounded),
                      label: Text(_loadingDevice
                          ? 'A carregar…'
                          : 'Aceder aos contactos do telemóvel'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        foregroundColor: BJBankColors.primary,
                        side: BorderSide(
                            color: BJBankColors.primary.withValues(alpha: 0.4)),
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                if (_deviceError != null)
                  Padding(
                    padding: const EdgeInsets.all(BJBankSpacing.md),
                    child: Text(_deviceError!,
                        style: BJBankTypography.bodyMedium.copyWith(
                          color: BJBankColors.error,
                        )),
                  ),
                if (_deviceLoaded && dev.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(BJBankSpacing.md),
                    child: Text('Sem contactos com número.',
                        style: BJBankTypography.bodyMedium.copyWith(
                          color: BJBankColors.onSurfaceVariant,
                        )),
                  ),
                for (final c in dev)
                  _row(
                    name: c.name.isEmpty ? c.phone : c.name,
                    phone: c.phone,
                    photo: c.photo,
                    initials: _initials(c.name),
                    onTap: () => Navigator.pop(
                      context,
                      PickedContact(
                          name: c.name, phone: c.phone, photo: c.photo),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(
            BJBankSpacing.md, BJBankSpacing.sm, BJBankSpacing.md, BJBankSpacing.xs),
        child: Text(t,
            style: BJBankTypography.labelLarge.copyWith(
              color: BJBankColors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            )),
      );

  Widget _row({
    required String name,
    required String phone,
    String? initials,
    Uint8List? photo,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: BJBankColors.primary.withValues(alpha: 0.12),
        backgroundImage:
            (photo != null && photo.isNotEmpty) ? MemoryImage(photo) : null,
        child: (photo == null || photo.isEmpty)
            ? Text(
                initials ?? '?',
                style: BJBankTypography.titleSmall.copyWith(
                  color: BJBankColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              )
            : null,
      ),
      title: Text(name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: BJBankTypography.bodyMedium.copyWith(
            color: BJBankColors.onSurface,
            fontWeight: FontWeight.w600,
          )),
      subtitle: Text(phone,
          style: BJBankTypography.bodySmall.copyWith(
            color: BJBankColors.onSurfaceVariant,
          )),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }

  String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return '?';
    if (words.length == 1) return words.first[0].toUpperCase();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }
}

class _DeviceContact {
  const _DeviceContact({required this.name, required this.phone, this.photo});
  final String name;
  final String phone;
  final Uint8List? photo;
}
