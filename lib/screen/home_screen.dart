import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart';
import 'package:tts_script_converter/screen/result_screen.dart';
import 'package:flutter/src/painting/box_border.dart' as bd;

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Row(
          children: [
            IconTheme(
              data: IconThemeData(color: Colors.black),
              child: Icon(Icons.edit_note),
            ),
            SizedBox(
              width: 15,
            ),
            Text('TTS Script File Converter')
          ],
        ),
        backgroundColor: Colors.redAccent.withOpacity(0.6),
      ),
      body: Center(
        child: DragTarget(),
      ),
    );
  }
}

class DragTarget extends StatefulWidget {
  const DragTarget({Key? key}) : super(key: key);

  @override
  _DragTargetState createState() => _DragTargetState();
}

class _DragTargetState extends State<DragTarget> {
  GlobalKey<ScaffoldState> scaffoldkey = GlobalKey<ScaffoldState>();
  final List<XFile> _list = [];
  final List<String> filesList = [];
  final List<String> languageList = [];
  String referenceFile = '';
  late String language;
  bool _dragging = false;
  bool _onlyReferenceErrorAlert = false;
  Offset? offset;

  int count = 0;

  void initState() {
    print("안녕하세요 ^^");
    scaffoldkey = GlobalKey<ScaffoldState>();
    _list.clear();
    filesList.clear();
    languageList.clear();
    language = "";
    //getErrorReferenceBook();
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
        onDragDone: (detail) async {
          //debugPrint('onDragDone:');
          for (final file in detail.files) {
            count++;
            print("${count}번째 파일 ");
            print("${file.name}");

            filesList.add(file.path);
          }

          for (int i = 0; i < filesList.length; i++) {
            if (!filesList[i].contains(".xlsx")) {
              filesList.clear();
              _list.clear();

              break;
            } else if (filesList.length == 1 &&
                filesList[0].contains("Frequently_errors_Reference")) {
              filesList.clear();
              _list.clear();
              _onlyReferenceErrorAlert = true;
              break;
            } else {
              setState(() {
                _list.addAll(detail.files);
              });
            }
          }
          if (_list.isEmpty) {
            if (_onlyReferenceErrorAlert == true) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(failMessageSnackBar2());
              _onlyReferenceErrorAlert = false;
            } else {
              ScaffoldMessenger.of(context).showSnackBar(failMessageSnackBar());
            }
          }

          for (int i = 0; i < filesList.length; i++) {
            if (filesList[i].contains("Frequently_errors_Reference")) {
              referenceFile = '${filesList[i]}';
              filesList.removeAt(i);
            }
          }
          print("들어간 파일들 : ${filesList.toList()}");
          print("들어간 레퍼런스 파일명 :${referenceFile}");
          languageRegister(filesList);
        },
        onDragUpdated: (details) {
          setState(() {
            //offset = details.localPosition;
          });
        },
        onDragEntered: (detail) {
          setState(() {
            _dragging = true;
            //offset = detail.localPosition;
          });
        },
        onDragExited: (detail) {
          setState(() {
            _dragging = false;
            //offset = null;
          });
        },
        child: _list.isEmpty
            ? Column(
                children: [
                  SizedBox(
                    height: 40,
                  ),
                  Text(
                    "<Input File>",
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "1.(필수) ccNC_TTSScipt 엑셀 문서(multi input 가능)",
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    "2.(선택) Frequently_errors_Reference.xlsx File",
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(
                    height: 40,
                  ),
                  Container(
                    height: 350,
                    width: 350,
                    decoration: BoxDecoration(
                      border: bd.Border.all(width: 5, color: Colors.black26),
                      color: _dragging
                          ? Colors.blue.withOpacity(0.4)
                          : Colors.redAccent.withOpacity(0.4),
                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                    ),
                    child: Stack(
                      children: [
                        if (_list.isEmpty)
                          const Column(
                            children: [
                              SizedBox(
                                height: 70,
                              ),
                              Center(
                                child: Icon(
                                  Icons.save_alt,
                                  size: 100,
                                  color: Colors.black12,
                                ),
                              ),
                              Row(
                                children: [
                                  Text("\t\t\t\t Drop Your",
                                      style: TextStyle(
                                          color: Colors.black26, fontSize: 20)),
                                  Text("\t .xlsx File(s)",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black26,
                                          fontSize: 20)),
                                  Icon(
                                    Icons.insert_drive_file_rounded,
                                    color: Colors.black26,
                                  ),
                                  Text(
                                    " Here!",
                                    style: TextStyle(
                                      color: Colors.black26,
                                      fontSize: 20,
                                    ),
                                  ),
                                ],
                              )
                            ],
                          )

                        // if (offset != null)
                        //   Align(
                        //     alignment: Alignment.topRight,
                        //     child: Text(
                        //       'result : ${offset}',
                        //       style: Theme.of(context).textTheme.bodySmall,
                        //     ),
                        //   )
                      ],
                    ),
                  )
                ],
              )
            :
            // Text(_list.map((e) => e.path).join("\n")),
            Container(
                child: ResultScreen(
                  filesList: filesList,
                  languageList: languageList,
                  referenceFile: referenceFile,
                ),
              ));
  }

  SnackBar failMessageSnackBar() {
    return SnackBar(
      duration: Duration(seconds: 2),
      content: Text("삽입 중에 잘못된 형식의 파일이 들어갔습니다."),
      action: SnackBarAction(
        onPressed: () {},
        label: "Done",
        textColor: Colors.blue,
      ),
    );
  }

  SnackBar failMessageSnackBar2() {
    return SnackBar(
      duration: Duration(seconds: 2),
      content: Text("레퍼런스 파일 외에 필수 파일인 스크립트 문서도 삽입되어야 합니다. 다시 시도해주세요."),
      action: SnackBarAction(
        onPressed: () {},
        label: "Done",
        textColor: Colors.blue,
      ),
    );
  }

  Future<List<String>> languageRegister(filesList) async {
    for (int i = 0; i < filesList.length; i++) {
      if (filesList[i].substring(filesList[i].lastIndexOf('\\')).split('_')[2] ==
          "Portuguese") {
        language = "ptp";
      } else if (filesList[i].substring(filesList[i].lastIndexOf('\\')).split('_')[2] ==
          "Czech") {
        language = "czc";
      } else if (filesList[i].substring(filesList[i].lastIndexOf('\\')).split('_')[2] ==
          "Slovakia") {
        language = "sks";
      } else if (filesList[i].substring(filesList[i].lastIndexOf('\\')).split('_')[2] ==
          "Swedish") {
        language = "sws";
      } else if (filesList[i].substring(filesList[i].lastIndexOf('\\')).split('_')[2] ==
          "Czech") {
        language = "czc";
      } else if (filesList[i].substring(filesList[i].lastIndexOf('\\')).split('_')[2] ==
          "Turkish") {
        language = "trt";
      } else if (filesList[i].substring(filesList[i].lastIndexOf('\\')).split('_')[2] ==
          "Croatian") {
        language = "hrh";
      } else if (filesList[i].substring(filesList[i].lastIndexOf('\\')).split('_')[2] ==
          "Dutch") {
        language = "dun";
      } else if (filesList[i].substring(filesList[i].lastIndexOf('\\')).split('_')[2] ==
          "Italian") {
        language = "iti";
      } else if (filesList[i].substring(filesList[i].lastIndexOf('\\')).split('_')[2] ==
          "Norwegian") {
        language = "non";
      } else if (filesList[i].substring(filesList[i].lastIndexOf('\\')).split('_')[2] ==
          "UK") {
        language = "eng";
      } else if (filesList[i].substring(filesList[i].lastIndexOf('\\')).split('_')[2] ==
          "Danish") {
        language = "dad";
      } else if (filesList[i].substring(filesList[i].lastIndexOf('\\')).split('_')[2] ==
          "Slovenian") {
        language = "sls";
      } else if (filesList[i].substring(filesList[i].lastIndexOf('\\')).split('_')[2] ==
          "Bulgarian") {
        language = "bgb";
      } else if (filesList[i].substring(filesList[i].lastIndexOf('\\')).split('_')[2] ==
          "Polish") {
        language = "plp";
      } else if (filesList[i].substring(filesList[i].lastIndexOf('\\')).split('_')[2] ==
          "Greek") {
        language = "grg";
      } else if (filesList[i].substring(filesList[i].lastIndexOf('\\')).split('_')[2] ==
          "German") {
        language = "ged";
      } else if (filesList[i].substring(filesList[i].lastIndexOf('\\')).split('_')[2] ==
          "Romanian") {
        language = "ror";
      } else if (filesList[i].substring(filesList[i].lastIndexOf('\\')).split('_')[2] ==
          "Ukrainian") {
        language = "uku";
      } else if (filesList[i].substring(filesList[i].lastIndexOf('\\')).split('_')[2] == "Finnish") {
        language = "fif";
      } else if (filesList[i].substring(filesList[i].lastIndexOf('\\')).split('_')[2] == "European") {
        if (filesList[i]
                .substring(filesList[i].lastIndexOf('\\'))
                .split('_')[3] ==
            "French") {
          language = "frf";
        } else if (filesList[i]
                .substring(filesList[i].lastIndexOf('\\'))
                .split('_')[3] ==
            "Spanish") {
          language = "spe";
        }

        ;
      } else {
        language = "UNKNOWN";
      }
      languageList.add(language);
    }
    return languageList;
  }
}
