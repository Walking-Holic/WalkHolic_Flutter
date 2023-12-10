import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fresh_store_ui/model/rank_image.dart';
import 'package:fresh_store_ui/screens/board/board_detail.dart';
import 'package:fresh_store_ui/screens/board/board_track.dart';
import 'package:fresh_store_ui/screens/home/hearder.dart';
import 'package:fresh_store_ui/screens/track/pomodoros.dart';
import 'package:fresh_store_ui/screens/track/track_search.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:location/location.dart';
import 'package:fresh_store_ui/constants.dart';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
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

  Track? trackInfo; // 현재 게시글의 상세 정보를 저장할 변수
  DetailTrack? trackDetailInfo;
  double _rating = 3; // 초기 별점 값
  Uint8List? profileImage;
  String? nickname;
  String? email;
  int? id;
  String? rank;


  final storage = FlutterSecureStorage();
  bool _isLoading = false;

  List<Track> locations = [];
  late KakaoMapController mapController; // callback 처리를 위한 controller
  Set<Marker> markers = {}; // 마커 변수
  Location location = new Location(); // 위치 받아오는 라이브러리
  Map<String, dynamic> markerInfoMap = {};


  @override
  void initState() {
    super.initState();
    _loadUserProfile();
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

 Widget _buildBody(Track? track) {
    return Expanded(
      child: KakaoMap(
        onMapCreated: (controller) {
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
              markerImageSrc: 'https://images-ext-1.discordapp.net/external/FGNH5mBQok1YI_g1tzJ-XzezhTtTlZZqm2i6xALLJXE/https/t1.daumcdn.net/localimg/localimages/07/mapapidoc/markerStar.png?format=webp&quality=lossless',
            ));
            fetchData(35.8714354,128.601445,10, updateMarkers: true);
            mapController.setCenter(LatLng(35.8714354, 128.601445));
          });
        },
        markers: markers.toList(),
        onMarkerTap: onMarkerTap, // 마커 탭 이벤트 핸들러 추가
        center: LatLng(637.3608681, 126.930650),
      ),
    );
  }

  Future<void> fetchDataForInfo(int id) async {
    try {
      String? accessToken = await storage.read(key: 'accessToken');
      Dio dio = Dio();
      Response response = await dio.get(
        '$IP_address/api/trail/$id',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        print("수행2");
        setState(() {
          trackInfo = Track.fromJson(response.data);
        });
      } else {
        // 에러 처리
        print('Failed to fetch track info: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> fetchData(double lat, double lng, double distance, {bool updateMarkers = true}) async {
    try {
      String? accessToken = await storage.read(key: 'accessToken');
      Dio dio = Dio();
      Response response = await dio.get(
        '$IP_address/api/trail/main?latitude=${lat}&longitude=${lng}&distance=${distance}',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      print("실행");
      print(response.statusCode);
      print(response);

      if (response.statusCode == 200) {
        final List<dynamic> items = response.data;
        locations = items.map((item) => Track.fromJson(item)).toList();

        setState(() {
          trackInfo = Track.fromJson(items.first);
        });
        print("trackInfo: $trackInfo");

        if (updateMarkers) {
          await _locateMe(locations);
        }
      } else {
        print("Failed to load data. Status code: ${response.statusCode}");
      }
    } catch (e) {
      // 네트워크 오류 또는 기타 오류 처리
      print("Error fetching data: $e");
    }
  }

  _locateMe(List<Track> locations) async {
    try {
      setState(() {
        for (Track locationData in locations) {
          String markerId = locationData.id.toString();
          double lat = locationData.coursSpotLa;
          double lng = locationData.coursSpotLo;

          String name = locationData.wlkCoursNm;

          print("마커 $markerId번");
          print("위도 : $lat");
          print("경도 : $lng");
          print("이름 : $name");

          Map<String, dynamic> markerInfo = {
            "id": markerId,
            "lat": lat,
            "lng": lng,
            "name": name
          };

          markerInfoMap[markerId] = markerInfo;

          Marker marker = Marker(
            markerId: markerId,
            latLng: LatLng(lat, lng),
            width: 30,
            height: 44,
            offsetX: 15,
            offsetY: 44,
          );
          markers.add(marker);
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

  void onMarkerTap(String markerId, LatLng latLng, int zoomLevel) async {
    Map<String, dynamic>? markerInfo = markerInfoMap[markerId];
    if (markerInfo != null) {
      int id = int.tryParse(markerInfo['id'].toString()) ?? 0;
      String name = markerInfo['name'] ?? '';

      if (name == "(사용자 설정 게시글)" && id != 0) {
        // 사용자 설정 경로일 경우
        await _getIndividualTrack(id);
      } else if (id != 0) {
        // 사용자 설정 경로가 아니면서 유효한 ID가 있을 경우
        await fetchDataForInfo(id);
      }

      // 대화 상자를 보여주는 부분
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return _buildInfo(id, trackInfo!); // trackInfo를 파라미터로 전달
        },
      );
    }
  }


  Future<void> _getIndividualTrack(int id) async {
    String url = '$IP_address/api/path/$id';

    try {
      String? accessToken = await storage.read(key: 'accessToken');
      Dio dio = Dio();
      Response response = await dio.get(
        url,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      if (response.statusCode == 200) {
        var responseData = response.data;
        trackInfo = Track(
          id: responseData['id'] ?? 0,
          wlkCoursFlagNm: responseData['title'] ?? '',
          wlkCoursNm: "(사용자 설정 게시글)", // wlkCoursNm에도 title 값을 사용
          averageScore: responseData['averageScore']?.toDouble() ?? 0.0,
          commentCount: 0, // commentCount는 기본값으로 설정
          coursSpotLa: 0.0, // coursSpotLa는 기본값 또는 임의의 값으로 설정
          coursSpotLo: 0.0, // coursSpotLo는 기본값 또는 임의의 값으로 설정
        );
        print("수행");
      }
    } catch (e) {
      print('Error fetching individual track: $e');
    }
  }
  // 마커 추가 함수
  void _addMarker(Track track) {
    // 마커 추가 로직
    Marker marker = Marker(
      markerId: track.id.toString(),
      latLng: LatLng(track.coursSpotLa, track.coursSpotLo),
      width: 30,
      height: 44,
      offsetX: 15,
      offsetY: 44,
    );
    markers.add(marker);
  }


  Widget _buildInfo(int id, Track track) {
    // markerInfoMap에서 id에 해당하는 마커 정보를 가져옵니다.
    Map<String, dynamic>? markerInfo = markerInfoMap[id.toString()];
    if (markerInfo == null) {
      print("오류");
      return Center(child: Text("마커 정보를 찾을 수 없습니다."));
    }
    double? lat = markerInfo['lat'] as double?;
    double? lng = markerInfo['lng'] as double ?;
    print(lat);
    print(lng);

    if (lat == null || lng == null) {
      // lat 또는 lng가 null일 경우, 함수를 더 이상 실행하지 않고 오류 메시지를 반환합니다.
      print("오류: 위도 또는 경도 정보가 없습니다. ID: $id");
      return Center(child: Text("위치 정보를 찾을 수 없습니다."));
    }
      return Padding(
        padding: EdgeInsets.only(bottom: 70.0),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: 350,
            height: 200,
            decoration: BoxDecoration(
              color: Color(0xFFF4EDDB),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Column(
                  children: [
                    SizedBox(height: 15),
                    Text(
                      '${trackInfo!.wlkCoursFlagNm}',
                      style: TextStyle(fontSize: 25.0, fontWeight: FontWeight.w900),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    Row(children:
                    [
                      SizedBox(width: 100),
                      Icon(Icons.star, color: Colors.amber),
                    SizedBox(width: 10),
                    Text(
                      '${trackInfo!.averageScore.toStringAsFixed(1)}',
                      style: TextStyle(fontSize: 25.0),
                      textAlign: TextAlign.center,
                    ),
                      SizedBox(width: 30),
                      Icon(Icons.chat),
                      SizedBox(width: 10),
                      Text(
                        '${trackInfo!.commentCount}',
                        style: TextStyle(fontSize: 25.0),
                        textAlign: TextAlign.center,
                      ),
                      ]
                    ),
                    SizedBox(height: 30),
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
                          '세부 정보 보기',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20.0
                          ),
                        ),
                        onPressed: () {
                          if(trackInfo!.wlkCoursNm == "(사용자 설정 게시글)"){
                            Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (context) => PostDetailsScreen(id: id)));
                          } else
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => TrackDetail(id: id)));
                        },
                      ),
                    ),
                  ],
                ),
            ),
          ),
        );
    }

  Widget _buildPlayButton() {
  return Align(
    alignment: Alignment.bottomCenter,
    child: IconButton(
      iconSize: 80,
      icon: Image.asset('$kIconPath/play2.png'),
      onPressed: () {
        Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PedometerAndStopwatchUI())
        );
      },
    ),
  );
}

  Widget _buildSearchButton() {
    return Padding(
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
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => SearchTrack()));
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBody(trackInfo),
          _buildPlayButton(),
          _buildSearchButton(),
        ],
      ),
    );
  }
}

class Track {
  int id;
  String wlkCoursFlagNm;
  String wlkCoursNm;
  double averageScore;
  int commentCount;
  double coursSpotLa;
  double coursSpotLo;

  Track({
    required this.id,
    required this.wlkCoursFlagNm,
    required this.wlkCoursNm,
    required this.averageScore,
    required this.commentCount,
    required this.coursSpotLa,
    required this.coursSpotLo,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
    id: json['id'] ?? 0,
    wlkCoursFlagNm: json['wlkCoursFlagNm'] ?? '',
    wlkCoursNm: json['wlkCoursNm'] ?? '',
    averageScore: json['averageScore'] ?? 0.0,
    commentCount: json['commentCount'] ?? 0,
    coursSpotLa: json['coursSpotLa'] ?? 0.0,
    coursSpotLo: json['coursSpotLo'] ?? 0.0);
  }
}

class Locate {
  int id;
  double coursSpotLa;
  double coursSpotLo;

  Locate({
    required this.id,
    required this.coursSpotLa,
    required this.coursSpotLo,
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
      id: json['id'] as int,
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
