import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase project `easy-flashcards-quiz`. These are client identifiers, not
/// secrets; access is enforced by `firestore.rules` and Firebase Auth.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform =>
      defaultTargetPlatform == TargetPlatform.iOS ? ios : android;

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyA_VAoivFD9q_pvz_QLBtvWoFJ-8LWGHT8',
    appId: '1:44748130303:android:64e4f6b19f334bd98c49ca',
    messagingSenderId: '44748130303',
    projectId: 'easy-flashcards-quiz',
    storageBucket: 'easy-flashcards-quiz.firebasestorage.app',
  );

  static const ios = FirebaseOptions(
    apiKey: 'AIzaSyCPb_J8jKp8lYEcSKnHBGc5ygBFCjWkhXU',
    appId: '1:44748130303:ios:6a8029b25d38936e8c49ca',
    messagingSenderId: '44748130303',
    projectId: 'easy-flashcards-quiz',
    storageBucket: 'easy-flashcards-quiz.firebasestorage.app',
    iosBundleId: 'com.subnext.basicflashcards',
  );
}
