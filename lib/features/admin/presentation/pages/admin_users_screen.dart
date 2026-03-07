import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/core/error/failures.dart';
import '../providers/admin_providers.dart';

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminUsersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: async.when(
        data: (either) => either.fold(
          (failure) => _buildError(context, failure),
          (state) => _buildList(context, ref, state),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(e.toString())),
      ),
    );
  }

  Widget _buildError(BuildContext context, Failure failure) {
    return Center(child: Text(failure.message));
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    AdminUsersState state,
  ) {
    if (state.users.isEmpty) return const Center(child: Text('No users found'));
    return RefreshIndicator(
      onRefresh: () => ref.read(adminUsersProvider.notifier).refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: state.users.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index == state.users.length) {
            if (state.users.length >= state.total)
              return const SizedBox.shrink();
            return TextButton(
              onPressed: () async {
                final next = state.page + 1;
                await ref
                    .read(adminUsersProvider.notifier)
                    .fetch(page: next, append: true);
              },
              child: const Text('Load more'),
            );
          }
          final item = state.users[index] as Map<String, dynamic>;
          final id = item['id']?.toString() ?? item['_id']?.toString() ?? '';
          final name = item['name'] ?? item['fullName'] ?? 'Unnamed';
          final email = item['email'] ?? '';
          return Card(
            child: ListTile(
              title: Text(name.toString()),
              subtitle: Text(email.toString()),
              trailing: PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'delete') {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Delete user'),
                        content: const Text(
                          'Are you sure you want to delete this user?',
                        ),
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
                    if (ok == true)
                      await ref
                          .read(adminUsersProvider.notifier)
                          .deleteUser(id);
                  } else if (v == 'promote') {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Promote user'),
                        content: const Text('Promote this user to admin?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text('Promote'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true)
                      await ref
                          .read(adminUsersProvider.notifier)
                          .promoteUser(id);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'promote', child: Text('Promote')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
              leading: CircleAvatar(
                child: Text(
                  (name.toString().isNotEmpty ? name.toString()[0] : '?'),
                ),
              ),
              subtitleTextStyle: const TextStyle(fontSize: 12),
            ),
          );
        },
      ),
    );
  }
}
