import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:location/location.dart' as loc;
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';

const String kakaoMapKey = 'c7f0222c04ff0b7bb1656cf815b683d2';
const String KakaoRestApi = '	a0120cb04bb109d4e2a6ad0a2ea8f24d';


class KakaoMapTest extends StatefulWidget {
  @override
  _KakaoMapTestState createState() => _KakaoMapTestState();
}

class _KakaoMapTestState extends State<KakaoMapTest> {
  late KakaoMapController mapController; // callback 처리를 위한 controller

  Set<Marker> markers = {}; // 마커 변수
  loc.Location location = loc.Location(); // 위치 받아오는 라이브러리
  Set<Polyline> polylines = {};
  Set<LatLng> points = {};
  double lat = 0.0;
  double lng = 0.0;

  LatLng? _startPoint;
  LatLng? _endPoint;

  _locateMe() async {
    try {
       loc.LocationData res = await location.getLocation(); // 현재 위치 받아옴
       print("Location Data: $res");
      markers.clear();
      polylines.clear();
      points.clear();
      _startPoint = null;
      _endPoint =  null;
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
         mapController.setCenter(LatLng(lat,lng)); //현재 위도, 경도로 center 이동
       });
    } catch (e) {
      print("Error locating: $e");
    }
    // print("내비 실행");
    // if (await NaviApi.instance.isKakaoNaviInstalled()) {
    //   // 카카오내비 앱으로 목적지 공유하기, WGS84 좌표계 사용
    //   await NaviApi.instance.shareDestination(
    //     destination:
    //     Location(name: '카카오 판교오피스', x: '127.108640', y: '37.402111'),
    //     // 좌표계 지정
    //     option: NaviOption(coordType: CoordType.wgs84),
    //   );
    // } else {
    //   // 카카오내비 설치 페이지로 이동
    //   launchBrowserTab(Uri.parse(NaviApi.webNaviInstall));
    // }
  }

  _submit() async {
    print("폴리라인 출력");
    List<Map<String, dynamic>> coordinates = [];
    int sequence = 1;

    for (LatLng point in points) {
      print('  LatLng(${point.latitude}, ${point.longitude})');

      // 각 위치에 대한 정보를 Map으로 추가
      coordinates.add({
        "sequence": sequence++,
        "latitude": point.latitude,
        "longitude": point.longitude,
      });
    }

    // JSON 형태로 변환
    String jsonCoordinates = jsonEncode({"coordinates": coordinates});
    print(jsonCoordinates);
    Navigator.pop(context, coordinates);
    // 위도와 경도 세트로 points에 저장되어 있음.
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 경로 찍어보기')),
      body: Column(
        children: [
          Expanded(
            child: KakaoMap(
              onMapCreated: ((controller) async {
                mapController = controller;

                // Fetch the user's current location
                loc.LocationData currentLocation = await location.getLocation();

                // Update state to reflect the new location and marker
                setState(() {
                  lat = currentLocation.latitude!;
                  lng = currentLocation.longitude!;
                  LatLng userLocation = LatLng(lat, lng);

                  // Set the map center to the user's location
                  mapController.setCenter(userLocation);

                  // Add a marker at the user's location
                  markers.add(Marker(
                    markerId: markers.length.toString(),
                    latLng: userLocation,
                    width: 30,
                    height: 44,
                    offsetX: 15,
                    offsetY: 44,
                    // You can add a custom marker image source if you want
                    markerImageSrc: 'https://w7.pngwing.com/pngs/96/889/png-transparent-marker-map-interesting-places-the-location-on-the-map-the-location-of-the-thumbnail.png',
                  ));
                });
              }),

              onMapTap: (LatLng point) {
                setState(() {
                  if (_startPoint == null) {
                    _startPoint = point;
                    markers.add(Marker(
                      markerId: 'startMarker',
                      latLng: point,
                      width: 30,
                      height: 44,
                      offsetX: 15,
                      offsetY: 44,
                    ),
                    );
                    points.add(_startPoint!);
                  } else {
                    _endPoint = point;
                    markers.add(Marker(
                      markerId: 'endMarker',
                      latLng: point,
                      width: 30,
                      height: 44,
                      offsetX: 15,
                      offsetY: 44,
                    ),
                    );
                    polylines.add(Polyline(
                      polylineId: 'polyline${polylines.length}',
                      points: [_startPoint!, _endPoint!],
                      strokeColor: Colors.blue,
                      strokeOpacity: 1,
                      strokeWidth: 10,
                      strokeStyle: StrokeStyle.solid,
                    ),
                    );
                    points.add(_endPoint!);

                    // 다음 경로를 위해 시작 지점 업데이트
                    _startPoint = _endPoint;
                  }
                });
              },
              markers: markers.toList(),
              polylines: polylines.toList(),
              center: LatLng(37.5665, 126.9780),
            ),
          ),
          Container(
            width: double.infinity,
            child: ElevatedButton(
              child: Text("다시 찍기"),
              onPressed: () => _locateMe(),
            ),
          ),
          Container(
            width: double.infinity,
            child: ElevatedButton(
              child: Text("제출하기"),
              onPressed: () => _submit(),
            ),
          ),
        ],
      ),
    );
  }
}
