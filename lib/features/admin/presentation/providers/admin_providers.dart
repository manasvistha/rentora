import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartz/dartz.dart';
import 'package:rentora/core/error/failures.dart';
import '../../domain/entities/admin_overview_entity.dart';
import '../../domain/usecases/get_admin_overview_usecase.dart';
import '../../domain/usecases/get_admin_users_usecase.dart';
import '../../domain/usecases/delete_user_usecase.dart';
import '../../domain/usecases/promote_user_usecase.dart';
import '../../domain/usecases/get_admin_properties_usecase.dart';
import '../../domain/usecases/update_admin_property_status_usecase.dart';
import '../../domain/usecases/delete_admin_property_usecase.dart';

class AdminUsersState {
  final List<dynamic> users;
  final int page;
  final int total;
  const AdminUsersState({this.users = const [], this.page = 1, this.total = 0});
}

class AdminUsersNotifier
    extends Notifier<AsyncValue<Either<Failure, AdminUsersState>>> {
  @override
  AsyncValue<Either<Failure, AdminUsersState>> build() {
    // initial state
    fetch();
    return const AsyncValue.loading();
  }

  Future<void> fetch({
    int page = 1,
    int limit = 20,
    bool append = false,
  }) async {
    state = const AsyncValue.loading();
    final usecase = ref.read(getAdminUsersUseCaseProvider);
    final res = await usecase.execute(page: page, limit: limit);
    res.fold(
      (failure) {
        state = AsyncValue.data(left(failure));
      },
      (data) {
        final items = (data['data'] as List?) ?? (data['users'] as List?) ?? [];
        final total = (data['total'] as int?) ?? items.length;
        List<dynamic> previous = [];
        final prev = state.asData?.value;
        if (prev != null) prev.fold((l) => null, (s) => previous = s.users);
        final current = append ? [...previous, ...items] : items;
        state = AsyncValue.data(
          right(AdminUsersState(users: current, page: page, total: total)),
        );
      },
    );
  }

  Future<void> refresh() async => fetch(page: 1, append: false);

  Future<void> deleteUser(String id) async {
    final usecase = ref.read(deleteUserUseCaseProvider);
    final res = await usecase.execute(id);
    res.fold((l) => null, (_) => fetch(page: 1));
  }

  Future<void> promoteUser(String id) async {
    final usecase = ref.read(promoteUserUseCaseProvider);
    final res = await usecase.execute(id);
    res.fold((l) => null, (_) => fetch(page: 1));
  }
}

final adminUsersProvider =
    NotifierProvider<
      AdminUsersNotifier,
      AsyncValue<Either<Failure, AdminUsersState>>
    >(AdminUsersNotifier.new);

class AdminPropertiesNotifier
    extends Notifier<AsyncValue<Either<Failure, List<dynamic>>>> {
  @override
  AsyncValue<Either<Failure, List<dynamic>>> build() {
    fetch();
    return const AsyncValue.loading();
  }

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    final usecase = ref.read(getAdminPropertiesUseCaseProvider);
    final res = await usecase.execute();
    state = AsyncValue.data(res);
  }

  Future<void> updateStatus(String id, String status) async {
    final usecase = ref.read(updateAdminPropertyStatusUseCaseProvider);
    final res = await usecase.execute(id, status);
    await res.fold((l) async => null, (_) async => fetch());
  }

  Future<void> deleteProperty(String id) async {
    final usecase = ref.read(deleteAdminPropertyUseCaseProvider);
    final res = await usecase.execute(id);
    await res.fold((l) async => null, (_) async => fetch());
  }
}

final adminPropertiesProvider =
    NotifierProvider<
      AdminPropertiesNotifier,
      AsyncValue<Either<Failure, List<dynamic>>>
    >(AdminPropertiesNotifier.new);

final adminOverviewProvider =
    FutureProvider.autoDispose<Either<Failure, AdminOverviewEntity>>((
      ref,
    ) async {
      final usecase = ref.read(getAdminOverviewUseCaseProvider);
      return usecase.execute();
    });
