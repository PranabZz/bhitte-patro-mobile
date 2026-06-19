import 'package:bhitte_patro/core/utils/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _logger = AppLogger();

  /// The Google account that was used to sign in.
  /// Cached here so that [getAuthenticatedClient] can reuse the exact same
  /// account without triggering the Android account-picker dialog again.
  GoogleSignInAccount? _cachedGoogleAccount;

  Future<void> initialize() async {
    _logger.d("AuthService: Initializing GoogleSignIn...");
    await GoogleSignIn.instance.initialize();
  }

  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      _logger.d("AuthService: Starting Google Sign-In...");
      // 1. Authenticate with Google – the user picks their account here once.
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();
      if (googleUser == null) {
        _logger.w("AuthService: Google Sign-In cancelled by user.");
        return null;
      }

      // Cache the account so subsequent calendar fetches never need to re-prompt.
      _cachedGoogleAccount = googleUser;

      _logger.d("AuthService: Requesting Calendar scopes...");
      // 2. Request authorization for Calendar scope
      final authorization = await googleUser.authorizationClient.authorizeScopes([
        calendar.CalendarApi.calendarScope,
      ]);

      _logger.d("AuthService: Authenticating with Firebase...");
      // 3. Authenticate with Firebase using idToken
      // In 7.x, .authentication is a property, not a Future.
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: authorization.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      _logger.e("AuthService: Error during Google Sign-In: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    _logger.d("AuthService: Signing out...");
    _cachedGoogleAccount = null;
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }

  Future<http.Client?> getAuthenticatedClient() async {
    _logger.d("AuthService: Getting authenticated client...");
    try {
      // Prefer the cached account from the original sign-in so we never
      // trigger the Android account-picker on devices with multiple Google
      // accounts.  Only fall back to attemptLightweightAuthentication() when
      // the app was restarted and the cache was lost.
      GoogleSignInAccount? googleUser = _cachedGoogleAccount;

      if (googleUser == null) {
        _logger.d("AuthService: No cached account – trying lightweight auth...");
        googleUser = await GoogleSignIn.instance.attemptLightweightAuthentication();
      }

      if (googleUser == null) {
        _logger.w("AuthService: No Google user found – user must sign in again.");
        return null;
      }

      // Re-cache whatever account we resolved, so future calls are instant.
      _cachedGoogleAccount = googleUser;
      _logger.i("AuthService: Using Google account: ${googleUser.email}");

      _logger.d("AuthService: Authorizing scopes...");
      // authorizeScopes() is safe to call on the cached account – it checks
      // whether the scopes are already granted and returns immediately without
      // showing any UI when they are.
      final authorization = await googleUser.authorizationClient.authorizeScopes([
        calendar.CalendarApi.calendarScope,
      ]);
      _logger.i("AuthService: Scopes authorized.");

      final credentials = auth.AccessCredentials(
        auth.AccessToken(
          'Bearer',
          authorization.accessToken,
          DateTime.now().toUtc().add(const Duration(hours: 1)),
        ),
        null,
        [calendar.CalendarApi.calendarScope],
      );

      return auth.authenticatedClient(http.Client(), credentials);
    } catch (e) {
      _logger.e("AuthService: Error during authenticated client retrieval: $e");
      return null;
    }
  }
}
