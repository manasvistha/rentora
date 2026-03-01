import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rentora/core/api/api_client.dart';
import 'package:rentora/core/api/api_endpoints.dart';
import 'package:rentora/features/auth/presentation/view_model/auth_view_model.dart';
import 'package:rentora/features/dashboard/domain/entities/dashboard_booking_entity.dart';
import 'package:rentora/features/dashboard/domain/entities/dashboard_property_entity.dart';
import 'package:rentora/features/dashboard/domain/usecases/get_dashboard_snapshot_usecase.dart';
import 'package:rentora/features/dashboard/presentation/pages/dashboard_lists_screen.dart';

class HomeContent extends ConsumerStatefulWidget {
  const HomeContent({super.key});

  @override
  ConsumerState<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends ConsumerState<HomeContent> {
  List<_PropertyItem> _properties = const [];
  List<_PropertyItem> _myProperties = const [];
  List<_BookingItem> _bookings = const [];
  bool _loading = true;
  String? _error;
  String? _selectedPropertyId;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

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

    final useCase = ref.read(getDashboardSnapshotUseCaseProvider);
    final result = await useCase.execute(forceRefresh: true);

    result.fold(
      (_) {
        setState(() {
          _loading = false;
          _error = 'Failed to load home data. Pull down to retry.';
        });
      },
      (snapshot) {
        setState(() {
          _properties = snapshot.allProperties
              .map(_PropertyItem.fromEntity)
              .toList();
          _myProperties = snapshot.myProperties
              .map(_PropertyItem.fromEntity)
              .toList();
          _bookings = snapshot.myBookings.map(_BookingItem.fromEntity).toList();
          _loading = false;
        });
      },
    );
  }

  List<dynamic> _extractList(dynamic value) {
    if (value is List) return value;
    if (value is Map<String, dynamic>) {
      final data = value['data'];
      if (data is List) return data;
    }
    return const [];
  }

