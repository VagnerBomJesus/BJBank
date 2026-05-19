// ============================================================================
// firestore_compat.dart — Shim para remover dependencia de cloud_firestore.
// ============================================================================
//
// A app migrou de Firebase/Firestore para Supabase. Em vez de reescrever
// 19 ficheiros que importam `cloud_firestore` (models + services + screens),
// este shim fornece classes minimais que satisfazem os usos existentes sem
// dependencia externa.
//
// Os services Supabase NOVOS (Supabase*) leem/escrevem via Postgrest
// directamente. Os services FIRESTORE legacy continuam a compilar e
// devolvem listas vazias / no-ops em runtime.
// ============================================================================

import 'package:flutter/foundation.dart';

// ============================================================================
// Tipos basicos
// ============================================================================

class Timestamp {
  final DateTime _date;
  const Timestamp._(this._date);

  factory Timestamp.fromDate(DateTime d) => Timestamp._(d);
  factory Timestamp.now() => Timestamp._(DateTime.now());
  factory Timestamp.fromMillisecondsSinceEpoch(int ms) =>
      Timestamp._(DateTime.fromMillisecondsSinceEpoch(ms));

  DateTime toDate() => _date;
  int get millisecondsSinceEpoch => _date.millisecondsSinceEpoch;

  @override
  String toString() => _date.toIso8601String();
}

class FieldValue {
  final String _kind;
  final num? _amount;
  const FieldValue._(this._kind, [this._amount]);

  static FieldValue serverTimestamp() => const FieldValue._('serverTimestamp');
  static FieldValue increment(num n) => FieldValue._('increment', n);
  static FieldValue arrayUnion(List<dynamic> _) =>
      const FieldValue._('arrayUnion');
  static FieldValue arrayRemove(List<dynamic> _) =>
      const FieldValue._('arrayRemove');
  static FieldValue delete() => const FieldValue._('delete');

  @override
  String toString() =>
      'FieldValue.$_kind${_amount != null ? "($_amount)" : ""}';
}

// ============================================================================
// Snapshots / refs
// ============================================================================

class DocumentSnapshot<T> {
  final String id;
  final T? _data;
  const DocumentSnapshot(this.id, [this._data]);
  T? data() => _data;
  bool get exists => _data != null;
  dynamic operator [](String key) =>
      _data is Map ? (_data as Map)[key] : null;
  DocumentReference<T> get reference =>
      DocumentReference<T>(id, '');
}

class QueryDocumentSnapshot<T> extends DocumentSnapshot<T> {
  const QueryDocumentSnapshot(super.id, super.data);
  @override
  T data() => super.data() as T;
}

class QuerySnapshot<T> {
  final List<QueryDocumentSnapshot<T>> docs;
  const QuerySnapshot(this.docs);
  int get size => docs.length;
  bool get isEmpty => docs.isEmpty;
}

class AggregateQuery {
  Future<AggregateQuerySnapshot> get() async =>
      const AggregateQuerySnapshot._(0);
}

class AggregateQuerySnapshot {
  final int count;
  const AggregateQuerySnapshot._(this.count);
}

// ============================================================================
// Query / Collection — todos os metodos devolvem vazio em runtime.
// ============================================================================

class Query<T> {
  const Query();
  Query<T> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    List<Object?>? arrayContainsAny,
    List<Object?>? whereIn,
    List<Object?>? whereNotIn,
    bool? isNull,
  }) =>
      this;
  Query<T> orderBy(Object field, {bool descending = false}) => this;
  Query<T> limit(int limit) => this;
  Query<T> startAt(List<Object?> values) => this;
  Query<T> startAfter(List<Object?> values) => this;
  Query<T> endAt(List<Object?> values) => this;
  Query<T> endBefore(List<Object?> values) => this;

  Future<QuerySnapshot<T>> get() async => QuerySnapshot<T>(const []);
  Stream<QuerySnapshot<T>> snapshots() =>
      Stream<QuerySnapshot<T>>.value(QuerySnapshot<T>(const []));
  AggregateQuery count() => AggregateQuery();
}

class CollectionReference<T> extends Query<T> {
  final String path;
  const CollectionReference(this.path);

  DocumentReference<T> doc([String? id]) =>
      DocumentReference<T>(id ?? _randomId(), path);

  Future<DocumentReference<T>> add(T data) async {
    debugPrint('[firestore_compat] add no-op em $path');
    return DocumentReference<T>(_randomId(), path);
  }

  String _randomId() =>
      DateTime.now().microsecondsSinceEpoch.toString();
}

class DocumentReference<T> {
  final String id;
  final String path;
  const DocumentReference(this.id, this.path);

  CollectionReference<U> collection<U>(String collectionPath) =>
      CollectionReference<U>('$path/$id/$collectionPath');

  Future<DocumentSnapshot<T>> get() async => DocumentSnapshot<T>(id);
  Stream<DocumentSnapshot<T>> snapshots() =>
      Stream<DocumentSnapshot<T>>.value(DocumentSnapshot<T>(id));

  Future<void> set(T data, [Object? options]) async {
    debugPrint('[firestore_compat] set no-op $path/$id');
  }

  Future<void> update(Map<String, dynamic> data) async {
    debugPrint('[firestore_compat] update no-op $path/$id');
  }

  Future<void> delete() async {
    debugPrint('[firestore_compat] delete no-op $path/$id');
  }
}

// ============================================================================
// FirebaseFirestore — entry point legacy
// ============================================================================

class FirebaseFirestore {
  static final FirebaseFirestore instance = FirebaseFirestore._();
  FirebaseFirestore._();

  CollectionReference<Map<String, dynamic>> collection(String path) =>
      CollectionReference<Map<String, dynamic>>(path);

  Future<T> runTransaction<T>(
    Future<T> Function(Transaction) updateFunction, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    debugPrint('[firestore_compat] runTransaction no-op');
    return await updateFunction(Transaction._());
  }

  WriteBatch batch() => WriteBatch();

  /// Compat com `FirebaseConfig` que faz `instance.app != null` em algumas
  /// verificacoes.
  FirebaseFirestore get app => this;
}

class Transaction {
  Transaction._();
  Future<DocumentSnapshot<T>> get<T>(DocumentReference<T> ref) async =>
      DocumentSnapshot<T>(ref.id);
  Future<void> set<T>(
    DocumentReference<T> ref,
    T data, [
    Object? options,
  ]) async {}
  Future<void> update(
    DocumentReference ref,
    Map<String, dynamic> data,
  ) async {}
  Future<void> delete(DocumentReference ref) async {}
}

class WriteBatch {
  Future<void> commit() async {}
  void set<T>(DocumentReference<T> ref, T data, [Object? options]) {}
  void update(DocumentReference ref, Map<String, dynamic> data) {}
  void delete(DocumentReference ref) {}
}

class SetOptions {
  final bool merge;
  const SetOptions({this.merge = false});
}
