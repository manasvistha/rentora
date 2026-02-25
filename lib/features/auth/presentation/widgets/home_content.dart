import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rentora/core/api/api_client.dart';
import 'package:rentora/core/api/api_endpoints.dart';

class HomeContent extends ConsumerStatefulWidget {
  const HomeContent({super.key});

  @override
  ConsumerState<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends ConsumerState<HomeContent> {
  List<_PropertyItem> _properties = const [];
  List<_BookingItem> _bookings = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final client = ref.read(apiClientProvider);

    try {
      final responses = await Future.wait([
        client.get(ApiEndpoints.propertyList),
        client.get(ApiEndpoints.bookingMy),
      ]);

      final propertyRaw = responses[0].data;
      final bookingRaw = responses[1].data;

      final propertyList = _extractList(propertyRaw);
      final bookingList = _extractList(bookingRaw);

      setState(() {
        _properties = propertyList.map(_PropertyItem.fromJson).toList();
        _bookings = bookingList.map(_BookingItem.fromJson).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to load home data. Pull down to retry.';
      });
    }
  }

  List<dynamic> _extractList(dynamic value) {
    if (value is List) return value;
    if (value is Map<String, dynamic>) {
      final data = value['data'];
      if (data is List) return data;
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAFBF7), Color(0xFFF4FBFA), Color(0xFFFFF7EF)],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _loadHomeData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            _HeroSummary(
              totalListings: _properties.length,
              totalBookings: _bookings.length,
              pendingBookings: _bookings
                  .where((booking) => booking.status.toLowerCase() == 'pending')
                  .length,
            ),
            const SizedBox(height: 16),
            if (_error != null)
              _ErrorCard(message: _error!, onRetry: _loadHomeData),
            if (_loading)
              const _LoadingSection()
            else ...[
              _SectionTitle(
                title: 'My Bookings',
                subtitle: 'Track your enlisted booking requests',
              ),
              const SizedBox(height: 10),
              if (_bookings.isEmpty)
                const _EmptyCard(
                  message: 'No bookings yet. Start by exploring properties.',
                )
              else
                ..._bookings
                    .take(5)
                    .map(
                      (booking) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _BookingCard(item: booking),
                      ),
                    ),
              const SizedBox(height: 18),
              const _SectionTitle(
                title: 'Featured Listings',
                subtitle: 'Fresh homes with real images from your backend',
              ),
              const SizedBox(height: 10),
              if (_properties.isEmpty)
                const _EmptyCard(message: 'No properties available right now.')
              else
                ..._properties.map(
                  (property) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PropertyCard(item: property),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeroSummary extends StatelessWidget {
  final int totalListings;
  final int totalBookings;
  final int pendingBookings;

  const _HeroSummary({
    required this.totalListings,
    required this.totalBookings,
    required this.pendingBookings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Dashboard',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.teal[900],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Manage your enlisted bookings and discover new properties.',
            style: TextStyle(color: Colors.blueGrey[600], fontSize: 13),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricChip(label: 'Listings', value: '$totalListings'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricChip(label: 'Bookings', value: '$totalBookings'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricChip(label: 'Pending', value: '$pendingBookings'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3FAF8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDAEEEA)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Color(0xFF0F766E),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF48696E)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF103033),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Color(0xFF5D7B7F)),
        ),
      ],
    );
  }
}

class _PropertyItem {
  final String id;
  final String title;
  final String location;
  final double price;
  final String status;
  final List<String> images;

  const _PropertyItem({
    required this.id,
    required this.title,
    required this.location,
    required this.price,
    required this.status,
    required this.images,
  });

