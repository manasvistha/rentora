import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rentora/core/api/api_client.dart';
import 'package:rentora/core/api/api_endpoints.dart';
import 'package:rentora/core/services/storage/user_session_service.dart';
import 'package:rentora/core/utils/property_coordinates.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:rentora/features/dashboard/presentation/pages/create_property_screen.dart';
import 'package:rentora/features/dashboard/domain/entities/dashboard_property_entity.dart';
import 'package:rentora/features/dashboard/domain/usecases/create_booking_request_usecase.dart';
import 'package:rentora/features/dashboard/presentation/widgets/property_location_preview.dart';
import 'package:rentora/features/message/domain/usecases/create_conversation_usecase.dart';
import 'package:rentora/features/message/presentation/pages/chat_screen.dart';

class PropertyDetailScreen extends ConsumerStatefulWidget {
  final DashboardPropertyEntity property;

  const PropertyDetailScreen({super.key, required this.property});

  @override
  ConsumerState<PropertyDetailScreen> createState() =>
      _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _details;
  PageController? _imagePageController;
  int _currentImageIndex = 0;
  bool _isOwner = false;
  String? _ownerId;
  String? _ownerName;
  String? _ownerEmail;
  PropertyCoordinates? _userCoordinates;
  bool _locatingUser = false;
  String? _locationError;
  bool _bookingSubmitting = false;
  bool _bookingRequestSent = false;

