import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fresh_store_ui/screens/board/board_post.dart';
import 'package:dio/dio.dart';
import 'package:fresh_store_ui/screens/tabbar/tabbar.dart';
import 'package:http/http.dart' as http;
import '../../Source/LoginUser/login.dart';
import '../../constants.dart';
import '../../model/rank_image.dart';
import 'board_detail.dart';

class FeedScreen extends StatefulWidget {
  @override
  _FeedScreenState createState() => _FeedScreenState();
}

@override

class _FeedScreenState extends State<FeedScreen> {
  List<Post> posts = [];
  String currentUserEmail = '';
  String? email;
  String? rank;

  Future<void> _loadUserProfile() async {
    final storage = FlutterSecureStorage();

    try {
      String? accessToken = await storage.read(key: 'accessToken');
      Dio dio = Dio();
      Response response = await dio.get(
        '$IP_address/api/member/me',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      print("실행");
      print(response.statusCode);

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = response.data;
        // 이미지 바이트 배열 추출

        setState(() {
          email = responseData['email'];
          rank = responseData['rank'];
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

  void _fetchPosts() async {
    try {
      String? accessToken = await storage.read(key: 'accessToken');
      Dio dio = Dio();
      Response response = await dio.get('$IP_address/api/path',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      print("실행");
      print(response.statusCode);

      if (response.statusCode == 200) {
        List<dynamic> responseData = response.data;
        List<Post> fetchedPosts = [];

        for (var postJson in responseData) {
          Post post = Post.fromJson(postJson);
          post.isCurrentUserPost = post.email == email;
          print('Post ID: ${post.id}, isCurrentUserPost: ${post.isCurrentUserPost}'); // 디버그 문
          fetchedPosts.add(post);
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

  void markPost(int pathId) async {
      String? accessToken = await storage.read(key: 'accessToken');
      Dio dio = Dio();
      Response response = await dio.post('$IP_address/api/path/collection/$pathId',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      print(response.statusCode);
    }

  void unMarkPost(int pathId) async {
    String? accessToken = await storage.read(key: 'accessToken');
    Dio dio = Dio();
    Response response = await dio.delete('$IP_address/api/path/collection/$pathId',
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
    print(response.statusCode);
  }


  @override
  void initState() {
    super.initState();
    _loadUserProfile();
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
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
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
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
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

  Widget _buildPost(Post post) {

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
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PostDetailsScreen(post: post)),
        );
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
                    backgroundImage: MemoryImage(authorImageBytes),
                  ),
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                         Text(
                          post.authorName,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      RankImage.getRankImage(post.rank, width: 40.0, height: 40.0), // 랭크 이미지 추가
                    ],
                  ),
                  trailing: post.isCurrentUserPost
                      ? GestureDetector(
                    onTap: () => _showPostOptions(context, post),
                    child: Image.asset('assets/icons/category_others@2x.png', width: 24, height: 24),
                  )
                      : null,
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
                      mainAxisSize: MainAxisSize.min,
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
                      icon: Icon(
                        post.collection ? Icons.bookmark : Icons.bookmark_border,
                        color: Colors.black,
                      ),
                      iconSize: 30.0,
                      onPressed: () {
                        if (post.collection) {
                          // 현재 북마크 상태이면 해제 처리
                          unMarkPost(post.id); // 여기서 post.id는 해당 글의 ID
                        } else {
                          // 현재 북마크 상태가 아니면 북마크 처리
                          markPost(post.id); // 여기서 post.id는 해당 글의 ID
                        }

                        setState(() {
                          post.collection = !post.collection; // 버튼이 눌릴 때마다 상태를 전환
                        });
                      },
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
    List<Post> reversedPosts = posts.reversed.toList();

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
                  (context, index) => _buildPost(reversedPosts[index]),
              childCount: reversedPosts.length,
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniStartFloat,
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        backgroundColor: Colors.black,
        onPressed: _showAddMenu,
      ),
    );
  }
}

Future<void> deletePost(int postId, BuildContext context) async {

  try {
    String? accessToken = await storage.read(key: 'accessToken');

    var Url = Uri.parse("$IP_address/api/path/delete/$postId"); //본인 IP 주소를  localhost 대신 넣기
    var response = await http.delete(Url, // 서버의 프로필 정보 API
      headers: <String, String>{
        'Authorization': 'Bearer $accessToken'},
    );

    print(postId);
    print(response.body);
    print(response.statusCode);

    if (response.statusCode == 200) {
      // 게시물 삭제 성공 처리
      print('Post deleted successfully');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => FRTabbarScreen(initialTabIndex: 1)),
      ).then((_) {
        // 여기에서 화면을 새로 고치는 로직
      });
    } else {
      // 서버 응답 에러 처리
      print('Failed to delete post: ${response.statusCode}');
    }
  } catch (e) {
    // HTTP 요청 예외 처리
    print('Error: $e');
  }
}

void _showPostOptions(BuildContext context, Post post) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Container(
        height: 150, // 높이 설정
        child: Column(
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('게시물 수정'),
              onTap: () async {
                Navigator.pop(context); // 하단 시트 닫기

                // 'NewPostScreen'으로 네비게이트 하며, 수정할 게시물 객체를 전달
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NewPostScreen(postToEdit: post),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('게시물 삭제'),
              onTap: () async {
                Navigator.pop(context); // 하단 시트 닫기
                // 삭제 확인 대화상자 표시
                await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('게시물 삭제'),
                      content: Text('정말 이 게시글을 삭제하시겠습니까?'),
                      actions: <Widget>[
                        TextButton(
                          child: Text('예'),
                          onPressed: () {
                            Navigator.of(context).pop();
                            deletePost(post.id, context);
                          },
                        ),
                        TextButton(
                          child: Text('아니오'),
                          onPressed: () {
                            Navigator.of(context).pop(); // '아니오' 선택 시
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      );
    },
  );
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
  String rank;
  int commentCount;
  String email; // 게시글 작성자의 이메일
  bool isCurrentUserPost; // 현재 사용자가 작성한 게시글인지 여부
  bool isMarked;
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
    this.isMarked = false,
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
