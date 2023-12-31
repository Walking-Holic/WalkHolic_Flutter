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
import 'package:fresh_store_ui/model/post_model.dart';

class MarkFeedScreen extends StatefulWidget {
  @override
  _MarkFeedScreenState createState() => _MarkFeedScreenState();
}

@override

class _MarkFeedScreenState extends State<MarkFeedScreen> {
  List<Post> posts = [];
  String currentUserEmail = '';
  String? email;
  String? rank;
  final storage = FlutterSecureStorage();
  bool isLoading = true; // 데이터 로딩 상태 관리 변수

  Future<void> _loadUserProfile() async {
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

          if (post.collection) {
            fetchedPosts.add(post);
          }
        }

        setState(() {
          posts = fetchedPosts;
          isLoading = false; // 데이터 로딩 완료
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
    Response response = await dio.post(
      '$IP_address/api/path/collection/$pathId',
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
    print(response.statusCode);
  }

  void unMarkPost(int pathId) async {
    String? accessToken = await storage.read(key: 'accessToken');
    Dio dio = Dio();
    Response response = await dio.delete(
      '$IP_address/api/path/collection/$pathId',
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


  Widget _buildPost(Post post, int id) {
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
              builder: (context) => PostDetailsScreen(id: id)),
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
                      RankImage.getRankImage(
                          post.rank, width: 40.0, height: 40.0), // 랭크 이미지 추가
                    ],
                  ),
                  trailing: post.isCurrentUserPost
                      ? GestureDetector(
                    onTap: () => _showPostOptions(context, post),
                    child: Image.asset(
                        'assets/icons/category_others@2x.png', width: 24,
                        height: 24),
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
                        post.collection ? Icons.bookmark : Icons
                            .bookmark_border,
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
                          post.collection =
                          !post.collection; // 버튼이 눌릴 때마다 상태를 전환
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
                padding: const EdgeInsets.only(left: 24, right: 24, top: 50),
              ),
            ]),
          ),
          isLoading
              ? SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: Colors.black),
            ),
          )
              : SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildPost(posts[index], posts[index].id),
              childCount: posts.length,
            ),
          ),
        ],
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
