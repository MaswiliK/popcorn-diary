import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Turns a caught error from a TMDB call into a message a person can
/// actually act on. Calling out "no internet" specifically matters here
/// because it's by far the most common failure mode for this app (TMDB
/// requires a live connection; the rest of the diary works offline) and
/// a generic "something went wrong" leaves the user guessing whether
/// it's their connection, a bad token, or a bug.
String friendlyMetadataErrorMessage(Object error) {
  if (_looksLikeConnectivityFailure(error)) {
    return 'No internet connection. Connect to the internet to search '
        'or fetch movie details from TMDB.';
  }
  if (error is TimeoutException) {
    return 'The request to TMDB timed out. Check your connection and try again.';
  }
  return 'Could not reach TMDB. Please try again.';
}

bool _looksLikeConnectivityFailure(Object error) {
  if (error is SocketException) return true;
  if (error is http.ClientException) {
    return _matchesConnectivityText(error.message);
  }
  return _matchesConnectivityText(error.toString());
}

bool _matchesConnectivityText(String text) {
  final lower = text.toLowerCase();
  return lower.contains('socketexception') ||
      lower.contains('failed host lookup') ||
      lower.contains('network is unreachable') ||
      lower.contains('no address associated with hostname') ||
      lower.contains('connection failed') ||
      lower.contains('connection refused') ||
      lower.contains('software caused connection abort');
}
