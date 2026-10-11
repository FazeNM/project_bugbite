/// Private activity metadata. Comment text is deliberately not duplicated here
/// so deleted comments cannot remain readable through an old notification.
class CommunityNotification {
  const CommunityNotification({
    required this.id,
    required this.recipientId,
    required this.actorId,
    required this.actorName,
    required this.postId,
    required this.commentId,
    required this.createdAt,
    required this.isRead,
    this.replyToCommentId,
  });

  final String id;
  final String recipientId;
  final String actorId;
  final String actorName;
  final String postId;
  final String commentId;
  final String? replyToCommentId;
  final DateTime createdAt;
  final bool isRead;

  bool get isReply => replyToCommentId != null;

  CommunityNotification copyWith({bool? isRead}) => CommunityNotification(
    id: id,
    recipientId: recipientId,
    actorId: actorId,
    actorName: actorName,
    postId: postId,
    commentId: commentId,
    replyToCommentId: replyToCommentId,
    createdAt: createdAt,
    isRead: isRead ?? this.isRead,
  );
}
