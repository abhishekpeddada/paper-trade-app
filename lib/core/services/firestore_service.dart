import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  FirebaseFirestore? get _db {
    if (defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.windows) {
      return null;
    }
    return FirebaseFirestore.instance;
  }
  
  FirebaseAuth? get _auth {
    if (defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.windows) {
      return null;
    }
    return FirebaseAuth.instance;
  }

  String? get _uid => _auth?.currentUser?.uid;

  // --- Portfolio Data ---

  Future<void> savePortfolioData({
    required double balance,
    required List<String> positions,
    required List<String> orders,
  }) async {
    if (_uid == null || _db == null) return;
    
    await _db!.collection('users').doc(_uid).collection('portfolio').doc('data').set({
      'balance': balance,
      'positions': positions,
      'orders': orders,
      'last_updated': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>?> loadPortfolioData() async {
    if (_uid == null || _db == null) return null;

    final doc = await _db!.collection('users').doc(_uid).collection('portfolio').doc('data').get();
    return doc.data();
  }

  // --- Watchlist Data ---

  Future<void> saveWatchlist(List<String> symbols) async {
    if (_uid == null || _db == null) return;

    await _db!.collection('users').doc(_uid).collection('watchlist').doc('data').set({
      'symbols': symbols,
      'last_updated': FieldValue.serverTimestamp(),
    });
  }

  Future<List<String>> loadWatchlist() async {
    if (_uid == null || _db == null) return [];

    final doc = await _db!.collection('users').doc(_uid).collection('watchlist').doc('data').get();
    if (doc.exists && doc.data() != null) {
      return List<String>.from(doc.data()!['symbols'] ?? []);
    }
    return [];
  }

  // --- Auto Trading Logs ---

  Future<void> saveAutoTradingLogs(List<String> logs) async {
    if (_uid == null || _db == null) return;

    // Firestore has a 1MB limit per document, so we might need to be careful with huge logs.
    // For now, we'll assume 200 lines is fine.
    await _db!.collection('users').doc(_uid).collection('settings').doc('auto_trading').set({
      'logs': logs,
      'last_updated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<String>> loadAutoTradingLogs() async {
    if (_uid == null || _db == null) return [];

    final doc = await _db!.collection('users').doc(_uid).collection('settings').doc('auto_trading').get();
    if (doc.exists && doc.data() != null) {
      return List<String>.from(doc.data()!['logs'] ?? []);
    }
    return [];
  }
  
  Future<void> saveLastScanDate(String date) async {
    if (_uid == null || _db == null) return;
    
    await _db!.collection('users').doc(_uid).collection('settings').doc('auto_trading').set({
      'last_scan_date': date,
    }, SetOptions(merge: true));
  }
  
  Future<String?> loadLastScanDate() async {
    if (_uid == null || _db == null) return null;
    
    final doc = await _db!.collection('users').doc(_uid).collection('settings').doc('auto_trading').get();
    if (doc.exists && doc.data() != null) {
      return doc.data()!['last_scan_date'] as String?;
    }
    return null;
  }
}
