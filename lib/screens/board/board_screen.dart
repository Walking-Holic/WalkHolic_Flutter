import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fresh_store_ui/screens/board/board_header.dart';
import 'package:fresh_store_ui/screens/board/board_post.dart';
import 'package:dio/dio.dart';

import '../../constants.dart';
import '../tabbar/tabbar.dart';

class FeedScreen extends StatefulWidget {
  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class PostDetailsScreen extends StatefulWidget {
  final Post post;

  PostDetailsScreen({required this.post});

  @override
  _PostDetailsScreenState createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  final TextEditingController _commentController = TextEditingController();
  List<Comment> _comments = [];
  DetailPost? postDetail; // 현재 게시글의 상세 정보를 저장할 변수
  double _rating = 3; // 초기 별점 값
  Uint8List? profileImage;
  String? nickname;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchPostsDetail(widget.post.id);
    _loadUserProfile();
  }

  Future<void> _fetchPostsDetail(int id) async {
    setState(() {
      _isLoading = true; // 로딩 시작
    });

    try {
      Dio dio = Dio();
      Response response = await dio.get('http://$IP_address:8080/api/path/$id');
      print("실행");
      print(response.statusCode);

      if (response.statusCode == 200) {
        setState(() {
          postDetail = DetailPost.fromJson(response.data);
          _comments = postDetail!.comments;
          _isLoading = false; // 로딩 완료// 댓글 데이터 저장// 상세 정보 저장
        });
      } else {
        print('잘못된 Url 경로');
      }
    } catch (e) {
      // 예외 처리
      print('Error: $e');
    }
  }

  Future<void> _loadUserProfile() async {
    final storage = FlutterSecureStorage();

    try {
      String? accessToken = await storage.read(key: 'accessToken');
      Dio dio = Dio();
      Response response = await dio.get(
        'http://$IP_address:8080/api/member/me',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      print("실행");
      print(response.statusCode);

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = response.data;
        // 이미지 바이트 배열 추출
        String base64String = responseData['profileImage'];
        Uint8List imageBytes = base64.decode(base64String);

        setState(() {
          profileImage = imageBytes;
          nickname = responseData['nickname'];
        });
      } else {
        // 에러 처리
        print('Failed to load user profile: ${response.statusCode}');
      }
    } catch (e) {
      // 예외 처리
      print('Error: $e');
    }
  }

  void _addComment(String commentText) async {
    if (commentText.isNotEmpty) {
      setState(() {
        _isLoading = true; // 로딩 시작
      });
      // 댓글 객체 생성
      Comment newComment = Comment(
        contents: commentText,
        score: _rating,
        author: Author(
          nickname: nickname ?? '익명',
          // 현재 사용자의 닉네임
          profileImage: profileImage != null ? base64Encode(profileImage!) : '',
          // 현재 사용자의 프로필 이미지
          email: '',
          // 필요한 경우 이메일 추가
          name: '',
          // 필요한 경우 이름 추가
          authority: '',
          // 필요한 경우 권한 추가
          rank: '',
          // 필요한 경우 랭크 추가
          walk: 0, // 필요한 경우 걸음 수 추가
        ),
      );

      // 댓글을 로컬 상태에 추가
      setState(() {
        _comments.add(newComment);
        _commentController.clear();
      });

      // 서버에 댓글 정보 전송
      final storage = FlutterSecureStorage();
      String? accessToken = await storage.read(key: 'accessToken');
      Dio dio = Dio();
      try {
        Response response = await dio.post(
          'http://$IP_address:8080/api/comment/save/${widget.post.id}',
          options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
          data: {"contents": commentText, "score": _rating},
        );

        await _fetchPostsDetail(widget.post.id);
      } catch (e) {
        print('댓글 전송 오류: $e');
      } finally {
        setState(() {
          _isLoading = false; // 로딩 종료
        });
      }
    }
  }

