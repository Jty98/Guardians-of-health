import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:guardians_of_health_project/Components/Numberpad/first_numberpad_view.dart';
import 'package:guardians_of_health_project/VM/security_ctrl.dart';
import 'package:guardians_of_health_project/home.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:guardians_of_health_project/my_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SecurityController securityController = Get.put(SecurityController());

  MyTheme myTheme = MyTheme();

  // 생체인증 status shared로 불러오기
  securityController.biometricsValue.value = await getisPrivatedState();
  // password status와 password shared로 불러와서 배열에 저장
  final initPw = await getisPasswordState();
  securityController.passwordValue.value =
      initPw[0]; // 0번째에 있는 passwordStatus 가져와서 넣어주기
  securityController.savedPassword = initPw[1]; // 1번째에 있는 password 값 넣어주기
  // print("init_isFirstRun: ${securityController.isFirstValue}");

  // 생체인식 스위치 켜져있으면 생체인증
  if (securityController.biometricsValue.value == true) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      securityController.authenticate(Get.context!, 0);
    });
    // 첫 실행시 obs로 관리하는 밸류를 true로 바꿔서 테마 변경 및 빌드시 setState 될때 인증 뜨는거 막기
  }

  // 테마 정보 가져오기
  final themeInfo = await myTheme.getThemeInfo();
  final bool isDarkMode = themeInfo[0];
  final int themeColor = themeInfo[1];

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(MyApp(isDarkMode, themeColor));
}

class MyApp extends StatefulWidget {
  final bool isDarkMode;
  final int themeColor;
  const MyApp(this.isDarkMode, this.themeColor, {Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  final securityController = Get.find<SecurityController>();
  late ThemeMode _themeMode;
  late Color _seedColor;
  bool _hasInitialized = false; // 초기화 여부를 확인하는 플래그

  @override
  void initState() {
    super.initState();
    _themeMode = widget.isDarkMode ? ThemeMode.dark : ThemeMode.light;
    _seedColor = widget.themeColor == 0
        ? const Color.fromARGB(255, 247, 251, 243)
        : widget.themeColor == 1
            ? Colors.red
            : widget.themeColor == 2
                ? Colors.yellow
                : widget.themeColor == 3
                    ? Colors.green
                    : widget.themeColor == 4
                        ? Colors.blue
                        : Colors.purple;
    if (!_hasInitialized) {
      _hasInitialized = true; // 초기화가 되었다고 플래그를 업데이트
      _initializeApp();
    }
  }

  changeThemeMode(ThemeMode themeMode) {
    _themeMode = themeMode; // home page에서 버튼을 누르면 역으로 올라와 여기서 색상을 바꿔줌.
    setState(() {});
  }

  changeSeedColor(Color getSeedColor) {
    _seedColor = getSeedColor;
    setState(() {});
  }

  _initializeApp() {
    if (securityController.passwordValue.value == true) {
      // MyWidgets의 Build가 끝난 후 실행 (이렇게 안하면 순서상 오류가 생겨서 localizationsDelegates에서 오류남)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        firstNumberpadDialog(Get.context!);
      });
      // 첫 실행시 obs로 관리하는 밸류를 true로 바꿔서 테마 변경 및 빌드시 setState 될때 인증 뜨는거 막기
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      // 기기별 Layout 조절
      designSize: const Size(430, 932), // IPhone 14 & 15 ProMax 기기 해상도
      builder: (context, child) {
        return GetMaterialApp(
          title: 'Flutter Demo',
          // Localization
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // Theme 세팅
          themeMode: _themeMode,
          darkTheme: modeDarkTheme(),
          theme: modeLightTheme(),
          // MediaQuery에 화면 배율을 1배로 고정해서 확대해서 깨지는일 없게하기
          builder: (context, child) {
            return MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.0)),
                child: child!);
          },
          // isAuthenticating이 진행중이면 true
          home: Obx(() {
            if (securityController.biometricsValue.value == true) {
              return securityController.isAuthenticating.value
                  ? Container(color: Colors.black)
                  : Home(
                      onChangeTheme: changeThemeMode,
                      onChangeThemeColor: changeSeedColor);
            } else {
              return Home(
                  onChangeTheme: changeThemeMode,
                  onChangeThemeColor: changeSeedColor);
            }
          }),
          // const Home(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }

  ThemeData modeDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorSchemeSeed: _seedColor,
      fontFamily: "omyu-pretty",
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary, // 기본 색상
          foregroundColor:
              Theme.of(context).colorScheme.onSecondary, // 텍스트 및 아이콘 색상
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6), // 모서리 둥글기 설정
          ),
        ),
      ),
    );
  }

  ThemeData modeLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorSchemeSeed: _seedColor,
      fontFamily: "omyu-pretty",
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.secondary, // 기본 색상
          foregroundColor:
              Theme.of(context).colorScheme.onSecondary, // 텍스트 및 아이콘 색상
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6), // 모서리 둥글기 설정
          ),
        ),
      ),
    );
  }
} // End

/// sharedPreferences 써서 비밀번호 등록 되어있으면 가져오고 아니면 말기
Future<List> getisPasswordState() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List passwordList = [];
  bool isPasswordValue = prefs.getBool('isPassword') ?? false;
  String password = prefs.getString('password') ?? "";
  // debugPrint("password 등록 여부: $isPasswordValue");
  // debugPrint("로그인된 password: $password");
  passwordList.add(isPasswordValue);
  passwordList.add(password);

  return passwordList;
}

/// sharedPreferences 써서 생체 등록 되어있으면 가져오고 아니면 말기
getisPrivatedState() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isBioValue = prefs.getBool('isBio') ?? false;
  // debugPrint("생체인식 등록 여부: $isBioValue");
  return isBioValue;
}

