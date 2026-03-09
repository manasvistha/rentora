import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/api/api_client.dart';
import 'package:rentora/core/api/api_endpoints.dart';

class MyFavoriteScreen extends ConsumerStatefulWidget {
  const MyFavoriteScreen({super.key});

  @override
  ConsumerState<MyFavoriteScreen> createState() => _MyFavoriteScreenState();
}

class _MyFavoriteScreenState extends ConsumerState<MyFavoriteScreen> {
  bool _loading = true;
  String? _error;
  List<_FavoriteItem> _favorites = const [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final client = ref.read(apiClientProvider);
    try {
      final response = await client.get(ApiEndpoints.favorites);
      final rawList = _extractList(response.data);
      final mapped = rawList
          .map(_FavoriteItem.fromJson)
          .whereType<_FavoriteItem>()
          .toList();
      setState(() {
        _favorites = mapped;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load favorites. Pull to retry.';
        _loading = false;
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

  Future<void> _removeFavorite(String propertyId) async {
    final client = ref.read(apiClientProvider);
    try {
      await client.delete(ApiEndpoints.favoriteByProperty(propertyId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Removed from favorites.'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(16, 0, 16, 96),
        ),
      );
      await _loadFavorites();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to remove favorite: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadFavorites,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            const Text(
              'My Favorites',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Saved homes you like, just like on the web dashboard.',
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              _ErrorCard(message: _error!, onRetry: _loadFavorites),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
            else if (_favorites.isEmpty)
              const _EmptyCard(
                message:
                    'No favorites yet. Tap the heart on a property to save it.',
              )
            else ...[
              ..._favorites.map(
                (fav) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _FavoriteCard(
                    item: fav,
                    onRemove: () => _removeFavorite(fav.propertyId),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FavoriteItem {
  /// The property's _id – used for the DELETE /api/favorite/:propertyId call.
  final String propertyId;
  final String title;
  final String location;
  final double price;
  final List<String> images;

  const _FavoriteItem({
    required this.propertyId,
    required this.title,
    required this.location,
    required this.price,
    required this.images,
  });

  // Keep a compatibility getter so existing code referencing .id still works.
  String get id => propertyId;

  static _FavoriteItem? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final map = raw.cast<String, dynamic>();

    final dynamic property = map['property'];

    // property is populated as an object by the backend (.populate('property'))
    if (property is Map) {
      final source = property.cast<String, dynamic>();
      final propId = (source['_id'] ?? source['id'] ?? '').toString();
      if (propId.isEmpty) return null;

      final imagesRaw = source['images'];
      final imageList = imagesRaw is List
          ? imagesRaw.map((e) => e.toString()).toList()
          : <String>[];

      return _FavoriteItem(
        propertyId: propId,
        title: (source['title'] ?? 'Untitled Property').toString(),
        location: (source['location'] ?? 'Unknown location').toString(),
        price: _asDouble(source['price']),
        images: imageList,
      );
    }

    // property is just a string ObjectId (not populated)
    if (property is String && property.isNotEmpty) {
      return _FavoriteItem(
        propertyId: property,
        title: (map['title'] ?? 'Untitled Property').toString(),
        location: (map['location'] ?? 'Unknown location').toString(),
        price: _asDouble(map['price']),
        images: const [],
      );
    }

    // property is null (deleted property) – skip this item
    return null;
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

class _FavoriteCard extends StatelessWidget {
  final _FavoriteItem item;
  final VoidCallback onRemove;

  const _FavoriteCard({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
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
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF103033),
                    ),
                  ),
                  const SizedBox(height: 6),
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
                  const SizedBox(height: 10),
                  Text(
                    'Rs. ${item.price.toStringAsFixed(0)} / month',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF7F4),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.favorite,
                              color: Color(0xFFD74C4C),
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Saved',
                              style: TextStyle(
                                color: Color(0xFF0F766E),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: onRemove,
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Color(0xFFD74C4C),
                        ),
                        label: const Text(
                          'Remove',
                          style: TextStyle(color: Color(0xFFD74C4C)),
                        ),
                      ),
                    ],
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