  factory _PropertyItem.fromJson(dynamic raw) {
    final map = raw is Map ? raw.cast<String, dynamic>() : <String, dynamic>{};

    final imageRaw = map['images'];
    final imageList = imageRaw is List
        ? imageRaw.map((e) => e.toString()).toList()
        : <String>[];

    return _PropertyItem(
      id: (map['_id'] ?? '').toString(),
      title: (map['title'] ?? 'Untitled Property').toString(),
      location: (map['location'] ?? 'Unknown location').toString(),
      price: _asDouble(map['price']),
      status: (map['status'] ?? 'available').toString(),
      images: imageList,
    );
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String get imageUrl {
    if (images.isEmpty) return '';
    return _toAbsoluteImageUrl(images.first);
  }

  static String _toAbsoluteImageUrl(String raw) {
    if (raw.isEmpty) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;

    final apiUri = Uri.parse(ApiEndpoints.baseUrl);
    final basePath = apiUri.path.endsWith('/api/') ? '/api/' : apiUri.path;
    final hostPath = basePath.endsWith('/api/')
        ? basePath.substring(0, basePath.length - 5)
        : basePath;

    final sanitized = raw.startsWith('/') ? raw : '/$raw';

    return Uri(
      scheme: apiUri.scheme,
      host: apiUri.host,
      port: apiUri.hasPort ? apiUri.port : null,
      path: '$hostPath$sanitized',
    ).toString();
  }
}

class _BookingItem {
  final String id;
  final String propertyTitle;
  final String status;
  final DateTime? createdAt;

  const _BookingItem({
    required this.id,
    required this.propertyTitle,
    required this.status,
    required this.createdAt,
  });

  factory _BookingItem.fromJson(dynamic raw) {
    final map = raw is Map ? raw.cast<String, dynamic>() : <String, dynamic>{};
    final property = map['property'];

    String title = 'Property';
    if (property is Map) {
      title = (property['title'] ?? 'Property').toString();
    } else if (property != null) {
      title = property.toString();
    }

    return _BookingItem(
      id: (map['_id'] ?? '').toString(),
      propertyTitle: title,
      status: (map['status'] ?? 'pending').toString(),
      createdAt: DateTime.tryParse((map['createdAt'] ?? '').toString()),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  final _PropertyItem item;

  const _PropertyCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isAvailable =
        item.status.toLowerCase() == 'available' ||
        item.status.toLowerCase() == 'approved';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(16),
            ),
            child: SizedBox(
              width: 110,
              height: 110,
              child: item.imageUrl.isEmpty
                  ? Container(
                      color: const Color(0xFFE8EFED),
                      child: const Icon(
                        Icons.home_work_outlined,
                        color: Color(0xFF7A9390),
                        size: 28,
                      ),
                    )
                  : Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stackTrace) => Container(
                        color: const Color(0xFFE8EFED),
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: Color(0xFF7A9390),
                          size: 28,
                        ),
                      ),
                    ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 14,
                        color: Color(0xFF5E7A7E),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF5E7A7E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rs. ${item.price.toStringAsFixed(0)} / month',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _StatusBadge(
                    text: isAvailable ? 'Available' : item.status,
                    positive: isAvailable,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final _BookingItem item;

  const _BookingCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final status = item.status.toLowerCase();
    final isPending = status == 'pending';
    final isApproved = status == 'approved';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDFECE9)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.event_note_outlined,
              color: Color(0xFF0F766E),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.propertyTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.createdAt != null
                      ? DateFormat('MMM d, y • h:mm a').format(item.createdAt!)
                      : 'Recently updated',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B8487),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StatusBadge(text: status, positive: isApproved, neutral: isPending),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final bool positive;
  final bool neutral;

  const _StatusBadge({
    required this.text,
    this.positive = false,
    this.neutral = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    if (positive) {
      bg = const Color(0xFFE5F7EE);
      fg = const Color(0xFF0F7A43);
    } else if (neutral) {
      bg = const Color(0xFFFFF5E8);
      fg = const Color(0xFF9A5A0B);
    } else {
      bg = const Color(0xFFF8E8E8);
      fg = const Color(0xFF9B2C2C);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text[0].toUpperCase() + text.substring(1),
        style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;

  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2EFEC)),
      ),
      child: Text(message, style: const TextStyle(color: Color(0xFF5F7B7F))),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF4CECE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB42318)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF7A2424), fontSize: 12),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _LoadingSection extends StatelessWidget {
  const _LoadingSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 96,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
