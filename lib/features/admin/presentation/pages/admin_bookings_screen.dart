import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_providers.dart';

class AdminBookingsScreen extends ConsumerWidget {
  const AdminBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminBookingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F5),
      appBar: AppBar(
        title: const Text('Monitor Bookings'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(e.toString())),
        data: (either) => either.fold(
          (failure) => Center(child: Text('Error: ${failure.message}')),
          (items) {
            if (items.isEmpty) {
              return const Center(child: Text('No bookings found'));
            }

            return RefreshIndicator(
              onRefresh: () => ref.read(adminBookingsProvider.notifier).fetch(),
              child: ListView.separated(
                padding: const EdgeInsets.all(14),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final raw = items[index];
                  final item = raw is Map<String, dynamic>
                      ? raw
                      : <String, dynamic>{};

                  final property = _asMap(item['property']);
                  final user = _asMap(item['user']);
                  final owner = _asMap(item['owner']);

                  final propertyTitle =
                      (property['title'] ?? item['propertyTitle'] ?? 'Property')
                          .toString();
                  final tenantName =
                      (user['name'] ??
                              user['email'] ??
                              item['tenant'] ??
                              'User')
                          .toString();
                  final ownerName =
                      (owner['name'] ??
                              owner['email'] ??
                              item['ownerName'] ??
                              'Owner')
                          .toString();
                  final status = (item['status'] ?? 'pending')
                      .toString()
                      .toLowerCase();
                  final createdAt = _parseDate(item['createdAt']);
                  final createdText = createdAt == null
                      ? 'Unknown date'
                      : '${createdAt.year.toString().padLeft(4, '0')}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                propertyTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            _statusChip(status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _infoRow('Tenant', tenantName),
                        const SizedBox(height: 4),
                        _infoRow('Owner', ownerName),
                        const SizedBox(height: 4),
                        _infoRow('Created', createdText),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    return <String, dynamic>{};
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 62,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
          ),
        ),
      ],
    );
  }

  Widget _statusChip(String status) {
    Color bg;
    Color fg;
    switch (status) {
      case 'approved':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF166534);
        break;
      case 'rejected':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFF991B1B);
        break;
      case 'cancelled':
        bg = const Color(0xFFE2E8F0);
        fg = const Color(0xFF334155);
        break;
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
