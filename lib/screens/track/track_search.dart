import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fresh_store_ui/constants.dart';
import 'package:fresh_store_ui/screens/board/board_track.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SearchTrack extends StatefulWidget {
  @override
  _SearchTrackState createState() => _SearchTrackState();
}

class _SearchTrackState extends State<SearchTrack> {
  final TextEditingController _searchController = TextEditingController();
  int? _selectedDifficultyOption; // 선택된 옵션의 인덱스를 저장할 변수
  int? _selectedLengthOption;
  bool _isFilterVisible = false; // 필터 옵션의 보임/숨김 상태
  List<WalkRoute> _searchResults = [];
  final storage = FlutterSecureStorage();
  int _currentPage = 0;
  bool _isFetching = false; // 데이터 로딩 중인지 여부
  final ScrollController _scrollController = ScrollController(); // 스크롤 컨트롤러
  bool _isLastPage = false; // 새로운 상태 변수 추가

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreData(); // 스크롤이 맨 아래에 도달하면 추가 데이터 로드
    }
  }

  Future<void> _loadMoreData() async {
    if (_isFetching) return;

    setState(() {
      _isFetching = true;
    });

    await _performSearch(); // 데이터 로드

    setState(() {
      _currentPage++; // 페이지 번호 증가
      _isFetching = false;
    });
  }

  Future<void> _performSearch() async {
    // API의 Base URL
    final String baseUrl = '$IP_address/api/trail/search';

    // 쿼리 파라미터 구성
    Map<String, String> queryParams = {
      'lnmAddr': _searchController.text,
      'coursLevelNm': _selectedDifficultyOption != null
          ? _difficultyOptions[_selectedDifficultyOption!]
          : '',
      'coursLtCn': _selectedLengthOption != null
          ? _lengthOptions[_selectedLengthOption!]
          : '',
      'page': _currentPage.toString(),
      'size': '10',
    };
    print(_currentPage);
    // 쿼리 스트링 생성
    String queryString = Uri(queryParameters: queryParams).query;

    // 최종 요청 URL
    final Uri requestUrl = Uri.parse('$baseUrl?$queryString');

    try {
      String? accessToken = await storage.read(key: 'accessToken');
      // HTTP GET 요청 실행
      final response = await http.get(
        requestUrl,
        headers: {
          'Authorization': 'Bearer $accessToken', // 토큰을 헤더에 포함
        },
      );
      print("실행");
      print(response.statusCode);
      print(response.body);
      if (response.statusCode == 200) {


        // 서버로부터 받은 JSON 데이터 파싱
        String responseBody = utf8.decode(response.bodyBytes);
        List<dynamic> jsonResponse = json.decode(responseBody);
        List<WalkRoute> newSearchResults =
            jsonResponse.map((data) => WalkRoute.fromJson(data)).toList();

        bool newIsLastPage = newSearchResults.isEmpty;

        setState(() {
          if (_currentPage == 0) {
            _searchResults = newSearchResults; // 새 검색 시 리스트 초기화
          } else {
            _searchResults.addAll(newSearchResults); // 추가 데이터 로드
          }
          _isLastPage = newIsLastPage; // 마지막 페이지 상태 업데이트
        });
      } else {
        // 에러 처리
        throw Exception('Failed to load data');
      }
    } catch (e) {
      // 예외 처리
      print('Error: $e');
    }
  }

  void startNewSearch() {
    setState(() {
      _currentPage = 0; // 새 검색을 시작하기 전에 페이지 번호를 0으로 설정
      _searchResults.clear(); // 이전 검색 결과를 지움
    });
    _performSearch(); // 새 검색 수행
  }

  List<WalkRoute> getFilteredWalkRoutes() {
    return walkRoutes.where((route) {
      final locationMatches = _searchController.text.isEmpty ||
          route.signgu_nm.contains(_searchController.text);
      final difficultyMatches = _selectedDifficultyOption == null ||
          route.coursLevelNm == _difficultyOptions[_selectedDifficultyOption!];
      final lengthMatches = _selectedLengthOption == null ||
          route.coursLtCn == _lengthOptions[_selectedLengthOption!];

      return locationMatches && difficultyMatches && lengthMatches;
    }).toList();
  }

  final List<WalkRoute> walkRoutes = [
    // 추가 데이터...
  ];

  final List<String> _difficultyOptions = [
    '매우쉬움',
    '쉬움',
    '보통',
    '어려움',
    '매우어려움',
  ];

  final List<String> _lengthOptions = [
    '1KM미만',
    '1~5KM미만',
    '5~10KM미만',
    '10~15KM미만',
    '15~20KM미만',
    '20~100KM미만'
  ];

  Widget _buildFilterOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                '난이도',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                '${_selectedDifficultyOption != null ? 1 : 0}/1',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        Wrap(
          children: _difficultyOptions.asMap().entries.map((entry) {
            int idx = entry.key;
            String val = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: FilterButton(
                text: val,
                isSelected: _selectedDifficultyOption == idx,
                onTap: () {
                  setState(() {
                    if (_selectedDifficultyOption == idx) {
                      _selectedDifficultyOption = null; // 선택 취소
                    } else {
                      _selectedDifficultyOption = idx; // 선택
                    }
                  });
                },
              ),
            );
          }).toList(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                '거리',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                '${_selectedLengthOption != null ? 1 : 0}/1',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        Wrap(
          children: _lengthOptions.asMap().entries.map((entry) {
            int idx = entry.key;
            String val = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: FilterButton(
                text: val,
                isSelected: _selectedLengthOption == idx,
                onTap: () {
                  setState(() {
                    if (_selectedLengthOption == idx) {
                      _selectedLengthOption = null; // 선택 취소
                    } else {
                      _selectedLengthOption = idx; // 선택
                    }
                  });
                },
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '시/군/구 를 입력하세요',
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.search),
                        onPressed: () {
                          startNewSearch();
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.filter_list),
                        onPressed: () {
                          setState(() {
                            _isFilterVisible = !_isFilterVisible; // 필터 상태 토글
                          });
                        },
                      ),
                    ],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: Container(), // 필터 옵션이 숨겨진 상태
              secondChild: _buildFilterOptions(), // 필터 옵션들을 보여주는 메소드
              crossFadeState: _isFilterVisible
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: Duration(milliseconds: 300), // 애니메이션 지속 시간
            ),
            // 여기에 검색 결과를 표시하는 위젯을 추가하세요
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _isFetching ? _searchResults.length + 1 : _searchResults.length,
                itemBuilder: (context, index) {
                  if (index < _searchResults.length) {
                    final route = _searchResults[index];
                    return Padding(
                      padding: EdgeInsets.only(top: 7.0),
                        child: InkWell( // InkWell로 각 항목을 감싸서 클릭 가능하게 만듭니다.
                          onTap: () {
                            // 클릭 시 TrackDetail 페이지로 이동하며 id를 파라미터로 전달합니다.
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => TrackDetail(id: route.id),
                            ));
                          },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 1,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              title:
                              Text('${route.signgu_nm} ${route.wlkCoursFlagNm}',
                              style: TextStyle(
                                fontSize: 20
                              ),),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(route.wlkCoursNm,
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600)),
                                SizedBox(height: 8.0),
                                  Row(
                                    children: [
                                      SizedBox(width: 8.0),
                                      Expanded(
                                        child: Text(
                                          '${route.coursLevelNm}',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 15),
                                        ),
                                      ),
                                      Icon(Icons.circle, size: 10.0),
                                      // 아이콘은 Expanded로 감싸지 않음
                                      Expanded(
                                        child: Text(
                                          '${route.coursDetailLtCn}km',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 15),
                                        ),
                                      ),
                                      Icon(Icons.circle, size: 10.0),
                                      // 아이콘은 Expanded로 감싸지 않음
                                      Expanded(
                                        child: Text(
                                          '${route.coursTimeCn}',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 15),
                                        ),
                                      ),
                                      SizedBox(width: 8.0),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    );
                  }else if (_isLastPage) {
                    // 마지막 페이지 메시지 표시
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text("마지막 페이지 입니다",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }
                  else {
                    // 로딩 인디케이터 표시
                    return Padding(
                      padding: EdgeInsets.only(top: 20.0, bottom: 20.0),
                      child: Center(child: CircularProgressIndicator(color: Colors.black)),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchResults.clear();
    super.dispose();
  }
}

class FilterButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterButton({
    Key? key,
    required this.text,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.black : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.0),
        ),
      ),
      onPressed: onTap,
      child: Text(
        text,
        style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            // 선택된 경우 하얀색, 아닐 경우 검정색
            fontSize: 12,
            fontWeight: FontWeight.w400 // 글자 크기 지정
            ),
      ),
    );
  }
}

