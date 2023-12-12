import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:location/location.dart' as loc;
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';

const String kakaoMapKey = 'c7f0222c04ff0b7bb1656cf815b683d2';
const String KakaoRestApi = '	a0120cb04bb109d4e2a6ad0a2ea8f24d';


class NewKakaoMapTest extends StatefulWidget {
  final List<Map<String, dynamic>> coordinates; // 경로 정보가 저장된 배열

  NewKakaoMapTest({Key? key, required this.coordinates}) : super(key: key);

  @override
  _NewKakaoMapTestState createState() => _NewKakaoMapTestState();
}

class _NewKakaoMapTestState extends State<NewKakaoMapTest> {
  late KakaoMapController mapController;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  void _loadMarkers() async {
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      List<LatLng> polylinePoints = [];
      for (var i = 0; i < widget.coordinates.length; i++) {
        var coordinate = widget.coordinates[i];
        double lat = coordinate['latitude'];
        double lng = coordinate['longitude'];

        // 첫 번째와 마지막 좌표에만 마커를 추가
        if (i == 0 || i == widget.coordinates.length - 1) {
          String markerImageSrc;
          String data = '';

          if (i == 0) {
            markerImageSrc = 'https://images-ext-1.discordapp.net/external/Fci0xx0t7a_rB5vEyljIyKoxNxkuvmM1lzltbndxXVY/https/t1.daumcdn.net/localimg/localimages/07/mapapidoc/red_b.png?format=webp&quality=lossless';
            data = "출발";
          } else {
            markerImageSrc = 'https://images-ext-2.discordapp.net/external/KG-ZxumaqxAwKA1fjxeKjfBecseQUzCvxu0Q-UfJ_8c/http/i1.daumcdn.net/localimg/localimages/07/mapapidoc/blue_b.png?format=webp&quality=lossless';
            data = "도착";
          }

          Marker marker = Marker(
            markerId: i.toString(),
            latLng: LatLng(lat, lng),
            width: 30,
            height: 44,
            offsetX: 15,
            offsetY: 44,
            markerImageSrc: markerImageSrc,
          );

          markers.add(marker);
        }

        // 모든 좌표를 폴리라인 점으로 추가
        polylinePoints.add(LatLng(lat, lng));
      }

      // 폴리라인 생성
      if (polylinePoints.length > 1) {
        polylines.add(Polyline(
          polylineId: 'route',
          points: polylinePoints,
          strokeColor: Colors.green,
          strokeOpacity: 5,
          strokeWidth: 5,
          strokeStyle: StrokeStyle.solid,
        ));
      }
    });
  }

  void _centerMap() {
      LatLng? firstLocation;

      for (var coordinate in widget.coordinates) {
        if (coordinate['sequence'] == 1) {
          double lat = coordinate['latitude'];
          double lng = coordinate['longitude'];
          firstLocation = LatLng(lat, lng);
          mapController.setCenter(firstLocation);
          break; // 첫 번째 위치를 찾았으므로 반복문 종료
        }
      }

      if (firstLocation == null) {
        firstLocation = LatLng(37.5665, 126.9780); // 기본 위치 설정
        mapController.setCenter(firstLocation);
      }
    }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, // AppBar 배경을 투명하게 설정
        elevation: 0, // 그림자 제거
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black), // 뒤로가기 버튼 아이콘
          onPressed: () {
            Navigator.of(context).pop(); // 현재 화면을 스택에서 제거하여 뒤로 가기
          },
        ),
        centerTitle: true, // 제목을 중앙에 배치
        title: Text(
          "작성자의 경로",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: KakaoMap(
        onMapCreated: (controller) {
          mapController = controller;
          _centerMap(); // 첫 번째 마커 위치를 초기 위치로 설정
          if (markers.isNotEmpty) {
            // 첫 번째 마커 위치를 지도의 중심으로 설정
            mapController.setCenter(markers.first.latLng);
          }
        },
        markers: markers.toList(),
        polylines: polylines.toList(),
      ),
    );
  }
}