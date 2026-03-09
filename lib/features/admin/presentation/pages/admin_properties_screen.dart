import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/api/api_endpoints.dart';
import 'package:rentora/features/dashboard/domain/entities/dashboard_property_entity.dart';
import 'package:rentora/features/dashboard/presentation/pages/property_detail_screen.dart';
import '../providers/admin_providers.dart';

class AdminPropertiesScreen extends ConsumerWidget {
  const AdminPropertiesScreen({super.key});

  static const _accent = Color(0xFF10B981);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminPropertiesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFE8F8F5),
      appBar: AppBar(
        title: const Text('Admin Properties'),
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
              return const Center(child: Text('No properties found'));
            }
            return RefreshIndicator(
              onRefresh: () =>
                  ref.read(adminPropertiesProvider.notifier).fetch(),
              child: ListView.separated(
                padding: const EdgeInsets.all(14),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final raw = items[index];
                  final item = raw is Map<String, dynamic>
                      ? raw
                      : <String, dynamic>{};
                  final id = (item['id'] ?? item['_id'] ?? '').toString();
                  final title = (item['title'] ?? 'Untitled').toString();
                  final location = (item['location'] ?? 'Unknown location')
                      .toString();
                  final status = (item['status'] ?? 'pending').toString();
                  final price = item['price'];
                  final images = (item['images'] is List)
                      ? (item['images'] as List)
                            .map((e) => e.toString())
                            .toList()
                      : <String>[];
                  final imageUrl = _resolveImage(
                    images.isNotEmpty ? images.first : null,
                  );

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PropertyDetailScreen(
                              property: DashboardPropertyEntity(
                                id: id,
                                title: title,
                                location: location,
                                price: price is num
                                    ? price.toDouble()
                                    : double.tryParse(
                                            price?.toString() ?? '',
                                          ) ??
                                          0,
                                status: status,
                                images: images,
                              ),
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    width: 82,
                                    height: 82,
                                    color: const Color(0xFFEFF6FF),
                                    child: imageUrl == null
                                        ? const Icon(
                                            Icons.home_work,
                                            color: _accent,
                                          )
                                        : Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(
                                                  Icons.home_work,
                                                  color: _accent,
                                                ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.place_outlined,
                                            size: 15,
                                            color: Color(0xFF64748B),
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              location,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 7),
                                      Text(
                                        price == null
                                            ? 'Price unavailable'
                                            : 'NPR $price',
                                        style: const TextStyle(
                                          color: Color(0xFF0F766E),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _statusChip(status),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _actionButton(
                                  label: 'Approve',
                                  color: const Color(0xFF16A34A),
                                  onTap: () => _confirmStatus(
                                    context,
                                    ref,
                                    id,
                                    'approved',
                                  ),
                                ),
                                _actionButton(
                                  label: 'Reject',
                                  color: const Color(0xFFDC2626),
                                  onTap: () => _confirmStatus(
                                    context,
                                    ref,
                                    id,
                                    'rejected',
                                  ),
                                ),
                                _actionButton(
                                  label: 'Delete',
                                  color: const Color(0xFF7F1D1D),
                                  onTap: () => _confirmDelete(context, ref, id),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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

  Widget _statusChip(String status) {
    final normalized = status.toLowerCase();
    Color bg;
    Color fg;
    switch (normalized) {
      case 'approved':
      case 'available':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF166534);
        break;
      case 'rejected':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFF991B1B);
        break;
      default:
        bg = const Color(0xFFFEF9C3);
        fg = const Color(0xFF854D0E);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        normalized,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(92, 34),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
      child: Text(label),
    );
  }

  Future<void> _confirmStatus(
    BuildContext context,
    WidgetRef ref,
    String id,
    String status,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Set status to $status?'),
        content: const Text('This will update the property listing status.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await ref.read(adminPropertiesProvider.notifier).updateStatus(id, status);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete property?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await ref.read(adminPropertiesProvider.notifier).deleteProperty(id);
    }
  }

  String? _resolveImage(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final value = raw.trim();
    if (value.startsWith('http://') || value.startsWith('https://')) {
      final uri = Uri.tryParse(value);
      if (uri == null) return value;
      const localHosts = {'localhost', '127.0.0.1', '0.0.0.0'};
      if (!localHosts.contains(uri.host)) return value;

      final apiUri = Uri.parse(ApiEndpoints.baseUrl);
      return uri.replace(host: apiUri.host, port: apiUri.port).toString();
    }
    final host = ApiEndpoints.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    if (value.startsWith('/')) return '$host$value';
    return '$host/public/property-images/$value';
  }
}
