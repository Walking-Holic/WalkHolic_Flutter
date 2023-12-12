import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:fresh_store_ui/model/rank_image.dart';
import 'package:fresh_store_ui/screens/board/new_kakao_map.dart';
import '../../constants.dart';
import 'package:fresh_store_ui/model/post_model.dart';

class PostDetailsScreen extends StatefulWidget {
  final int id;

  PostDetailsScreen({required this.id});

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
  String? email;
  int? id;
  String? rank;
  final storage = FlutterSecureStorage();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    _fetchPostsDetail(widget.id);
    _loadUserProfile();
  }

  Future<void> _fetchPostsDetail(int id) async {
    setState(() {
      _isLoading = true; // 로딩 시작
    });

    try {
      String? accessToken = await storage.read(key: 'accessToken');
      Dio dio = Dio();
      Response response = await dio.get('$IP_address/api/path/$id',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),);
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
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      // 예외 처리
      print('Error: $e');
    }
  }

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
        String base64String = responseData['profileImage'];
        Uint8List imageBytes = base64.decode(base64String);

        setState(() {
          profileImage = imageBytes;
          nickname = responseData['nickname'];
          email = responseData['email'];
          id = responseData['id'];
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
          email: email ?? '',
          // 필요한 경우 이메일 추가
          name: '',
          // 필요한 경우 이름 추가
          authority: '',
          // 필요한 경우 권한 추가
          rank: rank ?? '',
          // 필요한 경우 랭크 추가
          walk: 0, // 필요한 경우 걸음 수 추가
        ),
        id: id ?? 0,
      );

      // 댓글을 로컬 상태에 추가
      setState(() {
        _comments.add(newComment);
        _commentController.clear();
      });

      // 서버에 댓글 정보 전송
      String? accessToken = await storage.read(key: 'accessToken');
      Dio dio = Dio();
      try {
        Response response = await dio.post(
          '$IP_address/api/comment/save/${widget.id}',
          options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
          data: {"contents": commentText, "score": _rating},
        );

        await _fetchPostsDetail(widget.id);
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

// 댓글 삭제 로직을 수행하는 함수
  Future<void> _deleteComment(int commentId) async {
    setState(() {
      _isLoading = true;
    });

    String? accessToken = await storage.read(key: 'accessToken');
    Dio dio = Dio();

    try {
      Response response = await dio.get(
        '$IP_address/api/comment/delete/$commentId',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        // 댓글 목록을 새로고침
        await _fetchPostsDetail(widget.id);
      } else {
        // 에러 처리
        print('댓글 삭제 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('댓글 삭제 오류: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  // _showDeleteConfirmationDialog 함수
  void _showDeleteConfirmationDialog(int commentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('댓글 삭제'),
          content: Text('정말 댓글을 삭제 하시겠습니까?'),
          actions: <Widget>[
            TextButton(
              child: Text('예'),
              onPressed: () {
                Navigator.of(context).pop(); // 대화 상자 닫기
                _deleteComment(commentId); // 댓글 삭제 함수 호출
              },
            ),
            TextButton(
              child: Text('아니오'),
              onPressed: () {
                Navigator.of(context).pop(); // 대화 상자 닫기
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _editComment(Comment comment, int index) async {
    TextEditingController editController =
    TextEditingController(text: comment.contents);
    double newRating = comment.score; // 기존 별점을 초기값으로 설정

    // 대화 상자를 표시하여 수정 내용을 받습니다.
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('후기 설정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RatingBar.builder(
                initialRating: newRating,
                minRating: 1,
                direction: Axis.horizontal,
                itemCount: 5,
                itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) =>
                    Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (rating) {
                  newRating = rating;
                },
              ),
              SizedBox(height: 10.0),
              TextField(
                controller: editController,
                decoration: InputDecoration(labelText: '현재 후기'),
                maxLength: 50, // 최대 글자 수를 50으로 제한
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('삭제'),
              onPressed: () {
                Navigator.of(context).pop(); // 대화 상자 닫기
                _showDeleteConfirmationDialog(comment.id); // 댓글 삭제 함수 호출
              },
            ),
            TextButton(
              child: Text('수정'),
              onPressed: () {
                Navigator.of(context).pop();
                _updateComment(comment.id, editController.text, newRating);
              },
            ),
            TextButton(
              child: Text('취소'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> convertCoordinates(List<Coordinate> coordinates) {
    return coordinates.map((coordinate) {
      return {
        'latitude': coordinate.latitude,
        'longitude': coordinate.longitude,
        'sequence' : coordinate.sequence,
      };
    }).toList();
  }

  // 댓글 수정 로직을 수행하는 함수
  Future<void> _updateComment(
      int commentId, String newText, double newRating) async {
    setState(() {
      _isLoading = true;
    });
    String? accessToken = await storage.read(key: 'accessToken');
    Dio dio = Dio();

    try {
      Response response = await dio.post(
        '$IP_address/api/comment/update/$commentId',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
        data: {
          "contents": newText,
          "score": newRating,
        },
      );

      if (response.statusCode == 200) {
        // 댓글 목록을 새로고침
        await _fetchPostsDetail(widget.id);
      } else {
        // 에러 처리
        print('댓글 수정 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('댓글 수정 오류: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget build(BuildContext context) {
    // Base64 이미지 디코딩

    if (postDetail == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ); // 로딩 인디케이터 표시
    }
    else {
    String base64ImageUrl = postDetail!.imageUrl;
    if (base64ImageUrl.startsWith('data:image/png;base64,')) {
      base64ImageUrl =
          base64ImageUrl.substring('data:image/png;base64,'.length);
    }
    Uint8List imageBytes = base64.decode(base64ImageUrl);

    String base64AuthorImageUrl = postDetail!.authorImageUrl
        .substring(postDetail!.authorImageUrl.indexOf(',') + 1);
    Uint8List authorImageBytes = base64.decode(base64AuthorImageUrl);


      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
        child: SingleChildScrollView(
        child: Padding(
        padding: EdgeInsets.only(top: 30, left: 10, right: 10, bottom: 10),
    child:Container(
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
                      backgroundImage: MemoryImage(authorImageBytes),
                    ),
                    title: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          postDetail!.authorName,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ), // 이름과 랭크 이미지 사이의 간격
                        RankImage.getRankImage(postDetail!.rank, width: 40.0, height: 40.0),
                      ],
                    ),
                  ),
                  Padding(
                    padding:
                    EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                    child: Text(
                      postDetail!.title,
                      style: TextStyle(
                        fontSize: 25.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        postDetail != null ? postDetail!.content : '로딩 중...',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Image.memory(
                    imageBytes,
                    width: MediaQuery
                        .of(context)
                        .size
                        .width,
                    height: MediaQuery
                        .of(context)
                        .size
                        .width,
                    fit: BoxFit.cover,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: ElevatedButton(
                      onPressed: () {
                        if (postDetail != null && postDetail!.coordinates.isNotEmpty) {
                          // NewKakaoMapTest 클래스로 이동하며 coordinates 전달
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  NewKakaoMapTest(
                                    coordinates: convertCoordinates(postDetail!.coordinates),
                                  ),
                            ),
                          );
                        } else {
                          // 경로 정보가 없는 경우
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('경로 정보가 없습니다.')),
                          );
                        }
                      },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        textStyle: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15.0,
                        ),
                      ),
                      child: Text('작성자의 경로 보러가기'),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(5.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 10.0), // 동그라미 아이콘
                            SizedBox(width: 5), // 아이콘과 텍스트 사이 간격
                            Text(
                              "난이도: ${getKoreanDifficulty(postDetail!.difficulty)}",
                              style: TextStyle(fontWeight: FontWeight.bold), // 굵은 폰트
                            ),
                          ],
                        ),
                        SizedBox(width: 10),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 10.0), // 동그라미 아이콘
                            SizedBox(width: 5),
                            Text(
                              "예상 소요 시간: ${postDetail!.estimatedTime} 분",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(width: 10),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 10.0), // 동그라미 아이콘
                            SizedBox(width: 5),
                            Text(
                              "경로 길이: ${postDetail!.totalDistance} km",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start, // 왼쪽 정렬
                          children: <Widget>[
                            Icon(Icons.star, color: Colors.amber, size: 30.0),
                            SizedBox(width: 5),
                            Text(
                              postDetail?.averageScore != null ? '별점 ${postDetail!.averageScore.toStringAsFixed(1)}' : '', // 별점 평균 표시 또는 빈칸
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
                              '댓글 ${_comments.length}', // 댓글 수 표시
                              style: TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    color: Colors.black, // Divider 색상 설정
                    thickness: 0.1, // Divider 두께 설정
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
                            String base64AuthorImageUrl = comment.author.profileImage;
                            Uint8List authorImageBytes = base64.decode(base64AuthorImageUrl.split(',')[1]);
                            return Column(
                              children: [
                                ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: MemoryImage(authorImageBytes),
                                  ),
                                  title: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        comment.author.nickname, // 닉네임
                                        style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                                      ), // 닉네임과 랭크 이미지 사이 간격
                                      RankImage.getRankImage(comment.author.rank, width: 25.0, height: 25.0), // 랭크 이미지 추가
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          comment.contents, // 댓글 내용
                                          style: TextStyle(fontSize: 20.0),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(top: 4.0),
                                        child: RatingBarIndicator(
                                          rating: comment.score,
                                          itemBuilder: (context, _) => Icon(Icons.star, color: Colors.amber),
                                          itemCount: 5,
                                          itemSize: 20.0,
                                          direction: Axis.horizontal,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: (comment.author.email == email) // 현재 사용자의 댓글인지 확인
                                      ? IconButton(
                                    icon: Icon(Icons.edit),
                                    onPressed: () => _editComment(comment, index),
                                  )
                                      : null,
                                ),
                                if (index < _comments.length - 1)
                                  Divider(
                                    color: Colors.black, // Divider 색상 설정
                                    thickness: 0.1, // Divider 두께 설정
                                  ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                  Divider(
                    color: Colors.black, // Divider 색상 설정
                    thickness: 1.0, // Divider 두께 설정
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
                      SizedBox(width: 10.0),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundImage: profileImage != null
                                ? MemoryImage(profileImage!)
                                : null,
                            radius: 25.0,
                          ),
                          Text(nickname ?? '', style: TextStyle(fontSize: 12.0)),
                          SizedBox(height: 4.0),
                        ],
                      ),
                      SizedBox(width: 10.0),
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: '후기와 별점을 남겨주세요!',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 5.0, horizontal: 10.0), // 패딩 조절
                          ),
                          style: TextStyle(fontSize: 16.0), // 글꼴 크기 조절
                          maxLength: 50, // 최대 글자 수를 50으로 제한
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
      ),
      );
    }
  }
}
