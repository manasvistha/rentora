import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rentora/features/dashboard/domain/entities/dashboard_booking_entity.dart';
import 'package:rentora/features/dashboard/domain/entities/dashboard_property_entity.dart';
import 'package:rentora/features/dashboard/domain/usecases/get_all_properties_usecase.dart';
import 'package:rentora/features/dashboard/domain/usecases/get_booking_requests_usecase.dart';
import 'package:rentora/features/dashboard/domain/usecases/get_my_bookings_usecase.dart';
import 'package:rentora/features/dashboard/domain/usecases/get_my_properties_usecase.dart';

final allPropertiesProvider = FutureProvider.autoDispose
    .family<List<DashboardPropertyEntity>, bool>((ref, forceRefresh) async {
      final useCase = ref.read(getAllPropertiesUseCaseProvider);
      final result = await useCase.execute(forceRefresh: forceRefresh);
      return result.fold(
        (failure) => throw Exception(failure.message),
        (items) => items,
      );
    });

final myPropertiesProvider = FutureProvider.autoDispose
    .family<List<DashboardPropertyEntity>, bool>((ref, forceRefresh) async {
      final useCase = ref.read(getMyPropertiesUseCaseProvider);
      final result = await useCase.execute(forceRefresh: forceRefresh);
      return result.fold(
        (failure) => throw Exception(failure.message),
        (items) => items,
      );
    });

final myBookingsProvider = FutureProvider.autoDispose
    .family<List<DashboardBookingEntity>, bool>((ref, forceRefresh) async {
      final useCase = ref.read(getMyBookingsUseCaseProvider);
      final result = await useCase.execute(forceRefresh: forceRefresh);
      return result.fold(
        (failure) => throw Exception(failure.message),
        (items) => items,
      );
    });

final bookingRequestsProvider = FutureProvider.autoDispose
    .family<List<DashboardBookingEntity>, bool>((ref, forceRefresh) async {
      final useCase = ref.read(getBookingRequestsUseCaseProvider);
      final result = await useCase.execute(forceRefresh: forceRefresh);
      return result.fold(
        (failure) => throw Exception(failure.message),
        (items) => items,
      );
    });
