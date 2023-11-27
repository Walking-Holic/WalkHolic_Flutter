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



class HomeScreen extends StatefulWidget {

  final String title;

  static String route() => '/home';

  const HomeScreen({super.key, required this.title});

  @override
  State<StatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final datas = homePopularProducts;

  late KakaoMapController mapController; // callback 처리를 위한 controller

  Set<Marker> markers = {}; // 마커 변수
  Location location = new Location(); // 위치 받아오는 라이브러리
  // double lat = 0.0;
  // double lng = 0.0;
  List<LocationData> locations = [];
  _locateMe() async {
    try {
      markers.clear();
      setState(() {
        for (LocationData locationData in locations) {
          double lat = locationData.latitude!;
          double lng = locationData.longitude!;

          markers.add(Marker(
            markerId: UniqueKey().toString(),
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
  Future<void> fetchData() async {
    final String url = 'https://apis.data.go.kr/6270000/dgInParkwalk/getDgWalkParkList?serviceKey=4uIiQhsuu0bQtrHxzleNU7xH03OmYqOniRoZfNlzyZuuppsvQecRiGnTmJ47qdA3270X%2BkKD3fg4L6W%2FGUNKkw%3D%3D'
      +'&pageNo=1'
      +'&numOfRows=1000'
      +'&type=json'
      +'&lat=35.8714354'
      +'&lot=128.601445'
      +'&radius=1';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // "body" 아래의 "items"에서 "item" 배열을 가져오기
        final List<dynamic> items = data['body']['items']['item'];

        // 각 아이템에서 "id", "lat", 그리고 "lot" 값을 출력
        for (var item in items) {
          int id = item['id'];
          String parkNm = item['parkNm'];
          double lat = double.parse(item['lat']);
          double lng = double.parse(item['lot']);
          locations.add(LocationData.fromMap({
            "id": id,
            "parkNm" : parkNm,
            "latitude": lat,
            "longitude": lng,
          }));



          print('ID: $id, Latitude: $lat, Longitude: $lng');
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
  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.fromLTRB(24, 24, 24, 0);
    Size size = MediaQuery.of(context).size;


    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          const SliverPadding(
            padding: EdgeInsets.only(top: 24),
            sliver: SliverAppBar(
              pinned: true,
              automaticallyImplyLeading: false,
              flexibleSpace: HomeAppBar(),
            ),
          ),
          /*SliverPadding(
            padding: padding,
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                ((context, index) => _buildBody(context)),
                childCount: 1,
              ),
            ),
          ),*/
          // SliverPadding(
          //   padding: padding,
          //   sliver: _buildPopulars(),
          // ),
          SliverPadding(
            padding: EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(

              child: Container(
                height : 520,
              child : Column(
                children: [
                  Expanded(
                    child: KakaoMap(
                      onMapCreated: ((controller) {
                        mapController = controller;
                        setState(() {
                          markers.add(Marker(
                            markerId: UniqueKey().toString(),
                            latLng: LatLng(35.8714354, 128.601445),
                            width: 30,
                            height: 44,
                            offsetX: 15,
                            offsetY: 44,
                          ));
                          mapController.setCenter(LatLng(35.8714354, 128.601445));
                        });
                      }),
                      markers: markers.toList(),
                      center: LatLng(637.3608681, 126.930650), // 초기 값 (카카오)
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      child: Text("주변 산책로 검색"),
                      onPressed: () => fetchData(),
                    ),
                  ),
                ],
              ),
              ),
            ),
          ),
        


          //const SliverAppBar(flexibleSpace: SizedBox(height: 24)),

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

