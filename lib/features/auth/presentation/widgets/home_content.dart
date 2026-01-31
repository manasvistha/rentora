import 'package:flutter/material.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final properties = [
      const _PropertyItem(
        title: '1 Big Hall at Lalitpur',
        location: 'Mahalaxmi, Lalitpur',
        price: 'Rs. 8000 /per month',
        distance: '1.2 km from Gwarko',
        isAvailable: true,
      ),
      const _PropertyItem(
        title: '2BHK Flat',
        location: 'Mahalaxmi, Lalitpur',
        price: 'Rs. 8000 /per month',
        distance: '1.2 km from Gwarko',
        isAvailable: true,
      ),
      const _PropertyItem(
        title: 'A Flat at Ekantakuna',
        location: 'Ekantakuna, Lalitpur',
        price: 'Rs. 25000 /per month',
        distance: '1.2 km from Gwarko',
        isAvailable: false,
      ),
      const _PropertyItem(
        title: '1 Room at Satdobato',
        location: 'Satdobato, Lalitpur',
        price: 'Rs. 6000 /per month',
        distance: '2.5 km from Gwarko',
        isAvailable: true,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Recently Added Properties',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...properties.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PropertyCard(item: item),
          ),
        ),
      ],
    );
  }
}

class _PropertyItem {
  final String title;
  final String location;
  final String price;
  final String distance;
  final bool isAvailable;

  const _PropertyItem({
    required this.title,
    required this.location,
    required this.price,
    required this.distance,
    required this.isAvailable,
  });
}

class _PropertyCard extends StatelessWidget {
  final _PropertyItem item;

  const _PropertyCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final statusColor = item.isAvailable ? Colors.green : Colors.red;
    final statusText = item.isAvailable ? 'Available' : 'Booked';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 72,
              height: 72,
              color: const Color(0xFFE8E8E8),
              child: const Icon(Icons.bed, color: Colors.black54),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.location,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 6),
                Text(
                  item.price,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.place, size: 14, color: Colors.black38),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.distance,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black45,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(Icons.circle, size: 8, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    statusText,
                    style: const TextStyle(fontSize: 10, color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
