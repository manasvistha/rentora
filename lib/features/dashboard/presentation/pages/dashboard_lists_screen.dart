import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rentora/core/api/api_client.dart';
import 'package:rentora/core/api/api_endpoints.dart';
import 'package:rentora/features/dashboard/domain/entities/dashboard_booking_entity.dart';
import 'package:rentora/features/dashboard/domain/entities/dashboard_property_entity.dart';
import 'package:rentora/features/dashboard/domain/usecases/update_booking_status_usecase.dart';
import 'package:rentora/features/dashboard/presentation/pages/property_detail_screen.dart';
import 'package:rentora/features/dashboard/presentation/pages/create_property_screen.dart';
import 'package:rentora/features/dashboard/presentation/providers/dashboard_data_providers.dart';

enum PropertyListPreset { totalMarket, availableNow, myListings }

class AllPropertiesScreen extends ConsumerStatefulWidget {
  final PropertyListPreset initialPreset;

  const AllPropertiesScreen({
    super.key,
    this.initialPreset = PropertyListPreset.totalMarket,
  });

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

    final presetItems = switch (widget.initialPreset) {
      PropertyListPreset.availableNow =>
        items
            .where((item) => item.status.toLowerCase() == 'available')
            .toList(),
      _ => items,
    };

    return presetItems.where((item) {
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
    final state = widget.initialPreset == PropertyListPreset.myListings
        ? ref.watch(myPropertiesProvider(false))
        : ref.watch(allPropertiesProvider(false));

    final emptyMessage = switch (widget.initialPreset) {
      PropertyListPreset.availableNow => 'No available properties found.',
      PropertyListPreset.myListings => 'You have no listings yet.',
      PropertyListPreset.totalMarket => 'No properties found.',
    };

    return _DashboardScaffold(
      child: state.when(
        data: (items) {
          final filteredItems = _filterProperties(items);
          return _PropertyList(
            items: filteredItems,
            emptyMessage: emptyMessage,
            onRefresh: () {
              if (widget.initialPreset == PropertyListPreset.myListings) {
                return ref.refresh(myPropertiesProvider(true).future);
              }
              return ref.refresh(allPropertiesProvider(true).future);
            },
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
          onRetry: () {
            if (widget.initialPreset == PropertyListPreset.myListings) {
              ref.refresh(myPropertiesProvider(true));
              return;
            }
            ref.refresh(allPropertiesProvider(true));
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class MyListingsScreen extends ConsumerStatefulWidget {
  const MyListingsScreen({super.key});

  @override
  ConsumerState<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends ConsumerState<MyListingsScreen> {
  Future<void> _refreshListings({bool forceRefresh = true}) async {
    if (forceRefresh) {
      await ref.refresh(myPropertiesProvider(true).future);
    }
    ref.invalidate(myPropertiesProvider(false));
    ref.invalidate(myPropertiesProvider(true));
    ref.invalidate(allPropertiesProvider(false));
    ref.invalidate(allPropertiesProvider(true));
  }

  Future<void> _deleteListing(DashboardPropertyEntity item) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete listing'),
          content: Text('Delete "${item.title}" permanently?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      final client = ref.read(apiClientProvider);
      await client.delete(ApiEndpoints.propertyById(item.id));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Listing deleted.')));
      await _refreshListings();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete listing: $e')));
    }
  }

  Future<void> _editListing(DashboardPropertyEntity item) async {
    // Open full create/edit screen with property data so user can update all fields and images
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreatePropertyScreen(
          property: {
            '_id': item.id,
            'title': item.title,
            'location': item.location,
            'price': item.price,
            'images': item.images,
          },
          propertyId: item.id,
        ),
      ),
    );

    // After returning, refresh listings
    await _refreshListings();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myPropertiesProvider(false));

    return _DashboardScaffold(
      child: state.when(
        data: (items) => _PropertyList(
          items: items,
          emptyMessage: 'You have no listings yet.',
          onRefresh: _refreshListings,
          onItemTap: (item) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PropertyDetailScreen(property: item),
              ),
            );
          },
          onEditTap: _editListing,
        ),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => _refreshListings(),
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
          onOpenProperty: (item) {
            if (item.propertyId.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Property details unavailable.')),
              );
              return;
            }

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PropertyDetailScreen(
                  property: DashboardPropertyEntity(
                    id: item.propertyId,
                    title: item.propertyTitle,
                    location: item.propertyLocation,
                    price: item.propertyPrice,
                    status: item.status,
                    images: item.propertyImageUrl.isEmpty
                        ? const []
                        : [item.propertyImageUrl],
                  ),
                ),
              ),
            );
          },
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

class BookingRequestsScreen extends ConsumerStatefulWidget {
  const BookingRequestsScreen({super.key});

  @override
  ConsumerState<BookingRequestsScreen> createState() =>
      _BookingRequestsScreenState();
}

class _BookingRequestsScreenState extends ConsumerState<BookingRequestsScreen> {
  final Set<String> _processingIds = <String>{};
  final Map<String, String> _statusOverrides = <String, String>{};

  Future<void> _updateRequestStatus(String bookingId, String status) async {
    setState(() => _processingIds.add(bookingId));

    final result = await ref
        .read(updateBookingStatusUseCaseProvider)
        .execute(bookingId, status);

    if (!mounted) return;
    setState(() => _processingIds.remove(bookingId));

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: Colors.red.shade600,
          ),
        );
      },
      (_) async {
        setState(() {
          _statusOverrides[bookingId] = status;
        });

        final message = status == 'approved'
            ? 'Booking request approved.'
            : 'Booking request rejected.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: const Color(0xFF2F9E9A),
          ),
        );

