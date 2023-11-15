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
                height : 550,
              child : Column(
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
                      child: Text("내 위치"),
                      onPressed: () => _locateMe(),
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

