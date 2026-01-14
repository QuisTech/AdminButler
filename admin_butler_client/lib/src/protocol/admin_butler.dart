/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;

abstract class Document implements _i1.SerializableModel {
  Document._({
    this.id,
    required this.fileName,
    this.fileUrl,
    required this.summary,
    this.dueDate,
    this.amount,
    required this.category,
    required this.status,
    required this.createdAt,
    required this.userId,
    this.draft,
    this.replyDraft,
  });

  factory Document({
    int? id,
    required String fileName,
    String? fileUrl,
    required String summary,
    DateTime? dueDate,
    double? amount,
    required String category,
    required String status,
    required DateTime createdAt,
    required int userId,
    String? draft,
    String? replyDraft,
  }) = _DocumentImpl;

  factory Document.fromJson(Map<String, dynamic> jsonSerialization) {
    return Document(
      id: jsonSerialization['id'] as int?,
      fileName: jsonSerialization['fileName'] as String,
      fileUrl: jsonSerialization['fileUrl'] as String?,
      summary: jsonSerialization['summary'] as String,
      dueDate: jsonSerialization['dueDate'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['dueDate']),
      amount: (jsonSerialization['amount'] as num?)?.toDouble(),
      category: jsonSerialization['category'] as String,
      status: jsonSerialization['status'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      userId: jsonSerialization['userId'] as int,
      draft: jsonSerialization['draft'] as String?,
      replyDraft: jsonSerialization['replyDraft'] as String?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String fileName;

  String? fileUrl;

  String summary;

  DateTime? dueDate;

  double? amount;

  String category;

  String status;

  DateTime createdAt;

  int userId;

  String? draft;

  String? replyDraft;

  /// Returns a shallow copy of this [Document]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Document copyWith({
    int? id,
    String? fileName,
    String? fileUrl,
    String? summary,
    DateTime? dueDate,
    double? amount,
    String? category,
    String? status,
    DateTime? createdAt,
    int? userId,
    String? draft,
    String? replyDraft,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Document',
      if (id != null) 'id': id,
      'fileName': fileName,
      if (fileUrl != null) 'fileUrl': fileUrl,
      'summary': summary,
      if (dueDate != null) 'dueDate': dueDate?.toJson(),
      if (amount != null) 'amount': amount,
      'category': category,
      'status': status,
      'createdAt': createdAt.toJson(),
      'userId': userId,
      if (draft != null) 'draft': draft,
      if (replyDraft != null) 'replyDraft': replyDraft,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DocumentImpl extends Document {
  _DocumentImpl({
    int? id,
    required String fileName,
    String? fileUrl,
    required String summary,
    DateTime? dueDate,
    double? amount,
    required String category,
    required String status,
    required DateTime createdAt,
    required int userId,
    String? draft,
    String? replyDraft,
  }) : super._(
         id: id,
         fileName: fileName,
         fileUrl: fileUrl,
         summary: summary,
         dueDate: dueDate,
         amount: amount,
         category: category,
         status: status,
         createdAt: createdAt,
         userId: userId,
         draft: draft,
         replyDraft: replyDraft,
       );

  /// Returns a shallow copy of this [Document]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Document copyWith({
    Object? id = _Undefined,
    String? fileName,
    Object? fileUrl = _Undefined,
    String? summary,
    Object? dueDate = _Undefined,
    Object? amount = _Undefined,
    String? category,
    String? status,
    DateTime? createdAt,
    int? userId,
    Object? draft = _Undefined,
    Object? replyDraft = _Undefined,
  }) {
    return Document(
      id: id is int? ? id : this.id,
      fileName: fileName ?? this.fileName,
      fileUrl: fileUrl is String? ? fileUrl : this.fileUrl,
      summary: summary ?? this.summary,
      dueDate: dueDate is DateTime? ? dueDate : this.dueDate,
      amount: amount is double? ? amount : this.amount,
      category: category ?? this.category,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      draft: draft is String? ? draft : this.draft,
      replyDraft: replyDraft is String? ? replyDraft : this.replyDraft,
    );
  }
}