  PageController get _pageController {
    _imagePageController ??= PageController(initialPage: _currentImageIndex);
    return _imagePageController!;
  }

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  @override
  void dispose() {
    _imagePageController?.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = ref.read(apiClientProvider);
      final response = await client.get(
        ApiEndpoints.propertyById(widget.property.id),
      );

      final extracted = _extractMap(response.data);

      if (!mounted) return;
      // Determine ownership by comparing stored user id with owner field
      final sessionService = ref.read(userSessionServiceProvider);
      final session = await sessionService.getUserSession();
      final currentUserId = session['id'];

      String? ownerId;
      String? ownerName;
      String? ownerEmail;
      if (extracted != null) {
        final owner =
            extracted['owner'] ??
            extracted['user'] ??
            extracted['listedBy'] ??
            extracted['ownerId'];
        if (owner is String) ownerId = owner;
        if (owner is Map) {
          if (owner['_id'] != null) ownerId = owner['_id'].toString();
          if (owner['id'] != null) ownerId = owner['id'].toString();
          ownerName =
              (owner['name'] ?? owner['fullName'] ?? owner['displayName'])
                  ?.toString();
          ownerEmail = (owner['email'] ?? owner['username'])?.toString();
        }
      }

      setState(() {
        _details = extracted;
        _isOwner =
            currentUserId != null &&
            ownerId != null &&
            currentUserId == ownerId;
        _ownerId = ownerId;
        _ownerName = ownerName;
        _ownerEmail = ownerEmail;
        _loading = false;
      });

      if (!_isOwner && currentUserId != null && currentUserId.isNotEmpty) {
        _loadMyBookingStatus();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to fetch full property details.';
        _loading = false;
      });
    }
  }

  Future<void> _loadMyBookingStatus() async {
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.get(ApiEndpoints.bookingMy);

      final raw = response.data;
      final list = raw is List
          ? raw
          : (raw is Map<String, dynamic> && raw['data'] is List
                ? raw['data'] as List
                : const <dynamic>[]);

      bool sent = false;
      for (final item in list) {
        if (item is! Map) continue;
        final map = item.cast<String, dynamic>();
        final property = map['property'];
        final propertyId = property is Map
            ? (property['_id'] ?? property['id'] ?? '').toString()
            : property?.toString() ?? '';
        final bookingStatus = (map['status'] ?? '').toString().toLowerCase();
        if (propertyId == widget.property.id &&
            (bookingStatus == 'pending' || bookingStatus == 'approved')) {
          sent = true;
          break;
        }
      }

      if (!mounted) return;
      setState(() => _bookingRequestSent = sent);
    } catch (_) {
      // Keep booking button usable even if status lookup fails.
    }
  }

  Map<String, dynamic>? _extractMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is Map<String, dynamic>) return data;
      return raw;
    }
    if (raw is Map) {
      final mapped = raw.cast<String, dynamic>();
      final data = mapped['data'];
      if (data is Map) return data.cast<String, dynamic>();
      return mapped;
    }
    return null;
  }

  String _toAbsoluteImageUrl(String raw) {
    if (raw.isEmpty) return '';

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

  List<String> _resolveImages(Map<String, dynamic>? map) {
    final images = <String>[];

    void addIfValid(dynamic value) {
      if (value == null) return;
      final text = value.toString().trim();
      if (text.isEmpty) return;
      final normalized = _toAbsoluteImageUrl(text);
      if (normalized.isNotEmpty) images.add(normalized);
    }

    if (map != null) {
      final rawImages = map['images'];
      if (rawImages is List) {
        for (final image in rawImages) {
          if (image is Map) {
            addIfValid(image['url'] ?? image['path'] ?? image['src']);
          } else {
            addIfValid(image);
          }
        }
      }

      for (final key in ['image', 'thumbnail', 'cover', 'photo', 'imageUrl']) {
        addIfValid(map[key]);
      }
    }

    if (images.isEmpty && widget.property.imageUrl.isNotEmpty) {
      images.add(widget.property.imageUrl);
    }

    final seen = <String>{};
    return images.where((image) => seen.add(image)).toList();
  }

  Future<void> _removeImageByUrl(String imageUrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove image'),
        content: const Text('Remove this image from the property?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() => _loading = true);
      final client = ref.read(apiClientProvider);
      final id = widget.property.id;

      // Send removedImages as JSON array; backend should handle URL/path matching
      await client.put(
        ApiEndpoints.propertyById(id),
        data: {
          'removedImages': [imageUrl],
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image removed'),
          backgroundColor: Color(0xFF2F9E9A),
        ),
      );
      await _loadDetails();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove image: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
      setState(() => _loading = false);
    }
  }

  Future<void> _locateCurrentUser() async {
    setState(() {
      _locatingUser = true;
      _locationError = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Please enable location service on your device.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is required to show your position on the map.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (!mounted) return;
      setState(() {
        _userCoordinates = PropertyCoordinates(
          latitude: position.latitude,
          longitude: position.longitude,
        ).rounded();
        _locatingUser = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = e is Exception
            ? e.toString().replaceFirst('Exception: ', '')
            : 'Unable to fetch your current location.';
        _locatingUser = false;
      });
    }
  }

  Future<void> _openConversationWithOwner() async {
    try {
      final ownerId = _ownerId;
      if (ownerId == null || ownerId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Owner information unavailable')),
        );
        return;
      }

      final session = await ref
          .read(userSessionServiceProvider)
          .getUserSession();
      final currentUserId = session['id'];
      if (currentUserId == null || currentUserId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login again to start chat')),
        );
        return;
      }

      final usecase = ref.read(createConversationUseCaseProvider);
      final res = await usecase.execute(participants: [currentUserId, ownerId]);

      res.fold(
        (failure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(failure.message)));
        },
        (conversation) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(conversationId: conversation.id),
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to start chat: $e')));
    }
  }

  Future<void> _requestBooking() async {
    if (_bookingSubmitting) return;
    setState(() => _bookingSubmitting = true);

    final result = await ref
        .read(createBookingRequestUseCaseProvider)
        .execute(widget.property.id);

    if (!mounted) return;
    setState(() => _bookingSubmitting = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      (_) {
        setState(() => _bookingRequestSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Booking request sent. Owner will be notified and must accept first.',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  Future<void> _showBookingOptions() async {
    if (!mounted || _bookingSubmitting || _bookingRequestSent) return;

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose booking option',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF103033),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.payments_outlined),
                  title: const Text('Pay & Book'),
                  subtitle: const Text(
                    'Proceed with payment and send request.',
                  ),
                  onTap: () => Navigator.of(ctx).pop('pay'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.bookmark_add_outlined),
                  title: const Text('Book Only'),
                  subtitle: const Text('Send booking request without payment.'),
                  onTap: () => Navigator.of(ctx).pop('book'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selected == null) return;

    if (selected == 'pay') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Payment flow will open here. Sending request for now.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    await _requestBooking();
  }

  @override
  Widget build(BuildContext context) {
    final property = _details ?? <String, dynamic>{};
    final title = (property['title'] ?? widget.property.title).toString();
    final location = (property['location'] ?? widget.property.location)
        .toString();
    final status = (property['status'] ?? widget.property.status)
        .toString()
        .toLowerCase();
    final priceValue = property['price'];
    final price = priceValue is num
        ? priceValue.toDouble()
        : double.tryParse(priceValue?.toString() ?? '') ??
              widget.property.price;
    final description = (property['description'] ?? '').toString();
    final propertyType =
        (property['propertyType'] ??
                property['property_type'] ??
                property['type'] ??
                '')
            .toString();
    final floorNumber = (property['floor'] ?? property['floorNumber'] ?? '')
        .toString();
    final petPolicy =
        (property['petPolicy'] ??
                property['petsPolicy'] ??
                property['pet_policy'] ??
                '')
            .toString();
    final bedrooms = property['bedrooms']?.toString();
    final bathrooms = property['bathrooms']?.toString();
    final area = property['area']?.toString();
    final furnished = property['furnished'];
    final amenitiesRaw = property['amenities'];
    final amenities = amenitiesRaw is List
        ? amenitiesRaw.map((item) => item.toString()).toList()
        : <String>[];

    final propertyCoordinates = parsePropertyCoordinates(property);
    final imageUrls = _resolveImages(_details);
    final isAvailable = status == 'available' || status == 'approved';

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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.only(top: 50),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        )
                      else if (_error != null)
                        _DetailCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _error!,
                                style: const TextStyle(
                                  color: Color(0xFF7A2424),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _loadDetails,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: AspectRatio(
                            aspectRatio: 16 / 10,
                            child: imageUrls.isEmpty
                                ? Container(
                                    color: const Color(0xFFE8EFED),
                                    child: const Icon(
                                      Icons.home_work_outlined,
                                      color: Color(0xFF7A9390),
                                      size: 44,
                                    ),
                                  )
                                : Stack(
                                    children: [
                                      PageView.builder(
                                        controller: _pageController,
                                        itemCount: imageUrls.length,
                                        onPageChanged: (index) {
                                          if (!mounted) return;
                                          setState(() {
                                            _currentImageIndex = index;
                                          });
                                        },
                                        itemBuilder: (context, index) {
                                          return Image.network(
                                            imageUrls[index],
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) => Container(
                                                  color: const Color(
                                                    0xFFE8EFED,
                                                  ),
                                                  child: const Icon(
                                                    Icons.broken_image_outlined,
                                                    color: Color(0xFF7A9390),
                                                    size: 44,
                                                  ),
                                                ),
                                          );
                                        },
                                      ),
                                      if (imageUrls.length > 1)
                                        Positioned(
                                          left: 0,
                                          right: 0,
                                          bottom: 10,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: List.generate(
                                              imageUrls.length,
                                              (index) => AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 200,
                                                ),
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 3,
                                                    ),
                                                width:
                                                    _currentImageIndex == index
                                                    ? 14
                                                    : 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color:
                                                      _currentImageIndex ==
                                                          index
                                                      ? Colors.white
                                                      : Colors.white.withValues(
                                                          alpha: 0.55,
                                                        ),
                                                  borderRadius:
                                                      BorderRadius.circular(99),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      if (imageUrls.length > 1)
                                        Positioned(
                                          top: 10,
                                          right: 10,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(
                                                alpha: 0.45,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '${_currentImageIndex + 1}/${imageUrls.length}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      // Owner-only delete overlay on main image
                                      if (_isOwner)
                                        Positioned(
                                          top: 10,
                                          left: 10,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              final current =
                                                  imageUrls[_currentImageIndex];
                                              _removeImageByUrl(current);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red
                                                  .withOpacity(0.9),
                                              minimumSize: const Size(36, 36),
                                              padding: EdgeInsets.zero,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.delete_outline,
                                              size: 18,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                          ),
                        ),
                        if (imageUrls.length > 1) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 64,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: imageUrls.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final isSelected = _currentImageIndex == index;
                                return GestureDetector(
                                  onTap: () {
                                    _pageController.animateToPage(
                                      index,
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      curve: Curves.easeOut,
                                    );
                                    if (!mounted) return;
                                    setState(() {
                                      _currentImageIndex = index;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: 78,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF0F766E)
                                            : const Color(0xFFDFECE9),
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(9),
                                      child: Image.network(
                                        imageUrls[index],
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  color: const Color(
                                                    0xFFE8EFED,
                                                  ),
                                                  child: const Icon(
                                                    Icons.broken_image_outlined,
                                                    color: Color(0xFF7A9390),
                                                    size: 18,
                                                  ),
                                                ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        _DetailCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF103033),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.place_outlined,
                                    size: 18,
                                    color: Color(0xFF5E7A7E),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      location,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF5E7A7E),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (propertyCoordinates != null) ...[
                                const SizedBox(height: 12),
                                PropertyLocationPreview(
                                  propertyCoordinates: propertyCoordinates,
                                  userCoordinates: _userCoordinates,
                                  locatingUser: _locatingUser,
                                  locationError: _locationError,
                                  onLocateUser: _locateCurrentUser,
                                ),
                                const SizedBox(height: 14),
                              ] else
                                const SizedBox(height: 14),
                              Text(
                                'Rs. ${price.toStringAsFixed(0)} / month',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isAvailable
                                      ? const Color(0xFFE5F7EE)
                                      : const Color(0xFFF8E8E8),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  isAvailable ? 'Available' : status,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isAvailable
                                        ? const Color(0xFF0F7A43)
                                        : const Color(0xFF9B2C2C),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Availability display (if provided by backend)
                              (() {
                                final rawAvail = property['availability'];
                                DateTime? aStart;
                                DateTime? aEnd;

                                dynamic availSource = rawAvail;
                                if (rawAvail is String &&
                                    rawAvail.trim().isNotEmpty) {
                                  try {
                                    availSource = jsonDecode(rawAvail);
                                  } catch (_) {
                                    availSource = rawAvail;
                                  }
                                }

                                if (availSource is List &&
                                    availSource.isNotEmpty) {
                                  final first = availSource.first;
                                  if (first is Map) {
                                    try {
                                      aStart = DateTime.parse(
                                        first['startDate'].toString(),
                                      );
                                    } catch (_) {}
                                    try {
                                      aEnd = DateTime.parse(
                                        first['endDate'].toString(),
                                      );
                                    } catch (_) {}
                                  }
                                }

                                if (aStart != null && aEnd != null) {
                                  final fmt = DateFormat('MMM d, y');
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Availability',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF103033),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF4F8F7),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          '${fmt.format(aStart)} — ${fmt.format(aEnd)}',
                                          style: const TextStyle(
                                            color: Color(0xFF5E7A7E),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                  );
                                }

                                return const SizedBox.shrink();
                              })(),

                              if (description.trim().isNotEmpty) ...[
                                const Text(
                                  'Description',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF103033),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  description,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF5E7A7E),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              _DetailField(
                                label: 'Property Type',
                                value: propertyType.isEmpty
                                    ? 'Not specified'
                                    : propertyType,
                              ),
                              const SizedBox(height: 8),
                              _DetailField(
                                label: 'Floor Number',
                                value: floorNumber.isEmpty
                                    ? 'Not specified'
                                    : floorNumber,
                              ),
                              const SizedBox(height: 8),
                              _DetailField(
                                label: 'Pet Policy',
                                value: petPolicy.isEmpty
                                    ? 'Not specified'
                                    : petPolicy,
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (bedrooms != null)
                                    _SpecChip('Bedrooms: $bedrooms'),
                                  if (bathrooms != null)
                                    _SpecChip('Bathrooms: $bathrooms'),
                                  if (area != null)
                                    _SpecChip('Area: $area sqft'),
                                  if (furnished is bool)
                                    _SpecChip(
                                      furnished
                                          ? 'Furnished: Yes'
                                          : 'Furnished: No',
                                    ),
                                ],
                              ),
                              if (amenities.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Text(
                                  'Amenities',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF103033),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: amenities
                                      .map((amenity) => _SpecChip(amenity))
                                      .toList(),
                                ),
                              ],
                              const SizedBox(height: 14),
                              Text(
                                'Property ID: ${widget.property.id}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF5E7A7E),
                                ),
                              ),
                              if (!_isOwner) ...[
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        (isAvailable &&
                                            !_bookingSubmitting &&
                                            !_bookingRequestSent)
                                        ? _showBookingOptions
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _bookingRequestSent
                                          ? Colors.green
                                          : const Color(0xFF2F9E9A),
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: const Color(
                                        0xFF2F9E9A,
                                      ).withValues(alpha: 0.75),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: _bookingSubmitting
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Icon(
                                            _bookingRequestSent
                                                ? Icons.check_circle_outline
                                                : Icons.bookmark_add_outlined,
                                          ),
                                    label: Text(
                                      _bookingRequestSent
                                          ? 'Request Sent'
                                          : (isAvailable
                                                ? 'Request Booking'
                                                : 'Not Available for Booking'),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                if (_ownerId != null &&
                                    _ownerId!.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: _openConversationWithOwner,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFF4F46E5,
                                        ),
                                        side: const BorderSide(
                                          color: Color(0xFF4F46E5),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.chat_bubble_outline,
                                      ),
                                      label: const Text(
                                        'Chat with Owner',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),

                        // Owner actions
                        if (_isOwner) ...[
                          const SizedBox(height: 12),
                          _DetailCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Owner Actions',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF103033),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton(
                                  onPressed: () async {
                                    // Open edit screen with current details
                                    final merged = <String, dynamic>{};
                                    if (_details != null) {
                                      merged.addAll(_details!);
                                    }
                                    // include top-level summary fields as fallback
                                    merged.putIfAbsent(
                                      'title',
                                      () => widget.property.title,
                                    );
                                    merged.putIfAbsent(
                                      'location',
                                      () => widget.property.location,
                                    );
                                    merged.putIfAbsent(
                                      'price',
                                      () => widget.property.price,
                                    );
                                    merged.putIfAbsent(
                                      'images',
                                      () => widget.property.images,
                                    );
                                    merged.putIfAbsent(
                                      'coordinates',
                                      () => property['coordinates'],
                                    );

                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => CreatePropertyScreen(
                                          property: merged,
                                          propertyId: widget.property.id,
                                        ),
                                      ),
                                    );

                                    // Refresh details after possible edit
                                    await _loadDetails();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF2F9E9A),
                                    side: const BorderSide(
                                      color: Color(0xFF2F9E9A),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 16,
                                    ),
                                  ),
                                  child: const Text('Edit This Property'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final Widget child;

  const _DetailCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: child,
    );
  }
}

class _SpecChip extends StatelessWidget {
  final String label;

  const _SpecChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0F766E),
        ),
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  final String label;
  final String value;

  const _DetailField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF103033),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: Color(0xFF5E7A7E)),
          ),
        ),
      ],
    );
  }
}
