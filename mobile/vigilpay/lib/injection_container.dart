import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'core/network/api_client.dart';
import 'core/network/auth_session_manager.dart';
import 'core/network/token_storage.dart';
import 'features/auth/data/datasources/auth_gateway.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/load_session_usecase.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/domain/usecases/register_usecase.dart';
import 'features/auth/presentation/provider/auth_controller.dart';
import 'features/products/data/datasources/products_gateway.dart';
import 'features/products/data/repositories/products_repository_impl.dart';
import 'features/products/domain/repositories/products_repository.dart';
import 'features/products/domain/usecases/fetch_products_usecase.dart';
import 'features/products/presentation/provider/products_controller.dart';
import 'features/support/presentation/provider/support_controller.dart';

class InjectionContainer {
  static List<SingleChildWidget> get providers {
    return <SingleChildWidget>[
      Provider<TokenStorage>(
        create: (_) => TokenStorage(),
      ),
      Provider<AuthSessionManager>(
        create: (context) => AuthSessionManager(tokenStorage: context.read<TokenStorage>()),
      ),
      Provider<ApiClient>(
        create: (context) => ApiClient(sessionManager: context.read<AuthSessionManager>()),
      ),
      Provider<AuthGateway>(
        create: (context) => AuthGateway(
          apiClient: context.read<ApiClient>(),
          sessionManager: context.read<AuthSessionManager>(),
        ),
      ),
      Provider<ProductsGateway>(
        create: (context) => ProductsGateway(apiClient: context.read<ApiClient>()),
      ),
      Provider<AuthRepository>(
        create: (context) => AuthRepositoryImpl(gateway: context.read<AuthGateway>()),
      ),
      Provider<ProductsRepository>(
        create: (context) => ProductsRepositoryImpl(gateway: context.read<ProductsGateway>()),
      ),
      Provider<LoginUseCase>(
        create: (context) => LoginUseCase(context.read<AuthRepository>()),
      ),
      Provider<LoadSessionUseCase>(
        create: (context) => LoadSessionUseCase(context.read<AuthRepository>()),
      ),
      Provider<LogoutUseCase>(
        create: (context) => LogoutUseCase(context.read<AuthRepository>()),
      ),
      Provider<RegisterUseCase>(
        create: (context) => RegisterUseCase(context.read<AuthRepository>()),
      ),
      Provider<FetchProductsUseCase>(
        create: (context) => FetchProductsUseCase(context.read<ProductsRepository>()),
      ),
      ChangeNotifierProvider<AuthController>(
        create: (context) => AuthController(
          loginUseCase: context.read<LoginUseCase>(),
          loadSessionUseCase: context.read<LoadSessionUseCase>(),
          logoutUseCase: context.read<LogoutUseCase>(),
          registerUseCase: context.read<RegisterUseCase>(),
        ),
      ),
      ChangeNotifierProvider<ProductsController>(
        create: (context) => ProductsController(
          fetchProductsUseCase: context.read<FetchProductsUseCase>(),
        ),
      ),
      ChangeNotifierProvider<SupportController>(
        create: (context) => SupportController(
          apiClient: context.read<ApiClient>(),
        ),
      ),
    ];
  }
}
