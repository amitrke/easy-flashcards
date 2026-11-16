import 'dart:async';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../models/study_set.dart';
import 'account_service.dart';

/// Firebase Auth (Google, Apple) and Firestore under `users/{uid}/sets/{id}`.
class FirebaseAccountService implements AccountService {
  FirebaseAccountService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  bool _googleReady = false;

  AccountUser? _map(User? u) => u == null
      ? null
      : AccountUser(uid: u.uid, email: u.email, displayName: u.displayName);

  @override
  AccountUser? get currentUser => _map(_auth.currentUser);

  @override
  Stream<AccountUser?> get userChanges => _auth.authStateChanges().map(_map);

  @override
  bool get appleAvailable => Platform.isIOS;

  CollectionReference<Map<String, dynamic>> _sets() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Not signed in');
    return _db.collection('users').doc(uid).collection('sets');
  }

  @override
  Future<void> signIn(SignInMethod method) async {
    switch (method) {
      case SignInMethod.google:
        final google = GoogleSignIn.instance;
        if (!_googleReady) {
          await google.initialize();
          _googleReady = true;
        }
        final account = await google.authenticate();
        final idToken = account.authentication.idToken;
        await _auth.signInWithCredential(
          GoogleAuthProvider.credential(idToken: idToken),
        );
      case SignInMethod.apple:
        final apple = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );
        await _auth.signInWithCredential(
          OAuthProvider('apple.com').credential(
            idToken: apple.identityToken,
            accessToken: apple.authorizationCode,
          ),
        );
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final docs = await _sets().get();
    for (final d in docs.docs) {
      await d.reference.delete();
    }
    await user.delete();
  }

  @override
  Future<List<StudySet>> fetchSets() async {
    final snap = await _sets().get();
    return snap.docs.map((d) => StudySet.fromJson(d.data())).toList();
  }

  @override
  Future<void> putSet(StudySet set) => _sets().doc(set.id).set(set.toJson());

  @override
  Future<void> removeSet(String id) => _sets().doc(id).delete();
}