  Future<void> _addBooking() async {
    if (_selectedPropertyId == null || _selectedPropertyId!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a property first.')));
      return;
    }

    final client = ref.read(apiClientProvider);

    try {
      await client.post(
        ApiEndpoints.bookingCreate,
        data: {'propertyId': _selectedPropertyId},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking added successfully.')),
      );
      await _loadHomeData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add booking: $e')));
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    final client = ref.read(apiClientProvider);

    try {
      await client.dio.patch(ApiEndpoints.bookingCancel(bookingId));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Booking cancelled.')));
      await _loadHomeData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to cancel booking: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final greeting = _greeting();
    final rawName = authState.user?.name;
    final userName = (rawName != null && rawName.trim().isNotEmpty)
        ? rawName.trim()
        : 'User';
    final availableAll = _properties
        .where((property) => property.status.toLowerCase() == 'available')
        .toList();

    final totalListings = _myProperties.length;
    final availableNow = availableAll.length;
    final totalMarket = _properties.length;

    return Container(
      child: RefreshIndicator(
        onRefresh: _loadHomeData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(
                  'assets/images/Logo.png',
                  height: 30,
                  fit: BoxFit.contain,
                ),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No notifications yet.')),
                    );
                  },
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _DashboardHeader(
              greeting: greeting,
              userName: userName,
              totalListings: totalListings,
              availableNow: availableNow,
              totalMarket: totalMarket,
            ),
            const SizedBox(height: 16),
            if (_error != null)
              _ErrorCard(message: _error!, onRetry: _loadHomeData),
            if (_loading) const _LoadingSection(),
            if (!_loading) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _SectionTitle(
                    title: 'Explore Rentals',
                    subtitle: 'Recent listings from the platform',
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AllPropertiesScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('View all'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color.fromARGB(255, 9, 9, 11),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_properties.isEmpty)
                const _EmptyCard(message: 'No properties available right now.')
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _properties.length > 6 ? 6 : _properties.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 22,
                    crossAxisSpacing: 22,
                    childAspectRatio: 0.65,
                  ),
                  itemBuilder: (context, index) =>
                      _PropertyGridCard(item: _properties[index]),
                ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final String greeting;
  final String userName;
  final int totalListings;
  final int availableNow;
  final int totalMarket;

  const _DashboardHeader({
    required this.greeting,
    required this.userName,
    required this.totalListings,
    required this.availableNow,
    required this.totalMarket,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2F9E9A), Color(0xFF63C7C1)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFFE0F2EE),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            userName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Here's what's happening in your workspace today.",
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _TopMetric(
                  label: 'My Listings',
                  value: '$totalListings',
                  icon: Icons.apartment_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TopMetric(
                  label: 'Available Now',
                  value: '$availableNow',
                  icon: Icons.trending_up_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TopMetric(
                  label: 'Total Market',
                  value: '$totalMarket',
                  icon: Icons.search_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _TopMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableBookingCard extends StatelessWidget {
  final _BookingItem item;
  final VoidCallback onCancel;

  const _EditableBookingCard({required this.item, required this.onCancel});

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
      child: Column(
        children: [
          Row(
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
                          ? DateFormat(
                              'MMM d, y • h:mm a',
                            ).format(item.createdAt!)
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
              _StatusBadge(
                text: status,
                positive: isApproved,
                neutral: isPending,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
              label: const Text(
                'Cancel My Booking',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrowseBookingCard extends StatelessWidget {
  final _PropertyItem item;
  final VoidCallback onBookNow;

  const _BrowseBookingCard({required this.item, required this.onBookNow});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PropertyCard(item: item),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 8),
          child: ElevatedButton.icon(
            onPressed: onBookNow,
            icon: const Icon(Icons.book_online_outlined),
            label: const Text('Book This Property'),
          ),
        ),
      ],
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

    final imageList = _extractImages(map);

    return _PropertyItem(
      id: (map['_id'] ?? '').toString(),
      title: (map['title'] ?? 'Untitled Property').toString(),
      location: (map['location'] ?? 'Unknown location').toString(),
      price: _asDouble(map['price']),
      status: (map['status'] ?? 'available').toString(),
      images: imageList,
    );
  }

  factory _PropertyItem.fromEntity(DashboardPropertyEntity entity) {
    return _PropertyItem(
      id: entity.id,
      title: entity.title,
      location: entity.location,
      price: entity.price,
      status: entity.status,
      images: entity.images,
    );
  }

  static List<String> _extractImages(Map<String, dynamic> map) {
    final images = <String>[];

    void addIfValid(dynamic value) {
      if (value == null) return;
      final s = value.toString().trim();
      if (s.isNotEmpty) images.add(s);
    }

    final imageRaw = map['images'];
    if (imageRaw is List) {
      for (final item in imageRaw) {
        if (item is Map) {
          addIfValid(item['url'] ?? item['path'] ?? item['src']);
        } else {
          addIfValid(item);
        }
      }
    }

    // Common backend variants for a single preview image.
    for (final key in ['image', 'thumbnail', 'cover', 'photo', 'imageUrl']) {
      addIfValid(map[key]);
    }

    // Deduplicate while preserving order.
    final seen = <String>{};
    return images.where((url) => seen.add(url)).toList();
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

    // If backend returned an absolute URL pointing to localhost, remap it to the
    // API host so the Android emulator/device can reach it.
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      final uri = Uri.tryParse(raw);
      if (uri == null) return raw;

      const localHosts = {'localhost', '127.0.0.1', '0.0.0.0'};
      if (!localHosts.contains(uri.host)) return raw;

      final apiUri = Uri.parse(ApiEndpoints.baseUrl);
      return uri.replace(host: apiUri.host, port: apiUri.port).toString();
    }

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

  factory _BookingItem.fromEntity(DashboardBookingEntity entity) {
    return _BookingItem(
      id: entity.id,
      propertyTitle: entity.propertyTitle,
      status: entity.status,
      createdAt: entity.createdAt,
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

class _PropertyGridCard extends StatelessWidget {
  final _PropertyItem item;

  const _PropertyGridCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isAvailable =
        item.status.toLowerCase() == 'available' ||
        item.status.toLowerCase() == 'approved';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: const Color(0xFFE5ECEA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: AspectRatio(
              aspectRatio: 4 / 3,
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
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: const Color(0xFFE8EFED),
                          alignment: Alignment.center,
                          child: const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
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
