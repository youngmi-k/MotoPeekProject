import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CarDetailView extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> carData;
  final List<Map<String, dynamic>> colors;
  final List<Map<String, dynamic>> new_model_details;
  final List<Map<String, dynamic>> used_model_details;
  final List<Map<String, dynamic>> rent_model_details;
  final List<Map<String, dynamic>> lease_model_details;
  final List<Map<String, dynamic>> maintenance_data;
  final List<Map<String, dynamic>> reviews;
  final List<Map<String, dynamic>> video_data;
  final TabController tabController;

  CarDetailView({
    required this.docId,
    required this.carData,
    required this.colors,
    required this.new_model_details,
    required this.used_model_details,
    required this.rent_model_details,
    required this.lease_model_details,
    required this.maintenance_data,
    required this.reviews,
    required this.video_data,
    required this.tabController
  });

  @override
  _CarDetailViewState createState() => _CarDetailViewState();
}

class _CarDetailViewState extends State<CarDetailView> {
  late int selectedColorIndex;
  late String carImageUrl;
  late List<String> colorNames;
  late List<String> colorImages;
  late List<Color> colorOptions;
  late List<Map<String, dynamic>> sortedMaintenanceData;
  bool isWish = false; // 위시리스트 체크 여부 상태

  @override
  void initState() {
    super.initState();
    colorNames = widget.colors.map((doc) => doc['color'] as String).toList();
    colorImages = widget.colors.map((doc) => doc['image_url'] as String).toList();
    colorOptions = widget.colors.map((doc) {
      try {
        return Color(int.parse(doc['color_code']));
      } catch (e) {
        return Colors.grey; // color_code 변환 시 오류 발생 시 기본 색상을 사용
      }
    }).toList();
    selectedColorIndex = 0;
    carImageUrl = colorImages.isNotEmpty ? colorImages[0] : ''; // 첫 번째 색상의 이미지를 기본값으로 사용
    //정렬된 유지비 데이터
    sortedMaintenanceData = [
      ...widget.maintenance_data.where((data) => data['type'] == "총 예상 유지비"),
      ...widget.maintenance_data.where((data) => data['type'] != "총 예상 유지비"),
    ];
    _fetchWishStatus(); // 초기 wish 상태 가져오기
  }

  // Firebase에서 현재 wish 상태를 가져옴
  Future<void> _fetchWishStatus() async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('cars')
        .doc(widget.docId)
        .get();

