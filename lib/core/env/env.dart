import 'package:envied/envied.dart';

part 'env.g.dart';

/// Application environment configuration.
///
/// Prefers explicit `--dart-define` / `--dart-define-from-file=config/<env>.json` values at
/// build/run time, falling back cleanly to `.env` values compiled via `envied`.
@Envied(path: '.env')
abstract final class Env {
  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'prod',
  );

  static const bool useEmulator = bool.fromEnvironment(
    'USE_EMULATOR',
    defaultValue: false,
  );

  static const String _localSupabaseUrl = 'http://127.0.0.1:54321';
  static const String _localSupabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';

  @EnviedField(varName: 'SUPABASE_URL')
  static const String _enviedSupabaseUrl = _Env._enviedSupabaseUrl;

  @EnviedField(varName: 'SUPABASE_PUBLISHABLE_KEY')
  static const String _enviedSupabasePublishableKey =
      _Env._enviedSupabasePublishableKey;

  @EnviedField(varName: 'GOOGLE_WEB_CLIENT_ID')
  static const String _enviedGoogleWebClientId = _Env._enviedGoogleWebClientId;

  @EnviedField(varName: 'GOOGLE_IOS_CLIENT_ID')
  static const String _enviedGoogleIosClientId = _Env._enviedGoogleIosClientId;

  static const String _definedSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _definedSupabaseKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const String _definedGoogleWebClientId =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  static const String _definedGoogleIosClientId =
      String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

  static String get supabaseUrl {
    if (useEmulator || appEnv == 'local') {
      return _definedSupabaseUrl.isNotEmpty
          ? _definedSupabaseUrl
          : _localSupabaseUrl;
    }
    return _definedSupabaseUrl.isNotEmpty
        ? _definedSupabaseUrl
        : _enviedSupabaseUrl;
  }

  static String get supabasePublishableKey {
    if (useEmulator || appEnv == 'local') {
      return _definedSupabaseKey.isNotEmpty
          ? _definedSupabaseKey
          : _localSupabaseAnonKey;
    }
    return _definedSupabaseKey.isNotEmpty
        ? _definedSupabaseKey
        : _enviedSupabasePublishableKey;
  }

  static String get googleWebClientId =>
      _definedGoogleWebClientId.isNotEmpty
          ? _definedGoogleWebClientId
          : _enviedGoogleWebClientId;

  static String get googleIosClientId =>
      _definedGoogleIosClientId.isNotEmpty
          ? _definedGoogleIosClientId
          : _enviedGoogleIosClientId;

  /// Prevents the `staging` app flavor from accidentally connecting to production Supabase.
  static void assertFlavorSafe({
    required String? flavor,
    String? effectiveEnv,
    bool? emulatorOverride,
    String? resolvedUrl,
  }) {
    final env = effectiveEnv ?? appEnv;
    final isEmulator = emulatorOverride ?? useEmulator;
    final url = resolvedUrl ?? supabaseUrl;

    if (flavor == 'staging' &&
        !isEmulator &&
        env == 'prod' &&
        !url.contains('127.0.0.1') &&
        !url.contains('localhost')) {
      throw StateError(
        'Flavor safety guard: Postfolio Staging cannot connect to production Supabase. '
        'Pass --dart-define=APP_ENV=local (or --dart-define-from-file=config/staging.json).',
      );
    }
  }
}
