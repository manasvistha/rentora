// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:rentora/core/services/hive/hive_service.dart' as _i203;
import 'package:rentora/features/auth/data/datasources/auth_local_datasource.dart'
    as _i317;
import 'package:rentora/features/auth/data/repositories/auth_repository_impl.dart'
    as _i804;
import 'package:rentora/features/auth/domain/repositories/auth_repository.dart'
    as _i491;
import 'package:rentora/features/auth/domain/usecases/get_current_user_usecase.dart'
    as _i1054;
import 'package:rentora/features/auth/domain/usecases/login_usecase.dart'
    as _i323;
import 'package:rentora/features/auth/domain/usecases/logout_usecase.dart'
    as _i745;
import 'package:rentora/features/auth/domain/usecases/signup_usecase.dart'
    as _i270;
import 'package:rentora/features/auth/presentation/view_model/auth_view_model.dart'
    as _i773;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    gh.singleton<_i203.HiveService>(() => _i203.HiveService());
    gh.factory<_i317.AuthLocalDataSource>(
        () => _i317.AuthLocalDataSourceImpl(gh<_i203.HiveService>()));
    gh.factory<_i491.AuthRepository>(() => _i804.AuthRepositoryImpl(
          gh<_i317.AuthLocalDataSource>(),
          gh<_i203.HiveService>(),
        ));
    gh.factory<_i1054.GetCurrentUserUseCase>(
        () => _i1054.GetCurrentUserUseCase(gh<_i491.AuthRepository>()));
    gh.factory<_i323.LoginUseCase>(
        () => _i323.LoginUseCase(gh<_i491.AuthRepository>()));
    gh.factory<_i745.LogoutUseCase>(
        () => _i745.LogoutUseCase(gh<_i491.AuthRepository>()));
    gh.factory<_i270.SignupUseCase>(
        () => _i270.SignupUseCase(gh<_i491.AuthRepository>()));
    gh.factory<_i773.AuthViewModel>(() => _i773.AuthViewModel(
          loginUseCase: gh<_i323.LoginUseCase>(),
          signupUseCase: gh<_i270.SignupUseCase>(),
          logoutUseCase: gh<_i745.LogoutUseCase>(),
          getCurrentUserUseCase: gh<_i1054.GetCurrentUserUseCase>(),
        ));
    return this;
  }
}
