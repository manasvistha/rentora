import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rentora/features/dashboard/domain/entities/dashboard_booking_entity.dart';
import 'package:rentora/features/dashboard/domain/entities/dashboard_property_entity.dart';
import 'package:rentora/features/dashboard/presentation/pages/property_detail_screen.dart';
import 'package:rentora/features/dashboard/presentation/providers/dashboard_data_providers.dart';

class AllPropertiesScreen extends ConsumerStatefulWidget {
  const AllPropertiesScreen({super.key});

  @override
  ConsumerState<AllPropertiesScreen> createState() =>
      _AllPropertiesScreenState();
}

class _AllPropertiesScreenState extends ConsumerState<AllPropertiesScreen> {
  late final TextEditingController _searchController;
  late final TextEditingController _minPriceController;
  late final TextEditingController _maxPriceController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _minPriceController = TextEditingController();
    _maxPriceController = TextEditingController();

    _searchController.addListener(_refresh);
    _minPriceController.addListener(_refresh);
    _maxPriceController.addListener(_refresh);
  }

  @override
  void dispose() {
    _searchController.removeListener(_refresh);
    _minPriceController.removeListener(_refresh);
    _maxPriceController.removeListener(_refresh);

    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {});
  }

  List<DashboardPropertyEntity> _filterProperties(
    List<DashboardPropertyEntity> items,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    final minPrice = double.tryParse(_minPriceController.text.trim());
    final maxPrice = double.tryParse(_maxPriceController.text.trim());

    return items.where((item) {
      final matchesQuery =
          query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.location.toLowerCase().contains(query);

      final matchesMin = minPrice == null || item.price >= minPrice;
      final matchesMax = maxPrice == null || item.price <= maxPrice;

      return matchesQuery && matchesMin && matchesMax;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(allPropertiesProvider(false));

    return _DashboardScaffold(
      child: state.when(
        data: (items) {
          final filteredItems = _filterProperties(items);
          return _PropertyList(
            items: filteredItems,
            emptyMessage: 'No properties found.',
            onRefresh: () => ref.refresh(allPropertiesProvider(true).future),
            onItemTap: (item) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PropertyDetailScreen(property: item),
                ),
              );
            },
            header: _PropertyFilterBar(
              searchController: _searchController,
              minPriceController: _minPriceController,
              maxPriceController: _maxPriceController,
            ),
          );
        },
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.refresh(allPropertiesProvider(true)),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myPropertiesProvider(false));

    return _DashboardScaffold(
      child: state.when(
        data: (items) => _PropertyList(
          items: items,
          emptyMessage: 'You have no listings yet.',
          onRefresh: () => ref.refresh(myPropertiesProvider(true).future),
          onItemTap: (item) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PropertyDetailScreen(property: item),
              ),
            );
          },
        ),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.refresh(myPropertiesProvider(true)),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myBookingsProvider(false));

    return _DashboardScaffold(
      child: state.when(
        data: (items) => _BookingList(
          items: items,
          emptyMessage: 'You have no bookings yet.',
          onRefresh: () => ref.refresh(myBookingsProvider(true).future),
        ),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.refresh(myBookingsProvider(true)),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class BookingRequestsScreen extends ConsumerWidget {
  const BookingRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingRequestsProvider(false));

    return _DashboardScaffold(
      child: state.when(
        data: (items) => _BookingList(
          items: items,
          emptyMessage: 'No booking requests found.',
          onRefresh: () => ref.refresh(bookingRequestsProvider(true).future),
        ),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.refresh(bookingRequestsProvider(true)),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _DashboardScaffold extends StatelessWidget {
  final Widget child;

  const _DashboardScaffold({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2F9E9A),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const SizedBox.shrink(),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2F9E9A), Color(0xFF6CCBC7), Color(0xFFD8F3F2)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _PropertyList extends StatelessWidget {
  final List<DashboardPropertyEntity> items;
  final String emptyMessage;
  final Future<void> Function() onRefresh;
  final Widget? header;
  final void Function(DashboardPropertyEntity item)? onItemTap;

  const _PropertyList({
    required this.items,
    required this.emptyMessage,
    required this.onRefresh,
    this.header,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasHeader = header != null;
    final hasItems = items.isNotEmpty;
    final totalItemCount = (hasHeader ? 1 : 0) + (hasItems ? items.length : 1);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        itemCount: totalItemCount,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (hasHeader && index == 0) {
            return header!;
          }

          if (!hasItems) {
            return _EmptyCard(message: emptyMessage);
          }

          final effectiveIndex = hasHeader ? index - 1 : index;
          final item = items[effectiveIndex];
          return _PropertyListCard(
            item: item,
            onTap: onItemTap == null ? null : () => onItemTap!(item),
          );
        },
      ),
    );
  }
}

class _PropertyFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final TextEditingController minPriceController;
  final TextEditingController maxPriceController;

  const _PropertyFilterBar({
    required this.searchController,
    required this.minPriceController,
    required this.maxPriceController,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 7,
          child: TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search by title, location...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFFF4F6F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFD0D7DE)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFD0D7DE)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF9CB4C8)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: TextField(
            controller: minPriceController,
            keyboardType: TextInputType.number,
            decoration: _priceInputDecoration('Min price'),
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          'to',
          style: TextStyle(
            color: Color(0xFF4B5A6A),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 2,
          child: TextField(
            controller: maxPriceController,
            keyboardType: TextInputType.number,
            decoration: _priceInputDecoration('Max price'),
          ),
        ),
      ],
    );
  }

  InputDecoration _priceInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: const Color(0xFFF4F6F8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD0D7DE)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD0D7DE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF9CB4C8)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}

class _PropertyListCard extends StatelessWidget {
  final DashboardPropertyEntity item;
  final VoidCallback? onTap;

  const _PropertyListCard({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
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
                      ? _imagePlaceholder(Icons.home_work_outlined)
                      : Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _imagePlaceholder(Icons.broken_image_outlined),
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
                      Text(
                        item.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF5E7A7E),
                        ),
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder(IconData icon) {
    return Container(
      color: const Color(0xFFE8EFED),
      child: Icon(icon, color: const Color(0xFF7A9390), size: 28),
    );
  }
}

class _BookingList extends StatelessWidget {
  final List<DashboardBookingEntity> items;
  final String emptyMessage;
  final Future<void> Function() onRefresh;

  const _BookingList({
    required this.items,
    required this.emptyMessage,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: items.isEmpty
          ? ListView(children: [_EmptyCard(message: emptyMessage)])
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _BookingCard(item: items[index]),
            ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final DashboardBookingEntity item;

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
        text.isEmpty ? 'Unknown' : text[0].toUpperCase() + text.substring(1),
        style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
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
