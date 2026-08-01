import 'dart:typed_data';

import 'bite_guide.dart';

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.author,
    required this.location,
    required this.createdAt,
    required this.possibleMatch,
    required this.body,
    required this.visual,
    required this.tags,
    this.imageBytes,
    this.likes = 0,
    this.liked = false,
  });

  final String id;
  final String author;
  final String location;
  final DateTime createdAt;
  final String possibleMatch;
  final String body;
  final BiteVisual visual;
  final List<String> tags;
  final Uint8List? imageBytes;
  final int likes;
  final bool liked;

  CommunityPost copyWith({int? likes, bool? liked}) => CommunityPost(
    id: id,
    author: author,
    location: location,
    createdAt: createdAt,
    possibleMatch: possibleMatch,
    body: body,
    visual: visual,
    tags: tags,
    imageBytes: imageBytes,
    likes: likes ?? this.likes,
    liked: liked ?? this.liked,
  );
}