class WalkRoute {
  final int id;
  final String signgu_nm;
  final String wlkCoursFlagNm;
  final String wlkCoursNm;
  final String coursLevelNm;
  final String coursLtCn;
  final String coursDetailLtCn;
  final String coursTimeCn;
  final double averageScore;
  final int commentCount;

  WalkRoute(
      {required this.id,
      required this.signgu_nm,
      required this.wlkCoursFlagNm,
      required this.wlkCoursNm,
      required this.coursLevelNm,
        required this.coursLtCn,
        required this.coursDetailLtCn,
      required this.coursTimeCn,
      required this.averageScore,
      required this.commentCount});

  factory WalkRoute.fromJson(Map<String, dynamic> json) {
    return WalkRoute(
        id: json['id'] ?? 0,
        signgu_nm: json['signgu_nm'] ?? '',
        wlkCoursFlagNm: json['wlkCoursFlagNm'] ?? '',
        wlkCoursNm: json['wlkCoursNm'] ?? '',
        coursLtCn: json['coursLtCn'] ?? '',
        coursLevelNm: json['coursLevelNm'] ?? '',
        coursDetailLtCn: json['coursDetailLtCn'] ?? '',
        coursTimeCn: json['coursTimeCn'] ?? '',
        averageScore: json['averageScore'] ?? 0.0,
        commentCount: json['commentCount'] ?? 0);
  }
}
