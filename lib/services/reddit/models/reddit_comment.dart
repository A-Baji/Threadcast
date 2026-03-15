class RedditComment {
  final String id;
  final String authorName;
  final String body;
  final int score;
  final int depth; // 0 = top-level, 1 = reply, 2 = reply-to-reply
  final String? parentId; // null if top-level
  final List<RedditComment> replies;
  final bool isOp; // True if authorName == post author

  RedditComment({
    required this.id,
    required this.authorName,
    required this.body,
    required this.score,
    required this.depth,
    this.parentId,
    required this.replies,
    required this.isOp,
  });

  factory RedditComment.fromJson(Map<String, dynamic> json) {
    // Stub implementation
    return RedditComment(
      id: json['id'],
      authorName: json['author'],
      body: json['body'],
      score: json['score'],
      depth: json['depth'] ?? 0,
      parentId: json['parent_id'],
      replies: [], // Parse replies
      isOp: false, // Determine based on post author
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': authorName,
      'body': body,
      'score': score,
      'depth': depth,
      'parent_id': parentId,
      'replies': replies.map((r) => r.toJson()).toList(),
      'is_op': isOp,
    };
  }
}
