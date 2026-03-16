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

  factory RedditComment.fromJson(Map<String, dynamic> json, String opUsername) {
    List<RedditComment> parseReplies(dynamic replies) {
      if (replies is String || replies == null) {
        return [];
      }

      final listing = replies as Map<String, dynamic>;
      final children = (listing['data']?['children'] as List?) ?? const [];

      return children
          .where((child) => child is Map && child['kind'] == 't1')
          .map(
            (child) => RedditComment.fromJson(
              Map<String, dynamic>.from((child as Map)['data'] as Map),
              opUsername,
            ),
          )
          .toList();
    }

    return RedditComment(
      id: json['id']?.toString() ?? '',
      authorName: json['author']?.toString() ?? '[deleted]',
      body: json['body']?.toString() ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
      depth: (json['depth'] as num?)?.toInt() ?? 0,
      parentId: json['parent_id']?.toString(),
      replies: parseReplies(json['replies']),
      isOp: (json['author']?.toString() ?? '') == opUsername,
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
