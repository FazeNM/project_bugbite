import 'dart:convert';
import 'dart:typed_data';

class CommunityComment {
  const CommunityComment({
    required this.id,
    required this.authorId,
    required this.author,
    required this.body,
    required this.createdAt,
    this.replyToCommentId,
    this.replyToAuthorId,
    this.replyToAuthor,
  });

  factory CommunityComment.fromJson(Map<String, Object?> json) =>
      CommunityComment(
        id: json['id']! as String,
        authorId: json['authorId']! as String,
        author: json['author']! as String,
        body: json['body']! as String,
        createdAt: DateTime.parse(json['createdAt']! as String),
        replyToCommentId: json['replyToCommentId'] as String?,
        replyToAuthorId: json['replyToAuthorId'] as String?,
        replyToAuthor: json['replyToAuthor'] as String?,
      );

  final String id;
  final String authorId;
  final String author;
  final String body;
  final DateTime createdAt;
  final String? replyToCommentId;
  final String? replyToAuthorId;
  final String? replyToAuthor;

  bool get isReply => replyToCommentId != null;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'authorId': authorId,
    'author': author,
    'body': body,
    'createdAt': createdAt.toIso8601String(),
    'replyToCommentId': ?replyToCommentId,
    'replyToAuthorId': ?replyToAuthorId,
    'replyToAuthor': ?replyToAuthor,
  };
}

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.authorId,
    required this.author,
    required this.location,
    required this.createdAt,
    required this.possibleMatch,
    required this.body,
    required this.guideId,
    required this.tags,
    this.comments = const <CommunityComment>[],
    this.imageBytes,
    this.imagePath,
    this.remoteCommentCount,
    this.publishedPostId,
    this.likes = 0,
    this.liked = false,
  });

  final String id;
  final String authorId;
  final String author;
  final String location;
  final DateTime createdAt;
  final String possibleMatch;
  final String body;

  /// Null when the author suggests a bug outside the guide catalog.
  final String? guideId;
  final List<String> tags;
  final List<CommunityComment> comments;
  final Uint8List? imageBytes;

  /// Authenticated Cloud Storage path, never a publicly reusable download URL.
  final String? imagePath;

  /// Cloud comments are paginated separately from the post document.
  final int? remoteCommentCount;

  /// Set only after the owner explicitly publishes an older device-only post.
  final String? publishedPostId;
  final int likes;
  final bool liked;

  int get totalComments => remoteCommentCount ?? comments.length;

  factory CommunityPost.fromJson(Map<String, Object?> json) {
    final encodedImage = json['imageBase64'] as String?;
    return CommunityPost(
      id: json['id']! as String,
      authorId: json['authorId'] as String? ?? 'legacy-seed',
      author: json['author']! as String,
      location: json['location']! as String,
      createdAt: DateTime.parse(json['createdAt']! as String),
      possibleMatch: json['possibleMatch']! as String,
      body: json['body']! as String,
      guideId: json['guideId'] as String?,
      tags: List<String>.unmodifiable(
        (json['tags']! as List<Object?>).cast<String>(),
      ),
      comments: List<CommunityComment>.unmodifiable(
        (json['comments'] as List<Object?>? ?? const <Object?>[])
            .whereType<Map<String, Object?>>()
            .map(CommunityComment.fromJson),
      ),
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      liked: json['liked'] as bool? ?? false,
      imageBytes: encodedImage == null ? null : base64Decode(encodedImage),
      imagePath: json['imagePath'] as String?,
      remoteCommentCount: (json['remoteCommentCount'] as num?)?.toInt(),
      publishedPostId: json['publishedPostId'] as String?,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'authorId': authorId,
    'author': author,
    'location': location,
    'createdAt': createdAt.toIso8601String(),
    'possibleMatch': possibleMatch,
    'body': body,
    'guideId': guideId,
    'tags': tags,
    'comments': comments
        .map((comment) => comment.toJson())
        .toList(growable: false),
    'likes': likes,
    'liked': liked,
    if (imageBytes case final bytes?) 'imageBase64': base64Encode(bytes),
    'imagePath': ?imagePath,
    'remoteCommentCount': ?remoteCommentCount,
    'publishedPostId': ?publishedPostId,
  };

  CommunityPost copyWith({
    int? likes,
    bool? liked,
    List<CommunityComment>? comments,
    String? publishedPostId,
  }) => CommunityPost(
    id: id,
    authorId: authorId,
    author: author,
    location: location,
    createdAt: createdAt,
    possibleMatch: possibleMatch,
    body: body,
    guideId: guideId,
    tags: tags,
    comments: comments ?? this.comments,
    imageBytes: imageBytes,
    imagePath: imagePath,
    remoteCommentCount: remoteCommentCount,
    publishedPostId: publishedPostId ?? this.publishedPostId,
    likes: likes ?? this.likes,
    liked: liked ?? this.liked,
  );
}
