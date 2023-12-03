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
      for (var coordinate in widget.coordinates) {
        double lat = coordinate['latitude'];
        double lng = coordinate['longitude'];
        int sequence = coordinate['sequence'] ?? 0;

        Marker marker = Marker(
          markerId: sequence.toString(),
          latLng: LatLng(lat, lng),
          width: 30,
          height: 44,
          offsetX: 15,
          offsetY: 44,
          infoWindowContent: '작성자 경로 ${sequence.toString()}번 지점',
          infoWindowRemovable: false,
          infoWindowFirstShow: true,
        );

        markers.add(marker);
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
      appBar: AppBar(title:
      const Text('내 경로 찍어보기')),
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