        await ref.refresh(bookingRequestsProvider(true).future);
        ref.invalidate(myBookingsProvider(false));
        ref.invalidate(myBookingsProvider(true));
        ref.invalidate(allPropertiesProvider(false));
        ref.invalidate(allPropertiesProvider(true));
        ref.invalidate(myPropertiesProvider(false));
        ref.invalidate(myPropertiesProvider(true));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingRequestsProvider(false));

    return _DashboardScaffold(
      child: state.when(
        data: (items) => _BookingList(
          items: items,
          emptyMessage: 'No booking requests found.',
          onRefresh: () => ref.refresh(bookingRequestsProvider(true).future),
          processingIds: _processingIds,
          statusOverrides: _statusOverrides,
          onApprove: (bookingId) => _updateRequestStatus(bookingId, 'approved'),
          onReject: (bookingId) => _updateRequestStatus(bookingId, 'rejected'),
          onOpenProperty: (item) {
            if (item.propertyId.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Property details unavailable.')),
              );
              return;
            }

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PropertyDetailScreen(
                  property: DashboardPropertyEntity(
                    id: item.propertyId,
                    title: item.propertyTitle,
                    location: item.propertyLocation,
                    price: item.propertyPrice,
                    status: item.status,
                    images: item.propertyImageUrl.isEmpty
                        ? const []
                        : [item.propertyImageUrl],
                  ),
                ),
              ),
            );
          },
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
  final Future<void> Function(DashboardPropertyEntity item)? onEditTap;
  final Future<void> Function(DashboardPropertyEntity item)? onDeleteTap;

  const _PropertyList({
    required this.items,
    required this.emptyMessage,
    required this.onRefresh,
    this.header,
    this.onItemTap,
    this.onEditTap,
    this.onDeleteTap,
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
            onEdit: onEditTap == null ? null : () => onEditTap!(item),
            onDelete: onDeleteTap == null ? null : () => onDeleteTap!(item),
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
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _PropertyListCard({
    required this.item,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

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
                      if (onEdit != null || onDelete != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (onEdit != null)
                              TextButton.icon(
                                onPressed: onEdit,
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF1D4ED8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  minimumSize: const Size(0, 30),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                label: const Text('Edit'),
                              ),
                            if (onDelete != null)
                              TextButton.icon(
                                onPressed: onDelete,
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFFB91C1C),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  minimumSize: const Size(0, 30),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 16,
                                ),
                                label: const Text('Delete'),
                              ),
                          ],
                        ),
                      ],
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
  final Set<String> processingIds;
  final Map<String, String> statusOverrides;
  final Future<void> Function(String bookingId)? onApprove;
  final Future<void> Function(String bookingId)? onReject;
  final void Function(DashboardBookingEntity item)? onOpenProperty;

  const _BookingList({
    required this.items,
    required this.emptyMessage,
    required this.onRefresh,
    this.processingIds = const {},
    this.statusOverrides = const {},
    this.onApprove,
    this.onReject,
    this.onOpenProperty,
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
              itemBuilder: (context, index) {
                final item = items[index];
                return _BookingCard(
                  item: item,
                  statusOverride: statusOverrides[item.id],
                  onTap: onOpenProperty == null
                      ? null
                      : () => onOpenProperty!(item),
                  showOwnerActions: onApprove != null && onReject != null,
                  processing: processingIds.contains(item.id),
                  onApprove: onApprove == null
                      ? null
                      : () => onApprove!(item.id),
                  onReject: onReject == null ? null : () => onReject!(item.id),
                );
              },
            ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final DashboardBookingEntity item;
  final String? statusOverride;
  final VoidCallback? onTap;
  final bool showOwnerActions;
  final bool processing;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _BookingCard({
    required this.item,
    this.statusOverride,
    this.onTap,
    this.showOwnerActions = false,
    this.processing = false,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final status = (statusOverride ?? item.status).toLowerCase();
    final isPending = status == 'pending';
    final isApproved = status == 'approved';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDFECE9)),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 76,
                      height: 76,
                      child: item.propertyImageUrl.isEmpty
                          ? Container(
                              color: const Color(0xFFE8EFED),
                              child: const Icon(
                                Icons.home_work_outlined,
                                color: Color(0xFF7A9390),
                                size: 24,
                              ),
                            )
                          : Image.network(
                              item.propertyImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: const Color(0xFFE8EFED),
                                  child: const Icon(
                                    Icons.broken_image_outlined,
                                    color: Color(0xFF7A9390),
                                    size: 24,
                                  ),
                                );
                              },
                            ),
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
                          item.propertyLocation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF5E7A7E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rs. ${item.propertyPrice.toStringAsFixed(0)} / month',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                        if (showOwnerActions &&
                            (item.requesterName.isNotEmpty ||
                                item.requesterEmail.isNotEmpty)) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.requesterName.isNotEmpty
                                ? 'Requested by: ${item.requesterName}'
                                : item.requesterEmail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B8487),
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
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
              if (showOwnerActions && isPending) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: processing ? null : onReject,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF9B2C2C),
                          side: const BorderSide(color: Color(0xFFE8B4B4)),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: processing ? null : onApprove,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2F9E9A),
                          foregroundColor: Colors.white,
                        ),
                        child: processing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Accept'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
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
      bg = const Color(0xFFE5F7EE);
      fg = const Color(0xFF0F7A43);
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
