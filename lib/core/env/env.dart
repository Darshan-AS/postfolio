import 'package:envied/envied.dart';

part 'env.g.dart';

// Trigger build
@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'SUPABASE_URL')
  static const String supabaseUrl = _Env.supabaseUrl;

  @EnviedField(varName: 'SUPABASE_ANON_KEY')
  static const String supabaseAnonKey = _Env.supabaseAnonKey;

  @EnviedField(varName: 'USE_SUPABASE', defaultValue: false)
  static const bool useSupabase = _Env.useSupabase;

  @EnviedField(varName: 'GOOGLE_WEB_CLIENT_ID')
  static const String googleWebClientId = _Env.googleWebClientId;

  @EnviedField(varName: 'GOOGLE_IOS_CLIENT_ID')
  static const String googleIosClientId = _Env.googleIosClientId;
}
