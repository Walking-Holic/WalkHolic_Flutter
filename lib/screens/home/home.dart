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

const String kakaoMapKey = 'c7f0222c04ff0b7bb1656cf815b683d2';

class HomeScreen extends StatefulWidget {
  final String title;

  static String route() => '/home';

  const HomeScreen({super.key, required this.title});

  @override
  State<StatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final datas = homePopularProducts;

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
              child: GestureDetector(
                onTap: () {
                  print("SliverPadding 클릭됨!");
                  // 여기에 원하는 동작을 추가하세요.
                },
                child: Container(
                  height: 200,
                  color: Colors.blue,
                  child: Center(
                    child: Text("클릭 가능한 영역"),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: Expanded(
                child: KakaoMap(
                  onMapCreated: ((controller) {
                    /*mapController = controller;*/
                    setState(() {});
                  }),
                  /*markers: markers.toList(),*/
                  center: LatLng(37.3608681, 126.9306506), // 초기 값 (카카오)
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
