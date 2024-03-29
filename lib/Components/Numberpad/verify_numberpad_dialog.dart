/*
  기능: 비밀번호 설정시 비밀번호확인용 다이얼로그
*/

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:guardians_of_health_project/VM/security_ctrl.dart';

/// 비밀번호 사용을 활성화하면 띄워지는 다이어로그
void verifyNumberpadDialog(BuildContext context) {
  final securityController = Get.find<SecurityController>();

  /// keypad 안에 들어갈 버튼 리스트 설정하는 함수
  List<dynamic> setKeypadShape() {
    List<dynamic> keypadList = [];
    List<dynamic> dynamicKeyList = ["", 0, ""];

    for (int i = 1; i <= 12; i++) {
      if (i > 9) {
        keypadList.add(dynamicKeyList[i - 10]);
      } else {
        keypadList.add(i);
      }
    }

    return keypadList;
  }

  /// 비밀번호 확인이 틀렸을 때 띄우는 스낵바
  showSnackbar(
      {required String result,
      required String resultText,
      required Color resultbackColor,
      required Color resultTextColor}) {
    Get.showSnackbar(
      GetSnackBar(
        titleText: Text(
          result,
          style: TextStyle(
              color: resultTextColor,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        messageText: Text(
          resultText,
          style: TextStyle(
              color: resultTextColor,
              fontSize: 15.sp,
              fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        duration: const Duration(milliseconds: 800),
        backgroundColor: resultbackColor,
        snackPosition: SnackPosition.TOP,
        borderRadius: 50.r, // 둥글게하기
        margin: EdgeInsets.fromLTRB(60.w, 10.h, 60.w, 10.h), // 마진값으로 사이즈 조절
      ),
    );
    securityController.verifyPadNum = "".obs; // 비밀번호 확인 리스트 초기화
  }

  /// 비밀번호 확인하는 함수
  bool saveNumber() {
    bool status = false;
    if (securityController.tempPadNum == securityController.verifyPadNum.value) {
      // SQLite에 비밀번호 저장 및 비밀번호 사용 스위치 status 값 저장
      // 저장 후 저장 성공했다고 띄워주기위해 true
      securityController.savedPassword = securityController.verifyPadNum.value;
      securityController.savePwSharePreferencese();
      print("savedPassword: ${securityController.savedPassword}");
      status = true;
    } else {
      status = false;
    }
    return status;
  }

  Future<void> dialogFuture = showDialog(
    barrierDismissible: true,
    context: context,
    builder: (context) {
      return AlertDialog(
          title: const Center(
            child: Text(
              "비밀번호 확인",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          content: SizedBox(
            width: 450.w,
            height: 620.h,
            child: Center(
              child: Column(
                children: [
                  Obx(
                    () => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        showNumber(securityController, 1, context),
                        showNumber(securityController, 2, context),
                        showNumber(securityController, 3, context),
                        showNumber(securityController, 4, context),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          // 문자열의 뒤에서 한 글자 제거
                          if (securityController.verifyPadNum.value.isNotEmpty) {
                            securityController.verifyPadNum.value =
                                securityController.verifyPadNum.value.substring(
                                    0,
                                    securityController
                                            .verifyPadNum.value.length -
                                        1);
                          }
                        },
                        child: Icon(
                          Icons.backspace_outlined,
                          color: Theme.of(context).colorScheme.tertiary,
                          size: 30.h,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 10.h,
                  ),
                  Expanded(
                    child: GridView.builder(
                      itemCount: setKeypadShape().length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                      ),
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (BuildContext context, int index) {
                        return GestureDetector(
                          onTap: () {
                            // index값에 true넣어주기
                            securityController.buttonClickStatus[index].value =
                                true;

                            // 키패드의 index를 padNum에 추가시키기
                            securityController.verifyPadNum.value +=
                                setKeypadShape()[index].toString();

                            if (securityController.verifyPadNum.value.length ==
                                4) {
                              // verifyNumber에서 true return해주면 성공했다고 띄워주기
                              if (saveNumber() == true) {
                                securityController.saveStatus = true;
                                // 바로 삭제할수도 있어서 또 불러와서 id 조회
                                // securityController.initPasswordValue();
                                Get.back();
                                showSnackbar(
                                  result: "저장 성공",
                                  resultText: "비밀번호가 성공적으로 설정되었습니다.",
                                  resultbackColor:
                                      Theme.of(context).colorScheme.tertiary,
                                  resultTextColor:
                                      Theme.of(context).colorScheme.onTertiary,
                                );
                              } else {
                                showSnackbar(
                                  result: "저장 실패",
                                  resultText: "비밀번호가 일치하지 않습니다.",
                                  resultbackColor:
                                      Theme.of(context).colorScheme.error,
                                  resultTextColor:
                                      Theme.of(context).colorScheme.onError,
                                );
                              }
                            }

                            // 2초 뒤에 false 넣어줘서 원상복구하기
                            Timer(const Duration(milliseconds: 200), () {
                              securityController.buttonClickStatus[index].value =
                                  false;
                            });
                          },
                          child: Obx(
                            () => AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              decoration: BoxDecoration(
                                color: securityController
                                        .buttonClickStatus[index].value
                                    ? Colors.grey
                                    : Theme.of(context).colorScheme.tertiary,
                                borderRadius: BorderRadius.circular(100.r),
                              ),
                              child: Center(
                                child: Text(
                                  "${setKeypadShape()[index]}",
                                  style: TextStyle(
                                    fontSize: 40.sp,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onTertiary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ));
    },
  );
  // 다이얼로그가 닫힌 후의 로직
  dialogFuture.then((value) {
    // 다이얼로그가 닫힘을 확인하고 로직 수행
    if (securityController.saveStatus == true) {
      // 저장이 성공한 경우
      securityController.passwordValue.value = true;
      securityController.tempPadNum = "";
    } else {
      // 저장이 실패하거나 다이얼로그가 닫히지 않은 경우
      securityController.passwordValue.value = false;
      securityController.resetNumber();
      securityController.tempPadNum = "";
    }
  });
}

/// nuberPad 위에 버튼 누를 때 나오는 * 부분
Widget showNumber(SecurityController securityController, int valueLength,
    BuildContext context) {
  return Padding(
    padding: EdgeInsets.fromLTRB(5.w, 5.h, 5.w, 5.h),
    child: Container(
      width: 60.w,
      height: 60.h,
      color: Colors.blueGrey,
      child: Center(
          child: Text(
        securityController.verifyPadNum.value.length < valueLength ? "" : "*",
        style: TextStyle(fontSize: 35.sp),
        textAlign: TextAlign.center,
      )),
    ),
  );
}