    if (snapshot.exists) {
      setState(() {
        isWish = snapshot['wish'] ?? false; // wish 필드 값 가져오기
      });
    }
  }

  // wish 상태 변경 함수
  Future<void> _toggleWish() async {
    try {
      await FirebaseFirestore.instance
          .collection('cars')
          .doc(widget.docId)
          .update({'wish': !isWish}); // wish 값을 반전
      setState(() {
        isWish = !isWish; // UI 업데이트
      });
    } catch (e) {
      print("Failed to update wish: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final carName = widget.carData['make'] + " " + widget.carData['name'];
    final priceRange = widget.carData['price_range'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: null,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              isWish ? Icons.favorite : Icons.favorite_border, // 상태에 따라 아이콘 변경
              color: isWish ? Colors.red : Colors.grey, // 상태에 따라 색상 변경
            ),
            onPressed: _toggleWish, // 버튼 클릭 시 상태 변경 함수 호출
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 차량 이름과 가격대
              Text(carName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(priceRange, style: TextStyle(fontSize: 20, color: Colors.red, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),

              // 차량 이미지
              Center(
                child: Image.network(
                  carImageUrl, // 첫 번째 색상의 이미지를 기본값으로 사용
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 5),

              // 차량 외장 컬러 이름
              Center(
                child: Text(
                  colorNames[selectedColorIndex],
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              SizedBox(height: 16),

              // 색상 옵션
              Container(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: colorOptions.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedColorIndex = index;
                          carImageUrl = colorImages[index]; // 선택된 색상에 맞는 이미지로 변경
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selectedColorIndex == index ? Colors.blue : Colors.transparent,
                              width: 2, // 테두리 두께 설정
                            ),
                          ),
                          child: CircleAvatar(
                            backgroundColor: colorOptions[index],
                            radius: 20,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20),

              // TabBar
              TabBar(
                controller: widget.tabController,
                labelColor: Colors.red,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.red,
                tabs: [
                  Tab(text: '시세'),
                  Tab(text: '유지비'),
                  Tab(text: '리뷰'),
                  Tab(text: '영상'),
                ],
              ),
              SizedBox(height: 16),

              // TabBarView
              Container(
                height: 400,
                child: TabBarView(
                  controller: widget.tabController,
                  children: [
                    // 첫 번째 탭 내용 (차량 모델별 시세)
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 신차 모델별 시세 카드
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child:
                            Text(
                              '| 신차 시세',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(height: 8),
                          Column(
                            children: widget.new_model_details.map((model) {
                              return Card(
                                color: Colors.grey.shade50,
                                elevation: 1,
                                margin: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // 모델명
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            model['model'],
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            model['release'],
                                            style: TextStyle(fontSize: 13, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          // 가격
                                          Text.rich(
                                            TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: '${model['price']}',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: '만원',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey, // '만원' 글씨 색상 회색으로 변경
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          SizedBox(height: 16),

                          // 중고차 모델별 시세 카드
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child:
                            Text(
                              '| 중고차 시세',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(height: 8),
                          Column(
                            children: widget.used_model_details.map((model) {
                              return Card(
                                color: Colors.grey.shade50,
                                elevation: 1,
                                margin: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // 모델명
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            model['model'],
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            model['release'],
                                            style: TextStyle(fontSize: 13, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          // 가격
                                          Text.rich(
                                            TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: '${model['price']}',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: '만원',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey, // '만원' 글씨 색상 회색으로 변경
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          SizedBox(height: 16),

                          // 렌트 모델별 시세 카드
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child:
                            Text(
                              '| 렌트 시세',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(height: 8),
                          Column(
                            children: widget.rent_model_details.map((model) {
                              return Card(
                                color: Colors.grey.shade50,
                                elevation: 1,
                                margin: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // 모델명
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            model['model'],
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            model['release'],
                                            style: TextStyle(fontSize: 13, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          // 가격
                                          Text.rich(
                                            TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: '월 ',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey, // '만원' 글씨 색상 회색으로 변경
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: '${model['price']}',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: '원',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey, // '만원' 글씨 색상 회색으로 변경
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          SizedBox(height: 16),

                          // 리스 모델별 시세 카드
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child:
                            Text(
                              '| 리스 시세',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(height: 8),
                          Column(
                            children: widget.lease_model_details.map((model) {
                              return Card(
                                color: Colors.grey.shade50,
                                elevation: 1,
                                margin: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // 모델명
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            model['model'],
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            model['release'],
                                            style: TextStyle(fontSize: 13, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          // 가격
                                          Text.rich(
                                            TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: '월 ',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey, // '만원' 글씨 색상 회색으로 변경
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: '${model['price']}',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: '원',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey, // '만원' 글씨 색상 회색으로 변경
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),


                    // 두 번째 탭 내용 (유지비)
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: sortedMaintenanceData.asMap().entries.map((entry) {
                              int index = entry.key;
                              var data = entry.value;

                              return Container(
                                decoration: index == 0
                                    ? BoxDecoration(
                                  border: Border.all(
                                    color: Colors.red, // 테두리 색상
                                    width: 1.0, // 테두리 두께
                                  ),
                                  borderRadius: BorderRadius.circular(8.0), // 테두리 모서리 둥글게
                                )
                                    : null, // index가 0이 아닐 때는 테두리를 설정하지 않음
                                child: Card(
                                  //color: index != 0 ? Colors.white : Colors.grey.shade50, // 첫 번째 데이터만 회색 배경
                                  //elevation: index != 0 ? 0 : 1, // 첫 번째 데이터만 elevation 설정
                                  color: Colors.white,
                                  elevation: 0,
                                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              data['type'] ?? '',
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              data['description'] ?? '',
                                              style: TextStyle(fontSize: 13, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          data['value'] ?? '',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: index == 0 ? FontWeight.bold : null,
                                            //fontWeight: FontWeight.bold,
                                            color: index == 0 ? Colors.red : Colors.blue, // 첫 번째 데이터만 빨간색
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),


                    // 세 번째 탭 내용 (리뷰)
                    ListView(
                      padding: EdgeInsets.all(0.0),
                      children: widget.reviews.map((review) => buildReviewCard(review)).toList(),
                    ),


                    // 네 번째 탭 내용 (영상)
                    SingleChildScrollView(
                      child: Column(
                        children: widget.video_data.map((data) {
                          String videoId = data['videoId'] ?? '';
                          String thumbnailUrl = getThumbnailUrl(videoId);

                          return GestureDetector(
                            onTap: () {
                            },
                            child: Card(
                              color: Colors.white,
                              elevation: 0,
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12.0),
                                        child: Image.network(
                                          thumbnailUrl,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: 200,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[300],
                                              height: 200,
                                              child: Center(child: Icon(Icons.error)),
                                            );
                                          },
                                        ),
                                      ),
                                      Positioned.fill(
                                        child: Align(
                                          alignment: Alignment.center,
                                          child: Icon(
                                            //Icons.play_circle_outline,
                                            Icons.play_circle,
                                            color: Colors.red,
                                            size: 70.0,  // 아이콘 크기
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['title'] ?? '',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          '${data['channel']} • ${data['date']}',
                                          style: TextStyle(fontSize: 13, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 영상 탭에서 유튜브 썸네일 구하는 메소드
  String getThumbnailUrl(String videoId) {
    return 'https://img.youtube.com/vi/$videoId/0.jpg';
  }

  // 리뷰 탭 ui 구성 메소드
  Widget buildReviewCard(Map<String, dynamic> review) {
    List<String> images = [review['imageUrl_1'], review['imageUrl_2'], review['imageUrl_3']];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Card(
        color: Colors.white,
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 사용자 정보
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    review['user'],
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: () {
                      // 자세히 보기 버튼
                    },
                    child: Text(
                      '리뷰 보기 >',
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),

              // 컬러 옵션 및 별점
              Row(
                children: [
                  // 컬러 옵션 텍스트
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      review['colorOption'],
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                    ),
                  ),
                  SizedBox(width: 10),
                  // 별점
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: null,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(Icons.star_border, color: Colors.yellow.shade800, size: 18), // 테두리 별
                            Icon(Icons.star, color: Colors.yellow.shade800, size: 16), // 채워진 별
                          ],
                        ),
                        Text(
                          ' ${review['rating']}',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              SizedBox(height: 12),

              // 리뷰 이미지
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  childAspectRatio: 1,
                ),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      images[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
