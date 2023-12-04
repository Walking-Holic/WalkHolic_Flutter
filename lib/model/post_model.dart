
class Post {
  int id;
  String title;
  double totalDistance;
  String difficulty;
  String estimatedTime;
  double averageScore;
  String imageUrl;
  String authorName;
  String authorImageUrl;
  String rank;
  int commentCount;
  String email; // 게시글 작성자의 이메일
  bool isCurrentUserPost; // 현재 사용자가 작성한 게시글인지 여부
  bool collection;


  Post({
    required this.id,
    required this.title,
    required this.totalDistance,
    required this.difficulty,
    required this.estimatedTime,
    required this.averageScore,
    required this.imageUrl,
    required this.authorName,
    required this.authorImageUrl,
    required this.rank,
    required this.commentCount,
    required this.email,
    this.isCurrentUserPost = false,
    required this.collection
  });

  // JSON에서 Post 객체로 변환하는 생성자
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      // title이 null일 경우 빈 문자열을 사용합니다.
      totalDistance: json['totalDistance']?.toDouble() ?? 0.0,
      difficulty: json['difficulty'] ?? '',
      estimatedTime: json['estimatedTime'] ?? '',
      averageScore: json['averageScore']?.toDouble() ?? 0.0,
      imageUrl: json['pathImage'] != null
          ? "data:image/png;base64,${json['pathImage']}"
          : '',
      // null 체크 추가
      authorName:
      json['member'] != null ? json['member']['nickname'] ?? '' : '',
      // null 체크 추가
      authorImageUrl: json['member'] != null
          ? "data:image/png;base64,${json['member']['profileImage']}"
          : '',
      rank: json['member'] != null ? json['member']['rank'] ?? 'unknown' : 'unknown',
      // null 체크 추가
      commentCount: json['commentCount'] ?? 0,
      email: json['member'] != null ? json['member']['email'] ?? '' : '', // 초기값 설정
      collection: json['collection'] ?? false,
    );
  }
}

class Coordinate {
  int sequence;
  double latitude;
  double longitude;

  Coordinate({
    required this.sequence,
    required this.latitude,
    required this.longitude,
  });

  factory Coordinate.fromJson(Map<String, dynamic> json) {
    return Coordinate(
      sequence: json['sequence'] ?? 0,
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
    );
  }
}

class Author {
  String email;
  String nickname;
  String name;
  String authority;
  String rank;
  int walk;
  String profileImage;

  Author({
    required this.email,
    required this.nickname,
    required this.name,
    required this.authority,
    required this.rank,
    required this.walk,
    required this.profileImage,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      email: json['email'] ?? '',
      nickname: json['nickname'] ?? '',
      name: json['name'] ?? '',
      authority: json['authority'] ?? '',
      rank: json['rank'] ?? '',
      walk: json['walk'] ?? 0,
      profileImage: json['profileImage'] != null
          ? "data:image/png;base64,${json['profileImage']}"
          : '',
    );
  }
}

class Comment {
  int id;
  String contents;
  double score;
  Author author;

  Comment({
    required this.id,
    required this.contents,
    required this.score,
    required this.author,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id : json['id'] as int,
      contents: json['contents'] ?? '',
      score: json['score']?.toDouble() ?? 0.0,
      author: Author.fromJson(json['member'] as Map<String, dynamic>),
    );
  }
}

class DetailPost {
  String content;
  double averageScore;
  List<Coordinate> coordinates;
  List<Comment> comments;

  DetailPost({
    required this.content,
    required this.averageScore,
    required this.coordinates,
    required this.comments,
  });

  factory DetailPost.fromJson(Map<String, dynamic> json) {
    var coordinatesFromJson = json['coordinates'] as List;
    List<Coordinate> coordinatesList =
    coordinatesFromJson.map((i) => Coordinate.fromJson(i)).toList();

    var commentsFromJson = json['comments'] as List;
    List<Comment> commentsList =
    commentsFromJson.map((i) => Comment.fromJson(i)).toList();

    return DetailPost(
      content: json['content'] ?? '',
      averageScore: json['averageScore'] ?? 0.0,
      coordinates: coordinatesList,
      comments: commentsList,
    );
  }
}
