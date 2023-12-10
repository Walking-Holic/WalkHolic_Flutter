import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fresh_store_ui/constants.dart';
import 'package:fresh_store_ui/model/rank_image.dart';

import '../home/home.dart';

class TrackDetail extends StatefulWidget {
  final int id;

  TrackDetail({Key? key, required this.id}) : super(key: key);

  @override
  _TrackDetailState createState() => _TrackDetailState();
}

class _TrackDetailState extends State<TrackDetail> {
  Track? trackInfo;
  DetailTrack? trackDetailInfo;
  List<Comment> _comments = [];
  double _rating = 3;
  Uint8List? profileImage;
  String? nickname;
  String? email;
  int? id;
  String? rank;
  final storage = FlutterSecureStorage();
  bool _isLoading = false;
  final TextEditingController _commentController = TextEditingController();

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

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    fetchDetail(widget.id); // 안전한 호출
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

  Future<void> _deleteComment(int commentId) async {
    setState(() {
      _isLoading = true;
    });

    String? accessToken = await storage.read(key: 'accessToken');
    Dio dio = Dio();

    try {
      Response response = await dio.delete(
        '$IP_address/api/comment/trail/$commentId/delete',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        // 댓글 목록을 새로고침
        await fetchDetail(widget.id);
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

  Future<void> _updateComment(
      int commentId, String newText, double newRating) async {
    setState(() {
      _isLoading = true;
    });
    String? accessToken = await storage.read(key: 'accessToken');
    Dio dio = Dio();

    try {
      Response response = await dio.patch(
        '$IP_address/api/comment/trail/$commentId/update',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
        data: {
          "contents": newText,
          "score": newRating,
        },
      );

      if (response.statusCode == 200) {
        // 댓글 목록을 새로고침
        await fetchDetail(widget.id);
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

      print("진행");
      String? accessToken = await storage.read(key: 'accessToken');
      Dio dio = Dio();
      try {
        Response response = await dio.post(
          '$IP_address/api/comment/trail/${widget.id}/save',
          options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
          data: {"contents": commentText, "score": _rating},
        );

        await fetchDetail(widget.id);
        print(trackInfo!.id);
      } catch (e) {
        print('댓글 전송 오류: $e');
      } finally {
        setState(() {
          _isLoading = false; // 로딩 종료
        });
      }
    }
  }

  Future<void> fetchDetail(int trailId) async {
    try {
      String? accessToken = await storage.read(key: 'accessToken');
      Dio dio = Dio();
      Response response = await dio.get(
        '$IP_address/api/trail/$trailId',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      print("실행");
      print(response.statusCode);
      print(response);

      if (response.statusCode == 200) {
        setState(() {
          trackDetailInfo = DetailTrack.fromJson(response.data);
          _comments = trackDetailInfo!.comments;
          _isLoading = false; // 로딩 완료// 댓글 데이터 저장// 상세 정보 저장
        });
      } else {
        print("Failed to load data. Status code: ${response.statusCode}");
      }
    } catch (e) {
      // 네트워크 오류 또는 기타 오류 처리
      print("Error fetching data: $e");
      setState(() {
        _isLoading = false;
        // 오류 메시지를 표시하는 위젯 또는 로직을 추가할 수 있습니다.
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (trackDetailInfo == null) {
      // 로딩 상태 표시
      return CircularProgressIndicator();
    }
    return Scaffold(
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
            ),child: Column(
                  children: [
                    SizedBox(height: 10),
                    Text(
                      '${trackDetailInfo!.wlkCoursFlagNm}',
                      style: TextStyle(fontSize: 30.0),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start, // 텍스트를 왼쪽 정렬
                      children: [
                        Row(
                          children: [
                            Icon(Icons.golf_course),
                        Text(" 코스 : ",
                            style: TextStyle(fontSize: 17.0, fontWeight: FontWeight.w800)),
                    Text("${trackDetailInfo!.wlkCoursNm}",
                        style: TextStyle(fontSize: 17.0))]
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.location_on),
                        Text(' 주소 : ', style: TextStyle(fontSize: 17.0, fontWeight: FontWeight.w800)),
                            Text("${trackDetailInfo!.lnmAddr}",style: TextStyle(fontSize: 17.0)),
                          ]),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.route_outlined),
                        Text(' 경로  ', style: TextStyle(fontSize: 17.0,
                            fontWeight: FontWeight.w800))
                          ]
                        ),
                        Text("${trackDetailInfo!.coursDc}", style: TextStyle(fontSize: 17.0)),
                        SizedBox(height: 10), // 각 항목 사이의 간격
                        Row(
                          children: [
                            Icon(Icons.info, size: 22),
                          Text(' 설명 ', style: TextStyle(fontSize: 17.0, fontWeight: FontWeight.w800))
                          ]
                        ),
                            Text('${trackDetailInfo!.aditDc}', style: TextStyle(fontSize: 17.0)),
                            SizedBox(height: 10),
                        Row(
                            children : [
                              Icon(Icons.terrain, size: 22.0),
                              SizedBox(width: 8.0),
                              Expanded(
                                child:Text('${trackDetailInfo!.coursLevelNm} ',
                                    style: TextStyle(fontSize: 17.0),
                                ),
                              ),
                              Icon(Icons.directions, size: 22.0),
                              SizedBox(width: 10),
                              Expanded(child:
                              Text('${trackDetailInfo!.coursDetailLtCn}km ',
                                style: TextStyle(fontSize: 17.0),
                              ),
                              ),
                              Icon(Icons.timer, size: 22.0),
                              SizedBox(width: 10),
                              Expanded(child:
                              Text('${trackDetailInfo!.coursTimeCn} ',
                                  style: TextStyle(fontSize: 17.0)
                              ),
                              ),
                              SizedBox(height: 10),
                            ]
                        ),
                        Divider(thickness: 1.0),
                        Text("편의시설 정보",
                          style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w900),
                          ),
                        SizedBox(height: 10),
                        Row(children: [
                          Icon(Icons.local_drink, size: 22),
                        Text(' 식수대 ', style: TextStyle(fontSize: 17.0, fontWeight: FontWeight.w500))
                        ],),
                        Text('${trackDetailInfo!.optnDc}', style: TextStyle(fontSize: 14)),
                        SizedBox(height: 10),
                        Row(children: [
                          Icon(Icons.wc, size: 22),
                        Text(' 화장실 ', style: TextStyle(fontSize: 17.0, fontWeight: FontWeight.w500))
                        ],),
                        Text('${trackDetailInfo!.toiletDc}', style: TextStyle(fontSize: 14)),
                        SizedBox(height: 10),
                        Row(children: [
                          Icon(Icons.store, size: 22),
                        Text(' 매점 ', style: TextStyle(fontSize: 17.0, fontWeight: FontWeight.w500))
                        ],),
                        Text('${trackDetailInfo!.cvntlNm}', style: TextStyle(fontSize: 14)),
                        ],
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
                                trackDetailInfo?.averageScore != null ? '별점 ${trackDetailInfo!.averageScore.toStringAsFixed(1)}' : '', // 별점 평균 표시 또는 빈칸
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
                      color: Colors.black,
                      thickness: 1.0,
                    ),
                    Column(
                      children: [
                        if (_isLoading)
                          Center(child: CircularProgressIndicator()),
                        if (!_isLoading)
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: _comments.length,
                            itemBuilder: (context, index) {
                              Comment comment = _comments[index];

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
                                        ),
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
                                    trailing: (comment.author.email == email)
                                        ? IconButton(
                                      icon: Icon(Icons.edit),
                                      onPressed: () => _editComment(comment, index),
                                    )
                                        : null,
                                  ),
                                  if (index < _comments.length - 1)
                                    Divider(
                                      color: Colors.black,
                                      thickness: 0.1,
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
                                  vertical: 5.0, horizontal: 10.0),
                            ),
                            style: TextStyle(fontSize: 16.0),
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

class DetailTrack {
  String wlkCoursFlagNm;
  String wlkCoursNm;
  String coursDc;
  String signguNm;
  String coursLevelNm;
  String coursLtCn;
  String coursDetailLtCn;
  String aditDc;
  String coursTimeCn;
  String optnDc;
  String toiletDc;
  String cvntlNm;
  String lnmAddr;
  int commentCount;
  double averageScore;
  List<Comment> comments;

  DetailTrack({
    required this.wlkCoursFlagNm,
    required this.wlkCoursNm,
    required this.coursDc,
    required this.signguNm,
    required this.coursLevelNm,
    required this.coursLtCn,
    required this.coursDetailLtCn,
    required this.aditDc,
    required this.coursTimeCn,
    required this.optnDc,
    required this.toiletDc,
    required this.cvntlNm,
    required this.lnmAddr,
    required this.comments,
    required this.commentCount,
    required this.averageScore
  });

  factory DetailTrack.fromJson(Map<String, dynamic> json) {
    var commentsFromJson = json['comments'] as List;
    List<Comment> commentsList = commentsFromJson.map((commentJson) => Comment.fromJson(commentJson)).toList();
    return DetailTrack(
      wlkCoursFlagNm: json['wlkCoursFlagNm'] ?? '',
      wlkCoursNm: json['wlkCoursNm'] ?? '',
      coursDc: json['coursDc'] ?? '',
      signguNm: json['signguNm'] ?? '',
      coursLevelNm: json['coursLevelNm'] ?? '',
      coursLtCn: json['coursLtCn'] ?? '',
      coursDetailLtCn: json['coursDetailLtCn'] ?? '',
      aditDc: json['aditDc'] ?? '',
      coursTimeCn: json['coursTimeCn'],
      optnDc: json['optnDc'] ?? '',
      toiletDc: json['toiletDc'] ?? '',
      cvntlNm: json['cvntlNm'] ?? '',
      lnmAddr: json['lnmAddr'] ?? '',
      commentCount: json['commentCount'] ?? 0,
      averageScore: json['averageScore'] ?? 0.0,
      comments: commentsList,
    );
  }
}