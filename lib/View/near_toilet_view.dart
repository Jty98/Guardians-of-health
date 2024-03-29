import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:guardians_of_health_project/Model/toilets_model.dart';
import 'package:latlong2/latlong.dart' as latlng; 
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';

class NearToiletView extends StatefulWidget {
  const NearToiletView({super.key});

  @override
  State<NearToiletView> createState() => _NearToiletViewState();
}

class _NearToiletViewState extends State<NearToiletView> {
  // property
  late Position currentPosition;

  late MapController mapController;
  late TextEditingController searchBarController;
  late bool canRun;
  late List location;

  late double mylat = 0.0;
  late double mylng = 0.0;


  @override
  void initState() {
    super.initState();
    mapController = MapController();
    searchBarController = TextEditingController();
    canRun = false;
    checkLocationPermission();      // 위치 권한 사용 동의 여부
    getToiletsJsonData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: getToiletsJsonData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            List<ToiletsModel> toilets = snapshot.data as List<ToiletsModel>;
            return Stack(
              children: [         
                // canRun
                //   ? flutterMap(toilets)
                //   : const Center(
                //     child: CircularProgressIndicator(),
                //   ),
                flutterMap(toilets),
                Positioned(
                  bottom: 100.h,
                  right: 20.w,
                  child: FloatingActionButton(
                    backgroundColor: Colors.blueGrey,     // seedColor에 맞춰 바꾸기
                    onPressed: (){
                      canRun? getCurrentLocation() : showCheckLocationModal();
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.r)
                    ),
                    child: const Icon(
                      Icons.location_searching_outlined
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget flutterMap(List<ToiletsModel> toilets){
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: latlng.LatLng(mylat, mylng),
        initialZoom: 17.0,
        maxZoom: 20,
        minZoom: 14,
      ), 
      children: [
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
        ),
        MarkerLayer(           // 전국 화장실 데이터 마커 찍기
          markers: toilets.map((toilets) {
            return Marker(    
              width: 120.w,
              height: 120.h,
              point: latlng.LatLng(toilets.x, toilets.y), 
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: (){
                      showModalBottomSheet(
                        context: context, 
                        builder: (context) {
                          return SizedBox(
                            height: 300.h,
                            width: 500.w,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(15.w, 15.h, 15.w, 15.h),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    toilets.name,
                                    style: TextStyle(
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.bold
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 8.h),
                                    child: Divider(height: 1.h, color: Colors.grey),
                                  ),
                                  Row(
                                    children: [
                                      const Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            "\n주소 : ",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            "\n개방시간 : ",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold
                                            ),                                            
                                          ),
                                          Text(
                                            "\n거리 : ",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold
                                            ),                                            
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("\n${toilets.address}"),
                                          Text("\n${toilets.openingHours}"),
                                          Text("\n${calcDistance(toilets.x, toilets.y)}"),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      );
                    },
                    child: Column(
                      children: [
                        Text(
                          toilets.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15.sp,
                          ),
                        ),
                        Icon(
                          Icons.location_pin,
                          size: 30.sp,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        MarkerLayer(          // 현재 내위치 데이터
          markers: [ 
            Marker(   
              width: 120.w,
              height: 120.h,
              point: latlng.LatLng(mylat, mylng), 
              child: Column(
                children: [
                  Text(
                    "내 위치",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20.sp
                    ),
                  ),
                  Icon(
                    Icons.location_pin,
                    size: 40.sp,
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ],
        )
      ],
    );
  }

  // ---------- functions ----------
  /// 위치 사용 권한 확인 
  checkLocationPermission() async{      // permission 받을때 까지 await를 통해 대기해야함. 사용자의 선택에 따라 활동이 정해지거나 대기해야 하면 무조건 async await
    LocationPermission permission = await Geolocator.checkPermission();     // 사용자의 허용을 받았는지 여부에 따라 조건문 작성
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      // getBasicLocation();
    }

    if (permission == LocationPermission.deniedForever) {
      canRun = false;
      showCheckLocationModal();
      getBasicLocation();
      // return;
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      canRun = true;
      getCurrentLocation();           // 허용하면 현재 위치 가져오는 함수 실행 
      showNoticeModal();
    }
  }

  /// 내 위치 불러오기
  getCurrentLocation() async{
    canRun ?    // 현재 위치 세팅하기
      await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        forceAndroidLocationManager: true).then((position) {
          currentPosition = position;
          mylat = currentPosition.latitude;
          mylng = currentPosition.longitude;
          setState(() {});
        }).catchError((e){
          debugPrint("지도파트 오류(near_toilet_view.dart) currentLocation : $e");
        })
      : await ( // 광화문 광장 위치 세팅하기
        // mylat = 37.572946136442916,
        // mylng = 126.97689874408849;
      );
  }

  /// 위치 권한 요청 거부시 초기 위치 설정 (광화문)
  getBasicLocation() async {
    await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
      forceAndroidLocationManager: true).then((position) {
        currentPosition = position;
        canRun = false;
        mylat = 37.572946136442916;
        mylng = 126.97689874408849;
        setState(() {});
      }).catchError((e){
        debugPrint("지도파트 오류(near_toilet_view.dart) BasicLocation : $e");
      });
  }

  /// 권한 설정 거부됐을 때 현재 위치의 화장실 알고 싶다면 위치 권한 허용해달라고 알림창 띄우기
  showCheckLocationModal() {
    showDialog(
      context: context, 
      builder: (context) {
        return AlertDialog(
          title: const Center(child: Text("위치 사용 권한 거부 알림")),
          content: SizedBox(
            height: 200.h,
            width: 500.w,
            child: const Column(
              children: [
                Text(
                  "위치 사용 권한이 허용되지 않았습니다. 현재 위치 근처의 화장실 정보를 보시려면 위치 사용 권한을 허용해 주세요.\n"
                ),
                Text(
                  "허용 방법 : 설정 > 개인정보 보호 및 보안 > 위치 서비스 > 골든타임"
                ),
              ],
            ),
          ),
          actions: [
            Center(
              child: TextButton(
                onPressed: (){
                  getBasicLocation();
                  Get.back();
                }, 
                child: const Text("확인"),
              ),
            )
          ],          
        );
      }
    );
  }

  /// 지도 탭 처음 들어왔을 때 보여줄 경고창
  showNoticeModal() {
    showDialog(
      context: context, 
      builder: (context) {
        return AlertDialog(
          title: const Center(child: Text("※ 알림 ※")),
          content: SingleChildScrollView(
            child: SizedBox(
              height: 250.h,
              width: 500.w,
              child: Column(
                children: [
                  Text(
                    "지도에 표시되는 화장실은 「공중화장실 등에 관한 법률」 등에 따라 국민의 위생상의 편의와 복지증진을 위해 공중이 이용하도록 국가, 지방자치단체, 법인 또는 개인이 설치하는 화장실에 대한 정보(지방자치단체 관리 대상 개방화장실, 공중화장실, 이동화장실 등 (포함), 초등학교, 중학교 등 학교 화장실은 제공범위(대상) 제외)에 의거하여 표시되었으며, \n",
                    style: TextStyle(
                      fontSize: 14.sp
                    ),
                  ),
                  Text(
                    "정보에 오류가 있거나 지도에 표시되지 않은 화장실이 존재할 수 있음에 양해 부탁드립니다.",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            Center(
              child: TextButton(
                onPressed: (){
                  Get.back();
                }, 
                child: const Text("확인"),
              ),
            )
          ],
        );
      },
    );
  }

  /// 전국 화장실 (toilets.json) 데이터 불러오기
  Future<List<ToiletsModel>> getToiletsJsonData() async {
    var routeFromJsonFile = await rootBundle.loadString('assets/json/toilets.json');
    List<dynamic> listFromJson = json.decode(routeFromJsonFile);
    return listFromJson.map((json) => ToiletsModel.fromMap(json)).toList();
  }

  /// 거리 계산
  calcDistance(double toiletX, double toiletY){
    // 두 지점 사이 거리 변수
    String betweenDistance = '';

    // 두 위치 사이 거리 계산
    double distanceInMeters = Geolocator.distanceBetween(
      mylat, 
      mylng, 
      toiletX, 
      toiletY,
    );

    // meter 거리가  1km 미만 -> m / 1km 이상 -> km 변환
    distanceInMeters < 1000 ? betweenDistance = "${distanceInMeters.round().toString()} m" : betweenDistance = "${(distanceInMeters.round()/1000).toString()} km";  
    
    return betweenDistance;
  }
  


}   // END