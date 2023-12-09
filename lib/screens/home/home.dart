import 'package:flutter/material.dart';
import 'package:fresh_store_ui/components/product_card.dart';
import 'package:fresh_store_ui/model/popular.dart';
import 'package:fresh_store_ui/screens/detail/detail_screen.dart';
import 'package:fresh_store_ui/screens/home/hearder.dart';
import 'package:fresh_store_ui/screens/home/most_popular.dart';
import 'package:fresh_store_ui/screens/mostpopular/most_popular_screen.dart';
import 'package:fresh_store_ui/screens/special_offers/special_offers_screen.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fresh_store_ui/constants.dart';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fresh_store_ui/model/rank_image.dart';
import 'package:fresh_store_ui/main.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:fresh_store_ui/constants.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class HomeScreen extends StatefulWidget {

  final String title;

  static String route() => '/home';

  const HomeScreen({super.key, required this.title});

  @override
  State<StatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _commentController = TextEditingController();
  List<Comment> _comments = [];
  DetailPost? postDetail; // 현재 게시글의 상세 정보를 저장할 변수
  double _rating = 3; // 초기 별점 값
  Uint8List? profileImage_;
  String? nickname_;
  String? email;
  int? id;
  String? rank_;
  final storage = FlutterSecureStorage();
  bool _isLoading = false;

  late final datas = homePopularProducts;

  late KakaoMapController mapController; // callback 처리를 위한 controller

  Set<Marker> markers = {}; // 마커 변수

  Location location = new Location(); // 위치 받아오는 라이브러리
  // double lat = 0.0;
  // double lng = 0.0;
  List<ParkLocation> locations = [];
  Map<String, Map<String, dynamic>> markerInfoMap = {};



  List<dynamic> excelData = [];

  Future<List<String>> _loadFile(int id) async {
    ByteData data = await rootBundle.load('assets/KC_CFR_WLK_STRET_INFO_2021.xlsx');
    Uint8List bytes = data.buffer.asUint8List();
    var excel = Excel.decodeBytes(bytes);

    var table = excel.tables['Worksheet']!;
    List<List<dynamic>> excelTable = [];

    // for (var row in table.rows) {
    //   excelTable.add(row);
    // }
    print(id);
    var selectedRow = table.rows[id];
    List<String> rowDataValues = selectedRow.map((cell) => cell?.value.toString() ?? '').toList();

    // If you want to print the content of each cell, you can do it here
    // print(rowDataValues[1]);
    // print(selectedRow);
    print(rowDataValues);
    print('\n=====================================================\n');
    return rowDataValues;
  }




  _locateMe() async {
    try {

      setState(() {
        for (ParkLocation locationData in locations) {
          String markerId = UniqueKey().toString();
          double lat = locationData.latitude!;
          double lng = locationData.longitude!;

          Map<String, dynamic> markerInfo = {
            "id": locationData.id!,
            "lat": locationData.latitude!,
            "lng": locationData.longitude!,
          };

          markerInfoMap[markerId] = markerInfo;

          markers.add(Marker(
            markerId: markerId,
            latLng: LatLng(lat, lng),
            width: 30,
            height: 44,
            offsetX: 15,
            offsetY: 44,

          ));
        }

        // 새로운 마커를 추가한 후에도 기존 마커를 그대로 유지
        if (markers.isNotEmpty) {
          // 지도의 중심을 첫 번째 마커의 위치로 설정
          mapController.setCenter(LatLng(35.8714354, 128.601445));
        }
      });
    } catch (e) {
      print("위치 찾기 오류: $e");
    }
  }


  Future<void> fetchData2() async {

    try {
      final storage = FlutterSecureStorage();
      String? accessToken = await storage.read(key: 'accessToken');
      Dio dio = Dio();
      Response response = await dio.get(
        '$IP_address/api/trail/main?latitude=35.8714354&longitude=128.601445&distance=2.0',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      print("실행1");
      print(response.statusCode);

      print(response);
      if (response.statusCode == 200) {
        final List<dynamic> items = response.data;
        for (var item in items)
          {
            int id = item['id'];
            String Nm = item['wlkCoursNm'];
            double latitude = item['coursSpotLa'];
            double longitude = item['coursSpotLo'];
            locations.add(ParkLocation(
              id : id,
              Nm : Nm,
              latitude : latitude,
              longitude : longitude
            ));
          }
          _locateMe();
      } else {
        print("Failed to load data. Status code: ${response.statusCode}");
      }
    }
    catch(e) {
      // 네트워크 오류 또는 기타 오류 처리
      print("Error fetching data: $e");
    }
  }



  Future<Map<String, dynamic>?>? _userProfileFuture;

  Uint8List? profileImage;
  String? nickname;
  String? rank;

  @override
  void initState() {
    super.initState();
    _userProfileFuture = _loadUserProfile();
  }

  Future<Map<String, dynamic>?> _loadUserProfile() async {
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
        return response.data;
      } else {
        // 에러 처리
        print('Failed to load user profile: ${response.statusCode}');
      }
    } catch (e) {
      // 예외 처리
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Stack(
        children: [
          HomeAppBar(),
          Expanded(
            child: KakaoMap(
              onMapCreated: ((controller) {
                mapController = controller;
                setState(() {
                  markers.clear();
                  markers.add(Marker(
                    markerId: UniqueKey().toString(),
                    latLng: LatLng(35.8714354, 128.601445),
                    width: 30,
                    height: 44,
                    offsetX: 15,
                    offsetY: 44,
                    markerImageSrc:
                    'https://w7.pngwing.com/pngs/131/387/png-transparent-red-map-marker-icon-computer-icons-google-map-maker-world-map-map-marker-map-travel-world-red-thumbnail.png',
                  ));
                  fetchData2();
                  mapController.setCenter(LatLng(35.8714354, 128.601445));
                });
              }),
              markers: markers.toList(),
              onMarkerTap: (markerId, latLng, zoomLevel) {
                // List<String> Wlk_Data = await _loadFile(2);
                Map<String, dynamic>? info = markerInfoMap[markerId];

                if (info != null) {
                  print("------------------------------------");
                  print(info['id']);
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return Padding(
                          padding: EdgeInsets.only(bottom: 70.0),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: 350,
                              height: 230,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              child : FutureBuilder<List<String>>(
                                future: _loadFile(info['id']),
                                builder: (context, snapshot) {
                                  List<String> rowDataValues = snapshot.data ?? [];

                                  String Wlk_nm = rowDataValues[1];
                                  return Column(
                                    children: [
                                      Text('\n$Wlk_nm',
                                        style: TextStyle(fontSize: 25.0),
                                        textAlign: TextAlign.center,
                                      ),
                                      Container(
                                        width: 270,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius: BorderRadius.circular(10.0),
                                        ),
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            elevation: 0,
                                          ),
                                          child: Text(
                                            '자세히 보기',
                                            style: TextStyle(color: Colors.white, fontSize: 20.0),
                                          ),
                                          onPressed: () {
                                            Navigator.of(context).pushReplacement(
                                              MaterialPageRoute(
                                                  builder: (context) => Scaffold(
                                                      appBar: AppBar(
                                                        title: const Text('산책로 정보'),
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
                                                          child: FutureBuilder<List<String>>(
                                                            future: _loadFile(info['id']),
                                                            builder: (context, snapshot) {
                                                              List<String> rowDataValues = snapshot.data ?? [];

                                                              String Wlk_nm = rowDataValues[1];
                                                              String course = rowDataValues[3];
                                                              String location = rowDataValues[13];
                                                              String level = rowDataValues[5];
                                                              String distance = rowDataValues[7];
                                                              String time = rowDataValues[9];
                                                              String information = rowDataValues[8];
                                                              String water = rowDataValues[10];
                                                              String toilet = rowDataValues[11];
                                                              String market = rowDataValues[12];

                                                              print(rowDataValues);
                                                              return Column(
                                                                children: [
                                                                  Text('\n- $Wlk_nm -',
                                                                    style: TextStyle(fontSize: 30.0),
                                                                    textAlign: TextAlign.center,
                                                                  ),
                                                                  Text(
                                                                    '\n경로 : $course\n\n'
                                                                        '위치 : $location\n\n'
                                                                        '난이도 : $level\n\n'
                                                                        '코스길이 : ${distance}km\n\n'
                                                                        '소요시간 : $time\n\n'
                                                                        '산책로 설명:\n $information\n\n'
                                                                        '식수대 : $water\n\n'
                                                                        '화장실 :$toilet\n\n'
                                                                        '매점 : $market\n',
                                                                    style: TextStyle(fontSize: 17.0),
                                                                  ),
                                                                  Divider(
                                                                    color: Colors.black, // Divider 색상 설정
                                                                    thickness: 1.0, // Divider 두께 설정
                                                                  ),
                                                                  Padding(
                                                                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                                                                    child: RatingBar.builder(
                                                                      // initialRating: _rating,
                                                                      minRating: 1,
                                                                      direction: Axis.horizontal,
                                                                      allowHalfRating: false,
                                                                      itemCount: 5,
                                                                      itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                                                                      itemBuilder: (context, _) =>
                                                                          Icon(Icons.star, color: Colors.amber),
                                                                      onRatingUpdate: (rating) {
                                                                        setState(() {
                                                                          // _rating = rating;
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
                                                                          // controller: _commentController,
                                                                          decoration: InputDecoration(
                                                                            hintText: '후기와 별점을 남겨주세요!',
                                                                            border: OutlineInputBorder(),
                                                                            contentPadding: EdgeInsets.symmetric(
                                                                                vertical: 5.0, horizontal: 10.0), // 패딩 조절
                                                                          ),
                                                                          style: TextStyle(fontSize: 16.0), // 글꼴 크기 조절
                                                                        ),
                                                                      ),
                                                                      IconButton(
                                                                        icon: Icon(Icons.send),
                                                                        onPressed: () => {
                                                                          // _addComment(_commentController.text);
                                                                        },
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ],
                                                              );
                                                            },
                                                          ),

                                                      )


                                                  )
                                              )
                                                  )
                                              )
                                            );
                                          },

                                        ),

                                        ),


                                    ],
                                  );
                                },
                              )
                            ),
                          ),
                      );

                    },
                  );
                } else {

                }

              },
              center: LatLng(637.3608681, 126.930650), // 초기 값 (카카오)
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: IconButton(
              iconSize: 80,
              icon: Image.asset('$kIconPath/play2.png'),
              onPressed: () {},
            ),
          ),
      Padding(
        padding: EdgeInsets.only(top: 25.0),
        child: Container(
          width: 80,
          height: 60,
          decoration: BoxDecoration(
          // color: Colors.white,
        ),
          child: IconButton(
            iconSize: 35,
            icon: Image.asset('$kIconPath/pngegg.png'),
            onPressed: () {},
          ),
          // child: FutureBuilder<Map<String, dynamic>?>(
          //   future: _loadUserProfile(),
          //   builder: (context, snapshot) {
          //     if (snapshot.connectionState == ConnectionState.waiting) {
          //       return Center(child: CircularProgressIndicator());
          //     }
          //
          //     if (snapshot.hasError || !snapshot.hasData) {
          //       return Text("데이터 로드 실패");
          //     }
          //     var data = snapshot.data!;
          //     Uint8List imageBytes = base64.decode(data['profileImage']);
          //     String nickname = data['nickname'] ?? 'walkholic';
          //     String rank = data['rank'] ?? '';
          //
          //     return Padding(
          //       padding: const EdgeInsets.symmetric(horizontal: 12),
          //       child: Row(
          //         children: [
          //           // CircleAvatar(
          //           //   backgroundImage: MemoryImage(imageBytes),
          //           //   radius: 24,
          //           // ),
          //           // SizedBox(width: 16),
          //           // Expanded(
          //           //   child: Row(
          //           //     mainAxisSize: MainAxisSize.min,
          //           //     children: [
          //           //       Text(
          //           //         nickname,
          //           //         style: TextStyle(
          //           //           color: Color(0xFF212121),
          //           //           fontWeight: FontWeight.bold,
          //           //           fontSize: 20,
          //           //         ),
          //           //       ),
          //           //       SizedBox(width: 8), // 닉네임과 랭크 이미지 사이 간격
          //           //       RankImage.getRankImage(rank, width:40.0, height: 40.0),
          //           //     ],
          //           //   ),
          //           // ),
          //           // SizedBox(width: 16),
          //           IconButton(
          //             iconSize: 40,
          //             icon: Image.asset('$kIconPath/pngegg.png'),
          //             onPressed: () {},
          //           ),
          //         ],
          //       ),
          //     );
          //   },
          // ),
        )

      )

        ],
      ),

    );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      children: [
        // const SearchField(),
        const SizedBox(height: 24),
        //SpecialOffers(onTapSeeAll: () => _onTapSpecialOffersSeeAll(context)),
        const SizedBox(height: 24),
        //MostPopularTitle(onTapseeAll: () => _onTapMostPopularSeeAll(context)),
        const SizedBox(height: 24),
        const MostPupularCategory(),
      ],
    );
  }

  // Widget _buildPopulars() {
  //   return SliverGrid(
  //     gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
  //       maxCrossAxisExtent: 185,
  //       mainAxisSpacing: 24,
  //       crossAxisSpacing: 16,
  //       mainAxisExtent: 285,
  //     ),
  //     delegate: SliverChildBuilderDelegate(_buildPopularItem, childCount: 30),
  //   );
  // }

  Widget _buildPopularItem(BuildContext context, int index) {
    final data = datas[index % datas.length];
    return ProductCard(
      data: data,
      ontap: (data) => Navigator.pushNamed(context, ShopDetailScreen.route()),
    );
  }

  void _onTapMostPopularSeeAll(BuildContext context) {
    Navigator.pushNamed(context, MostPopularScreen.route());
  }

  void _onTapSpecialOffersSeeAll(BuildContext context) {
    Navigator.pushNamed(context, SpecialOfferScreen.route());
  }
}

class ParkLocation {
  final int id;
  final String Nm;
  final double latitude;
  final double longitude;

  ParkLocation({
    required this.id,
    required this.Nm,
    required this.latitude,
    required this.longitude,
  });
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