import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:location/location.dart';

const String kakaoMapKey = 'c7f0222c04ff0b7bb1656cf815b683d2';

void main() {
  AuthRepository.initialize(appKey: kakaoMapKey);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KaKao Map',
      home: KakaoMapTest(),
    );
  }
}

class KakaoMapTest extends StatefulWidget {
  @override
  _KakaoMapTestState createState() => _KakaoMapTestState();
}


class _KakaoMapTestState extends State<KakaoMapTest> {
  late KakaoMapController mapController; // callback 처리를 위한 controller

  Set<Marker> markers = {}; // 마커 변수
  Location location = new Location(); // 위치 받아오는 라이브러리
  double lat = 0.0;
  double lng = 0.0;

  _locateMe() async {
    try {
      LocationData res = await location.getLocation(); // 현재 위치 받아옴
      //print("Location Data: $res");
      setState(() {
        lat = res.latitude!;
        lng = res.longitude!;
        markers.add(Marker(
          markerId: UniqueKey().toString(),
          latLng: LatLng(lat, lng),
          width: 30,
          height: 44,
          offsetX: 15,
          offsetY: 44,
          markerImageSrc:
          'https://w7.pngwing.com/pngs/96/889/png-transparent-marker-map-interesting-places-the-location-on-the-map-the-location-of-the-thumbnail.png',
        ));
        //print("Markers: $markers");
        mapController.setCenter(LatLng(lat, lng)); //현재 위도, 경도로 center 이동
      });
    } catch (e) {
      print("Error locating: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter KakaoMap example')),
      body: Column(
        children: [
          Expanded(
            child: KakaoMap(
              onMapCreated: ((controller) {
                mapController = controller;
                setState(() {});
              }),
              markers: markers.toList(),
              center: LatLng(637.3608681, 126.930650), // 초기 값 (카카오)
            ),
          ),
          Container(
            width: double.infinity,
            child: ElevatedButton(
              child: Text("Locate Me"),
              onPressed: () => _locateMe(),
            ),
          ),
        ],
      ),
    );
  }
}