  String getKoreanDifficulty(String difficulty) {
    switch (difficulty) {
      case "UPPER":
        return "상";
      case "MIDDLE":
        return "중";
      case "LOWER":
        return "하";
      default:
        return "미정"; // 난이도 정보가 없거나 매칭되지 않는 경우
    }
  }

  @override
  Widget build(BuildContext context) {
    // Base64 이미지 디코딩
    String base64ImageUrl = widget.post.imageUrl;
    if (base64ImageUrl.startsWith('data:image/png;base64,')) {
      base64ImageUrl =
          base64ImageUrl.substring('data:image/png;base64,'.length);
    }
    Uint8List imageBytes = base64.decode(base64ImageUrl);

    String base64AuthorImageUrl = widget.post.authorImageUrl
        .substring(widget.post.authorImageUrl.indexOf(',') + 1);
    Uint8List authorImageBytes = base64.decode(base64AuthorImageUrl);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, // AppBar의 배경을 투명하게 설정
        elevation: 0, // 그림자를 없애기 위해 elevation을 0으로 설정
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => FRTabbarScreen(
                        initialTabIndex: 1) // FeedScreen이 두 번째 탭일 경우
                    ));
          },
        ),
        title: Text(widget.post.title),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(10.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[400],
                    backgroundImage: MemoryImage(authorImageBytes),
                  ),
                  title: Text(
                    widget.post.authorName,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(widget.post.timeAgo),
                ),
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                  child: Text(
                    widget.post.title,
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Image.memory(
                  imageBytes,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.width,
                  fit: BoxFit.cover,
                ),
                Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      postDetail != null ? postDetail!.content : '로딩 중...',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "난이도: ${getKoreanDifficulty(widget.post.difficulty)}",
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "예상 소요 시간: ${widget.post.estimatedTime} 분",
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "경로 길이: ${widget.post.totalDistance} km",
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    if (_isLoading)
                      // 로딩 중일 때 로딩 인디케이터 표시
                      Center(child: CircularProgressIndicator()),
                    if (!_isLoading)
                      // 로딩이 끝난 후 댓글 목록 표시
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          Comment comment = _comments[index];
                          // Base64 문자열에서 이미지 데이터 추출
                          String base64AuthorImageUrl =
                              comment.author.profileImage;
                          Uint8List authorImageBytes =
                              base64.decode(base64AuthorImageUrl.split(',')[1]);

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: MemoryImage(authorImageBytes),
                            ),
                            title: Text(_comments[index].contents),
                            subtitle: Text(_comments[index].author.nickname),
                            trailing: Text(_comments[index].score.toString()),
                          );
                        },
                      ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: RatingBar.builder(
                    initialRating: _rating,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: false,
                    itemCount: 5,
                    itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                    itemBuilder: (context, _) =>
                        Icon(Icons.star, color: Colors.amber),
                    onRatingUpdate: (rating) {
                      setState(() {
                        _rating = rating;
                      });
                    },
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        CircleAvatar(
                          backgroundImage: profileImage != null
                              ? MemoryImage(profileImage!)
                              : null,
                          radius: 20.0,
                        ),
                        SizedBox(height: 4.0),
                        Text(nickname ?? '', style: TextStyle(fontSize: 12.0)),
                      ],
                    ),
                    SizedBox(width: 8.0),
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: '후기와 별점을 남겨주세요!',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send),
                      onPressed: () => _addComment(_commentController.text),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedScreenState extends State<FeedScreen> {
  List<Post> posts = [];

  void _fetchPosts() async {
    try {
      Dio dio = Dio();
      Response response = await dio.get('http://$IP_address:8080/api/path');
      print("실행");
      print(response.statusCode);

      if (response.statusCode == 200) {
        List<dynamic> responseData = response.data;
        List<Post> fetchedPosts = [];

        for (var postJson in responseData) {
          fetchedPosts.add(Post.fromJson(postJson));
        }

        setState(() {
          posts = fetchedPosts;
        });
      } else {
        print('잘못된 Url 경로');
      }
    } catch (e) {
      // 예외 처리
      print('Error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  void _showAddMenu() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 60.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // 실제 내용의 크기만큼만 차지하도록 설정
            children: <Widget>[
              // 커스텀 버튼으로 카메라 기능 구현
              ElevatedButton.icon(
                icon: Icon(Icons.edit),
                label: Text('게시글 작성'),
                onPressed: () {
                  Navigator.pop(context); // 하단 시트를 닫습니다.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            NewPostScreen()), // 새로운 화면으로 이동합니다.
                  );
                },
                style: ElevatedButton.styleFrom(
                  primary: Colors.white,
                  onPrimary: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                ),
              ),
              SizedBox(height: 10), // 버튼 사이의 간격
              // 커스텀 버튼으로 갤러리 기능 구현
              ElevatedButton.icon(
                icon: Icon(Icons.search),
                label: Text('게시글 검색'),
                onPressed: () {
                  // 갤러리 기능을 여기에 구현하세요.
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  primary: Colors.white,
                  onPrimary: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPost(int index) {
    final post = posts[index];

    String base64ImageUrl = post.imageUrl;
    if (base64ImageUrl.startsWith('data:image/png;base64,')) {
      base64ImageUrl =
          base64ImageUrl.substring('data:image/png;base64,'.length);
    }
    String base64authorImageUrl =
        post.authorImageUrl.substring(post.authorImageUrl.indexOf(',') + 1);

    Uint8List imageBytes = base64.decode(base64ImageUrl);
    Uint8List authorImageBytes = base64.decode(base64authorImageUrl);

    return InkWell(
      onTap: () async {
        // 결과를 받습니다.
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PostDetailsScreen(post: post)),
        );
        if (result != null) {
          // 예를 들어, 결과로부터 댓글 수와 별점을 추출하여 UI를 업데이트합니다.
          int commentsCount = result['commentsCount'];
          double rating = result['rating'];
        }
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 7,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[400],
                    backgroundImage: MemoryImage(authorImageBytes),
                  ),
                  title: Text(
                    post.authorName,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(post.timeAgo),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  post.title,
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Image.memory(
                imageBytes,
                width: 200.0, // 이미지의 너비 설정
                height: 200.0, // 이미지의 높이 설정
                fit: BoxFit.cover, // 이미지를 컨테이너에 맞추도록 조정
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.star, color: Colors.amber, size: 30.0),
                        // 평균 점수 표시
                        Text(
                          '${post.averageScore.toStringAsFixed(1)}',
                          // 소수점 한 자리까지 표현
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 30.0),
                        IconButton(
                          icon: Icon(Icons.chat),
                          iconSize: 30.0,
                          onPressed: () {},
                        ),
                        Text(
                          '${post.commentCount}', // 댓글 수 표시
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.bookmark_border),
                      iconSize: 30.0,
                      onPressed: () => print('Save post'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEDF0F6),
      body: CustomScrollView(
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, top: 24),
                child: Row(
                  children: [
                    Image.asset('assets/icons/profile/logo@2x.png', scale: 2),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text('게시판',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ]),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildPost(index),
              childCount: posts.length,
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniStartFloat,
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: _showAddMenu,
      ),
    );
  }
}

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
  String timeAgo;
  int commentCount;

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
    required this.timeAgo,
    required this.commentCount,
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
      // null 체크 추가
      timeAgo: "Some time ago",
      // 시간은 API 응답에 따라 조정
      commentCount: json['commentCount'] ?? 0,
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
  String contents;
  double score;
  Author author;

  Comment({
    required this.contents,
    required this.score,
    required this.author,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      contents: json['contents'] ?? '',
      score: json['score']?.toDouble() ?? 0.0,
      author: Author.fromJson(json['member']),
    );
  }
}

class DetailPost {
  String content;
  List<Coordinate> coordinates;
  List<Comment> comments;

  DetailPost({
    required this.content,
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
      coordinates: coordinatesList,
      comments: commentsList,
    );
  }
}
