import 'package:cloud_firestore/cloud_firestore.dart';

import 'sync_service.dart';

/// The only file in the app that touches the Firestore SDK.
///
/// Keeping it this small is what lets `FirestoreSyncService` be unit-tested
/// against an in-memory [SyncBackend].
class FirestoreBackend implements SyncBackend {
  FirestoreBackend(this._db);

  final FirebaseFirestore _db;

  /// Every user's rows live under their own uid. `firestore.rules` enforces
  /// the same boundary server-side, so a client cannot query another path.
  static String collectionPath(String uid, String collection) =>
      'users/$uid/$collection';

  @override
  Future<void> put(
    String uid,
    String collection,
    String id,
    Map<String, dynamic> data,
  ) {
    return _db
        .collection(collectionPath(uid, collection))
        .doc(id)
        .set(data);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAll(
    String uid,
    String collection,
  ) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _db.collection(collectionPath(uid, collection)).get();

    return <Map<String, dynamic>>[
      // The document id is authoritative — it is the uuid we minted, so a doc
      // that somehow lost its embedded `id` field still restores correctly.
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in snapshot.docs)
        <String, dynamic>{...doc.data(), 'id': doc.id},
    ];
  }
}
