/// Runtime configuration supplied via `--dart-define` at build/run time,
/// never hardcoded into source control.
///
/// Usage:
///   flutter run --dart-define=TMDB_API_TOKEN=your_token_here
///
/// Get a free TMDB API read access token at:
///   https://www.themoviedb.org/settings/api
class AppConfig {
  AppConfig._();

  static const String tmdbApiToken =
      String.fromEnvironment('TMDB_API_TOKEN', defaultValue: '');

  static bool get hasTmdbToken => tmdbApiToken.isNotEmpty;
}
