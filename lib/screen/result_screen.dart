import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:tts_script_converter/screen/home_screen.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:multi_highlight_text/multi_highlight_text.dart';
import 'package:multi_highlight_text/config.dart';
import 'package:sticky_az_list/sticky_az_list.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:tts_script_converter/model/Contents.dart';
import 'package:tts_script_converter/model/SearchData.dart';
import 'package:search_page/search_page.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen(
      {super.key,
      required this.filesList,
      required this.languageList,
      required this.referenceFile});

  final List<String> filesList;
  final List<String> languageList;
  final String referenceFile;

  @override
  State<ResultScreen> createState() => _ResultScreen();

}

class _ResultScreen extends State<ResultScreen> {
  //★★전역 변수 모음 시작★★//
  var excel = null;
  late List<String> filesList = widget.filesList;
  late List<String> languageList = widget.languageList;
  late String referenceFile = widget.referenceFile;
  List<Map<String, Object>> patternCheckData = [];
  List<SearchData> searchDataList = [];
  Map<String, String> editedTextForMZExcelFile = {};
  Map<String, String> orgExcelValues = {};
  List<String> referenceFileTables = [];
  List<String> wrongWords = [];
  List<String> wrongWordsOutput = [];
  List<String> correctedWords = [];
  Map<String, String> referenceFileDatas = {};
  List<String> doubleErrorList = ["  ", "   ", "    ", "     ", ".."];
  String tempSpaceFinding = "";
  List<String> errorType0 = []; // double quote and double space (ex .. ,  )
  List<String> errorType1 = []; // double quote (ex ..)
  int errorType2 = 0; // double space (ex   )
  List<String> errorType3 = []; // 레퍼런스북에 의거한 miss spelling 오류
  List<String> errorType4 = []; // 중복단어 오류.

  List<String> errorType1IndexList = [];
  List<String> errorType2IndexList = [];
  List<String> errorType3IndexList = [];
  List<String> errorType4IndexList = [];

  List<List<int>>? copyFileBytes = [];
  bool isEditMode = false;
  bool isTextView = false;
  bool isGrammarCheckMode = false;
  bool isGrammarCheckButton = true;
  bool isPatternCheckButton = true;

  String _selectedFile = '';
  String _selectedLanguage = '';
  String tempResult = '';

  List<String> beforeResult = [];
  List<String> afterResult = [];
  List<String> indexOrValue = [];
  List<String> patternIndexs = [];
  List<String> patternValues = [];
  List<Contents> patternResult = [];
  TextEditingController resultController = TextEditingController();
  TextEditingController prefixController = TextEditingController();
  TextEditingController suffixController = TextEditingController();
  final EdgeInsetsGeometry padding = EdgeInsets.all(8.0);
  final BoxDecoration decoration = BoxDecoration(
    color: Colors.yellow,
  );
  final BoxDecoration decoration2 = BoxDecoration(
    color: Colors.greenAccent,
  );

  final TextStyle _textStyle =
      const TextStyle(fontSize: 14, color: Colors.black);

  List<String> targetWords = [];
  String aftertext = "";
  String highLightText = "";
  List<String> splittedWords = [];
  int fileIndex = 0;
  String errorReport = "[Error Report]\n${DateTime.now()}\n";
  var regExp = RegExp(r"[\[,\],;,.,NX]");
  var regExp2 = RegExp(r"[;,NX]");
  var regExp3 = RegExp(r"N(.{0,});|([0-9]+;)"); // 최종파일 출력시 인덱스 1차 정규표현 가공
  var regExp4 = RegExp(r"N(.{0,});"); // 최종파일 출력시 인덱스 2차 정규표현 가공
  var regExp5 = RegExp(r"(.{0,})_N"); // 최종파일 출력시 인덱스 3차 정규표현 가공

  String prefix = "";
  String suffix = "";

  //★★전역 변수 모음 끝★★//

  void initState() {
    super.initState();
    setState(() {
      errorReport +=
          "Converting Target(s) ☞ ${languageList.toList().toString().toUpperCase()}\n\n";
      if (referenceFile != "") {
        getErrorReferenceBook(referenceFile);
      }
      _selectedFile = filesList[0];
      _selectedLanguage = languageList[0];
      afterResult = getExcelData(filesList);
      fileIndex = filesList.indexOf(_selectedFile);
      _onSetText(fileIndex);
      aftertext = afterResult[0].replaceAll('\n', ' ');
      splittedWords = aftertext.split(' ');
      highLightText = afterResult[0];

      //print("함수 호출 전  : ${splittedWords[11]}");
    });
  }

  //★★위젯의 시작★★//
  Widget build(BuildContext context) {
    resultController = TextEditingController(text: afterResult.first);

    return Center(
        child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 12,
            ),
            //☞ back button
            new SizedBox(
              width: 160,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  AlertDialog alert = AlertDialog(
                    content: Text("변환된 파일이 모두 사라집니다.\n 첫 화면으로 이동하시겠습니까?"),
                    actions: [
                      TextButton(
                          onPressed: () {
                            filesList.clear();
                            languageList.clear();
                            beforeResult.clear();
                            Navigator.pop(context);
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    HomeScreen()));
                          },
                          child: Text("예",
                              style: TextStyle(
                                color: Colors.red.withOpacity(0.6),
                              ))),
                      TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text("아니오",
                              style: TextStyle(
                                color: Colors.red.withOpacity(0.6),
                              ))),
                    ],
                  );
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return alert;
                      });
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withOpacity(0.4)),
                child: Row(
                  children: [
                    IconTheme(
                      data: IconThemeData(color: Colors.black),
                      child: Icon(Icons.chevron_left),
                    ),
                    Text("Back", style: TextStyle(color: Colors.black)),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 30,
            ),
            //☞ grammar check button
            new SizedBox(
              width: 180,
              height: 50,
              child: ElevatedButton(
                onPressed: isGrammarCheckButton //이 부분에서 텍스트 상태 (저장여부확인), 다시 짜기
                    ? () {
                        Future.delayed(const Duration(milliseconds: 1000), () {
                          setState(() {
                            isEditMode = false;
                            isGrammarCheckButton = false;
                            isGrammarCheckMode = !isGrammarCheckMode;
                            fileIndex = filesList.indexOf(_selectedFile);
                            if (resultController.text ==
                                beforeResult[fileIndex]) {
                              //print("같네요?");

                              aftertext = _onChangedTextController(fileIndex)
                                  .text
                                  .replaceAll('\n', ' ');
                              splittedWords = aftertext.split(' ');
                              highLightText = resultController.text;
                              _grammarCheck(splittedWords);
                            } else {
                              aftertext =
                                  resultController.text.replaceAll('\n', ' ');
                              splittedWords = aftertext.split(' ');
                              highLightText = resultController.text;
                              _grammarCheck(splittedWords);
                            }
                          });
                        });
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withOpacity(0.4)),
                child: Row(
                  children: [
                    IconTheme(
                      data: IconThemeData(color: Colors.black),
                      child: Icon(Icons.verified),
                    ),
                    SelectableText(
                      "\tGrammar Check",
                      style: TextStyle(fontSize: 13, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(
              width: 30,
            ),
            // ☞ pattern check button
            new SizedBox(
              width: 180,
              height: 50,
              child: ElevatedButton(
                onPressed: isPatternCheckButton
                    ? () {
                        getPatternCheckData(resultController.text);
                        // patternIndexs = patternCheckData.keys.toList();
                        // patternValues = patternCheckData.values.toList();
                        // final AtoZ = patternValues.map(
                        //     (item) => patternCheckData(
                        //       values: item['value']
                        //     )
                        // );

                        AlertDialog alert = AlertDialog(
                          content: Column(
                            children: [
                              Text(
                                "Pattern Check",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Expanded(
                                child: Container(
                                  height: 800,
                                  width: 800,
                                  child: StickyAzList(
                                      items: patternResult,
                                      options: StickyAzOptions(
                                        listOptions: ListOptions(
                                            headerColor: Colors.redAccent
                                                .withOpacity(0.4)),
                                      ),
                                      builder: (context, index, item) {
                                        return ListTile(
                                          title: Text("${item.contents}"),
                                        );
                                      }),
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text("닫기",
                                    style: TextStyle(
                                      color: Colors.red.withOpacity(0.6),
                                    ))),
                          ],
                        );
                        Future.delayed(const Duration(milliseconds: 2000), () {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return alert;
                              });
                        });
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withOpacity(0.4)),
                child: Row(
                  children: [
                    IconTheme(
                      data: IconThemeData(color: Colors.black),
                      child: Icon(Icons.view_timeline),
                    ),
                    Text(" Pattern Check",
                        style: TextStyle(color: Colors.black)),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 30,
            ),
            // ☞ search button
            new SizedBox(
              width: 180,
              height: 50,
              child: ElevatedButton(
                onPressed: isPatternCheckButton
                    ? () {
                        getSearchData(resultController.text);

                        ListView.builder(
                          itemCount: searchDataList.length,
                          itemBuilder: (context, index) {
                            final searchData = searchDataList[index];
                          },
                        );

                        showSearch(
                          context: context,
                          delegate: SearchPage(
                            items: searchDataList,
                            searchLabel: 'Search Content',
                            suggestion: const Center(
                              child: Text('Filter Content or Index '),
                            ),
                            failure: const Center(
                              child: Text('Not found :('),
                            ),
                            filter: (searchData) => [
                              searchData.content,
                              searchData.index,
                            ],
                            sort: (a, b) => a.compareTo(b),
                            builder: (searchData) => ListTile(
                              title: Text(searchData.content),
                              trailing: Text(searchData.index),
                            ),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withOpacity(0.4)),
                child: Row(
                  children: [
                    IconTheme(
                      data: IconThemeData(color: Colors.black),
                      child: Icon(Icons.search),
                    ),
                    Text(" Search", style: TextStyle(color: Colors.black)),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 30,
            ),
            //☞ edit activate switchListTile
            new Container(
              width: 200,
              height: 50,
              child: SwitchListTile(
                  title: const Row(
                    children: [
                      IconTheme(
                        data: IconThemeData(color: Colors.black),
                        child: Icon(Icons.edit),
                      ),
                      Text(
                        'Edit Mode',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  tileColor: Colors.redAccent.withOpacity(0.4),
                  activeColor: Colors.red,
                  value: isEditMode,
                  onChanged: (bool value) {
                    fileIndex = filesList.indexOf(_selectedFile);
                    if (isEditMode == false) {
                      if (isGrammarCheckMode == true) {
                        //print("에디팅 off=> on 상황  : 그래머 체크를 한 이후에 버튼을 누르려 할때");
                        setState(() {
                          _onChangedTextController(fileIndex);

                          isGrammarCheckMode = false;
                          isGrammarCheckButton = true;
                          isPatternCheckButton = false;
                          isTextView = !isTextView;
                          _onSwitchChanged(value);
                        });
                      } else {
                        // print("에디팅 off=> on 상황 : 그래머 체크를 하지 않고 버튼을 누르려 할때");
                        setState(() {
                          _onChangedTextController(fileIndex);
                          isGrammarCheckButton = true;
                          isPatternCheckButton = false;
                          isTextView = !isTextView;
                          _onSwitchChanged(value);
                        });
                      }
                    } else {
                      if (beforeResult[fileIndex] == resultController.text) {
                        setState(() {
                          //print("에디팅 on => off 상황 : 수정한 내용이 없을 때 ");
                          _onChangedTextController(fileIndex);
                          isGrammarCheckButton = true;
                          isTextView = !isTextView;
                          isGrammarCheckMode = false;
                          isPatternCheckButton = true;
                          _onSwitchChanged(value);
                        });
                      } else {
                        //print("에디팅 on => off 상황 : 수정한 내용이 있을 경우");
                        AlertDialog alert = AlertDialog(
                          content: Text("변경된 내용이 있습니다. 저장하시겠습니까?"),
                          actions: [
                            TextButton(
                                onPressed: () {
                                  if (resultController.text == "" ||
                                      (!resultController.text.contains(
                                              "[HEADER]\nPromptSculptor Script\nScriptVersion = v2.0.0\nScriptEncoding = UTF-8\nLanguage =") ||
                                          !resultController.text
                                              .contains("[TTS]"))) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        editFailMessageSnackBar());
                                  } else {
                                    fileIndex =
                                        filesList.indexOf(_selectedFile);

                                    afterResult[fileIndex] =
                                        resultController.text;

                                    setState(() {
                                      _onChangedTextController(fileIndex);
                                      isGrammarCheckButton = true;
                                      isEditMode = false;
                                      isTextView = false;
                                      isPatternCheckButton = true;
                                    });
                                    Navigator.pop(context);
                                  }
                                },
                                child: Text("저장",
                                    style: TextStyle(
                                      color: Colors.red.withOpacity(0.4),
                                    ))),
                            TextButton(
                                onPressed: () {
                                  fileIndex = filesList.indexOf(_selectedFile);
                                  setState(() {
                                    resultController.text =
                                        beforeResult[fileIndex];
                                  });
                                  Navigator.pop(context);
                                  setState(() {
                                    isGrammarCheckButton = true;
                                    isEditMode = false;
                                    isTextView = false;
                                  });
                                },
                                child: Text("저장안함",
                                    style: TextStyle(
                                      color: Colors.red.withOpacity(0.4),
                                    ))),
                            TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text("취소",
                                    style: TextStyle(
                                      color: Colors.red.withOpacity(0.4),
                                    ))),
                          ],
                        );
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return alert;
                            });
                      }
                    }
                  }),
            ),

            SizedBox(
              width: 30,
            ),
            //☞ download button
            new SizedBox(
              width: 180,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  prefixController.text = "";
                  suffixController.text = "";
                  AlertDialog alert = AlertDialog(
                    content: Container(
                      height: 350,
                      width: 300,
                      child: Column(
                        children: [
                          Text(
                            "변환된 Text 파일을 다운로드 \n하시겠습니까?",
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                            height: 70,
                          ),
                          Text(
                            "(선택사항)스크립트 파일의 인덱스에 특정 문자 붙이기\n영문(대문자 자동변환),숫자만 입력가능",
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10,),
                          TextField(
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(RegExp('[\\_]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\!]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\@]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\#]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\\$]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\%]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\^]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\&]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\*]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\(]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\)]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\-]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\_]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\+]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\-]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\~]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\`]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\{]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\}]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\[]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\]]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\;]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\:]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\"]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\\']')),
                              FilteringTextInputFormatter.deny(RegExp('[\\,]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\<]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\>]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\.]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\?]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\/]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\[ㄱ-ㅎ]')),
                            ],
                            maxLength: 5,
                            controller: prefixController,
                            decoration: InputDecoration(
                              isDense: true,
                              labelText: 'Prefix 입력',
                              hintText: '사용안함',
                              filled: true,
                            ),
                          ),
                          SizedBox(height: 10,),
                          TextField(
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(RegExp('[\\_]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\!]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\@]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\#]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\\$]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\%]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\^]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\&]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\*]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\(]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\)]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\-]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\_]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\+]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\-]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\~]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\`]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\{]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\}]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\[]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\]]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\;]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\:]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\"]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\\']')),
                              FilteringTextInputFormatter.deny(RegExp('[\\,]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\<]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\>]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\.]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\?]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\/]')),
                              FilteringTextInputFormatter.deny(RegExp('[\\[ㄱ-ㅎ]')),
                            ],
                            maxLength: 5,
                            controller: suffixController ,
                            decoration: InputDecoration(
                              isDense: true,
                              labelText: 'Suffix 입력',
                              hintText: '사용안함',
                              helperText:
                                  '※ Underbar는 입력하지 마십시오.\n 자동으로 파일에 들어갑니다.',
                              helperStyle: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold),
                              filled: true,
                            ),
                          )
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            if (beforeResult[fileIndex] !=
                                resultController.text) {
                              fileIndex = filesList.indexOf(_selectedFile);
                              afterResult[fileIndex] = resultController.text;
                              bool downloadCancelFlag =
                                  await _writeData(afterResult);
                              if (downloadCancelFlag == true) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(downloadCancel());
                              } else {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(requireEditandDownload());
                                setState(() {
                                  isGrammarCheckButton = true;
                                  isEditMode = false;
                                  isTextView = false;
                                  isPatternCheckButton = true;
                                });
                              }
                            } else {
                              //print(afterResult.toList());

                              bool downloadCancelFlag =
                                  await _writeData(afterResult);
                              if (downloadCancelFlag == true) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(downloadCancel());
                              } else {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(isDownloading());
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(downloadComplete());
                                Future.delayed(const Duration(milliseconds: 4500), () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: (BuildContext context) =>
                                          HomeScreen()));
                                });

                              }

                            }

                          },
                          child: Text("예",
                              style: TextStyle(
                                color: Colors.red.withOpacity(0.4),
                              ))),
                      TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text("아니오",
                              style: TextStyle(
                                color: Colors.red.withOpacity(0.4),
                              ))),
                    ],
                  );
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return alert;
                      });
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withOpacity(0.4)),
                child: Row(
                  children: [
                    IconTheme(
                      data: IconThemeData(color: Colors.black),
                      child: Icon(Icons.download),
                    ),
                    SelectableText("Download",
                        style: TextStyle(color: Colors.black)),
                  ],
                ),
              ),
            )
          ],
        ),
        //☞ dropdown view
        Container(
            child: DropdownButton(
          // style: TextStyle(
          //     fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold),
          dropdownColor: Colors.grey,
          value: _selectedFile,
          items: filesList
              .map((e) => DropdownMenuItem(
                    child: Row(
                      children: [
                        Text(
                          "▷ ${e.substring(e.lastIndexOf('\\') + 1)}",
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "의 변환 결과",
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black45,
                          ),
                        )
                      ],
                    ),
                    value: e,
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              isGrammarCheckMode = false;
              isGrammarCheckButton = true;
              _selectedFile = value!;
              print("선택된 파일 : ${_selectedFile}");
              fileIndex = filesList.indexOf(_selectedFile);
              _onChangedTextController(fileIndex);
              getSearchData(resultController.text);
              //_onSetText(fileIndex);
            });
            // //print("☆☆: ${ _onSetText(fileIndex).substring(0,92)}");
            // aftertext = _onChangedTextController(fileIndex).text.replaceAll(
            //     '\n', ' ');
            // //print("★★ ${aftertext.substring(0,92)}");
            // //Future.delayed(const Duration(milliseconds: 1000), () {
            // splittedWords = aftertext.split(' ');
            // highLightText = resultController.text;
            // _grammarCheck(splittedWords);
            //});
          },
        )),
        SizedBox(
          width: 20,
        ),
        //☞ visibility(1) : check result
        Visibility(
          child: Center(
            child: Row(
              children: [
                Text(
                  "(Check Mode)",
                  style: TextStyle(
                      fontStyle: FontStyle.italic, color: Colors.redAccent),
                ),
                SizedBox(
                  width: 20,
                ),
                IconTheme(
                  data: IconThemeData(color: Colors.white),
                  child: Icon(Icons.rectangle),
                ),
                Text(
                  " : 중복 단어",
                  style: TextStyle(
                      fontStyle: FontStyle.italic, color: Colors.black),
                ),
                SizedBox(
                  width: 20,
                ),
                IconTheme(
                  data: IconThemeData(color: Colors.redAccent),
                  child: Icon(Icons.rectangle),
                ),
                Text(
                  " : 단어 오타 발생",
                  style: TextStyle(
                      fontStyle: FontStyle.italic, color: Colors.black),
                ),
                SizedBox(
                  width: 20,
                ),
                IconTheme(
                  data: IconThemeData(color: Colors.greenAccent),
                  child: Icon(Icons.rectangle),
                ),
                Text(
                  " : 띄어쓰기 두번이상 및 중복 마침표.",
                  style: TextStyle(
                      fontStyle: FontStyle.italic, color: Colors.black),
                ),
              ],
            ),
          ),
          visible: isGrammarCheckMode,
        ),
        //☞ visibility(2) : edit mode
        Visibility(
          child: Text(
            "(Edit Mode)",
            style:
                TextStyle(fontStyle: FontStyle.italic, color: Colors.redAccent),
          ),
          visible: isTextView,
        ),
        //☞ SingleChildScroolView : 텍스트필드와 텍스트

        Expanded(
          child: Stack(
            children: [
              Container(
                  margin: EdgeInsets.all(10),
                  color: (isEditMode == true && isGrammarCheckMode == false)
                      ? Colors.white
                      : Colors.black12,
                  child: SingleChildScrollView(
                    child: isGrammarCheckButton
                        ? TextFormField(
                            key: Key('Result'),
                            readOnly: !isEditMode,
                            controller: resultController,
                            maxLines: null,
                            decoration: InputDecoration(
                                enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                        color:
                                            Colors.redAccent.withOpacity(0.4))),
                                focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.redAccent
                                            .withOpacity(0.4)))),
                          )
                        : _buildBackgroundColorExample(
                            onMixStyleBuilder: (styleA, styleB) {
                              return _textStyle.copyWith(
                                  backgroundColor: Colors.blue);
                            },
                          ),
                  )),
              // Positioned(
              //   bottom: 20,
              //   right: 40,
              //   child: FloatingActionButton(
              //     onPressed: () {
              //       AlertDialog alert = AlertDialog(
              //         insetPadding: EdgeInsets.only(top: 120, left: 770),
              //         content: Column(
              //           children: [
              //             Text(
              //               "Reference File",
              //               style: TextStyle(
              //                   fontSize: 16, fontWeight: FontWeight.bold),
              //             ),
              //             referenceFile == ""
              //                 ? Text("레퍼런스 파일이 없습니다. 오타 검증에 반영되지 않습니다.")
              //                 : Text("YES")
              //           ],
              //         ),
              //         actions: [
              //           TextButton(
              //               onPressed: () {
              //                 Navigator.pop(context);
              //               },
              //               child: Text("닫기",
              //                   style: TextStyle(
              //                     color: Colors.red.withOpacity(0.6),
              //                   ))),
              //         ],
              //       );
              //       showDialog(
              //           barrierColor: Colors.white.withOpacity(0),
              //           context: context,
              //           builder: (BuildContext context) {
              //             return alert;
              //           });
              //     },
              //     backgroundColor: Colors.redAccent.withOpacity(0.4),
              //     tooltip: 'Reference File View',
              //     child: const Icon(Icons.checklist_rtl),
              //   ),
              // ),
            ],
          ),
        ),
      ],
    ));
  }

  //★★ 위젯의 끝★★//

  //★★function 모음 시작★★//
  // ☞ 문법 오류 유형에 따른 어떤 하이라이트(틴트)를 칠해줄지에 대해 정의 한 부분
  Widget _buildBackgroundColorExample({MixStyleBuilder? onMixStyleBuilder}) {
    return Row(
      //padding: const EdgeInsets.all(30),
      children: [
        MultiHighLightText(
          text: highLightText,
          textStyle: const TextStyle(fontSize: 14, color: Colors.black),
          onMixStyleBuilder: onMixStyleBuilder,
          highlights: [
            ...targetWords
                .toList() //중복 단어
                .map((e) => HighlightItem(
                    text: e,
                    textStyle:
                        _textStyle.copyWith(backgroundColor: Colors.white)))
                .toList(),
            ...wrongWords //틀린 단어
                .map((e) => HighlightItem(
                    text: e,
                    textStyle:
                        _textStyle.copyWith(backgroundColor: Colors.redAccent)))
                .toList(),
            ...doubleErrorList //이중 띄어쓰기 및 이중 dot
                .map((e) => HighlightItem(
                    text: e,
                    textStyle: _textStyle.copyWith(
                        backgroundColor: Colors.greenAccent)))
                .toList(),
            // ...[const TextRange(start: 0, end: 98)]
            //     .map((e) => HighlightItem(
            //     range: e,
            //     textStyle:
            //     _textStyle.copyWith(backgroundColor: Colors.grey)))
            //     .toList()
          ],
        ),
      ],
    );
  }

  //☞ 홈스크린에서 가져온 엑셀 파일들을 가져오는 함수
  List<String> getExcelData(List<String> filesList) {
    String output = '';
    String contents = "";

    for (int i = 0; i < filesList.length; i++) {
      var bytes = File(filesList[i]).readAsBytesSync(); //엑셀파일을 바이트로 표현
      excel = Excel.decodeBytes(bytes);
      var decoder = SpreadsheetDecoder.decodeBytes(bytes, update: true);
      output =
          "[HEADER]\nPromptSculptor Script\nScriptVersion = v2.0.0\nScriptEncoding = UTF-8\nLanguage = ${languageList[i]}\n\n[TTS]\n";
      var table = decoder.tables.keys.first;
      for (int a = 4; a < excel.tables[table]!.maxRows - 1; a++) {
        if (decoder.tables[table]!.rows[a][languageList[i] == "eng" ? 3 : 4] ==
                "New" ||
            decoder.tables[table]!.rows[a][languageList[i] == "eng" ? 3 : 4] ==
                "Changed") {
          contents = decoder
              .tables[table]!.rows[a][languageList[i] == "eng" ? 2 : 3]
              .toString()
              .replaceAll("\n", " ")
              .trimRight();

          output += "${decoder.tables[table]!.rows[a][0]}\;\n${contents}\n\n";
        }
      }
      output = output.substring(0, output.length - 2); //마지막 줄바뀜 2줄 삭제
      beforeResult.add(output);
    }

    return beforeResult;
  }

  //☞ 레퍼런스 파일을 가져왔을 경우 실행 되는 함수이며, wrong word와 corrected word 리스트를 생성해주는 함수
  void getErrorReferenceBook(String referenceFile) {
    var referenceFile_after = File(referenceFile).readAsBytesSync();
    var excel = Excel.decodeBytes(referenceFile_after);
    var decoder =
        SpreadsheetDecoder.decodeBytes(referenceFile_after, update: true);
    var table = decoder.tables.keys.toList();
    //print(table);

    for (int i = 1; i < table.length; i++) {
      referenceFileTables.add(table[i]);
    }
    int cnt = 1;
    for (int i = 0; i < referenceFileTables.length; i++) {
      for (int a = 1; a < excel.tables[referenceFileTables[i]]!.maxRows; a++) {
        for (int b = 0; b < 3; b++) {
          if (cnt % 3 == 1) {
            referenceFileDatas['Language'] = '${referenceFileTables[i]}';
            referenceFileDatas['Error type'] =
                '${decoder.tables[referenceFileTables[i]]!.rows[a][b]}';
          } else if (cnt % 3 == 2) {
            wrongWords
                .add('${decoder.tables[referenceFileTables[i]]!.rows[a][b]}');
            referenceFileDatas['Wrong'] =
                '${decoder.tables[referenceFileTables[i]]!.rows[a][b]}';
          } else if (cnt % 3 == 0) {
            correctedWords
                .add('${decoder.tables[referenceFileTables[i]]!.rows[a][b]}');
            referenceFileDatas['Corrected'] =
                '${decoder.tables[referenceFileTables[i]]!.rows[a][b]}';
          }
          //print(decoder.tables[referenceFileTables[i]]!.rows[a][b]);
          cnt++;
        }
      }
    }
  }

  // ☞ 그래머 체크 : 스크립트 파일 내 문장들을 단어 별로 끊어서 문장체크 실시(double space, dobule quoute, reference book을 통한 스펠링 오류 , 중복 단어 체크)
  void _grammarCheck(List<String> splittedWords) {
    //print("함수 안 : ${splittedWords[11]}");
    //print(splittedWords.toList());

    errorType0.clear();
    for (int i = 0; i < doubleErrorList.length; i++) {
      if (resultController.text.contains(doubleErrorList[i])) {
        errorType0.add(doubleErrorList[i]);
      }
    }
    wrongWordsOutput.clear();
    for (int i = 0; i < wrongWords.length; i++) {
      // referencebook에서 내용 비교해  틀린 단어 갯수 세기
      for (int j = 0; j < splittedWords.length; j++) {
        if (wrongWords[i] == splittedWords[j]) {
          wrongWordsOutput.add(wrongWords[i]);
        }
      }
    }
    targetWords.clear();
    for (int i = 1; i < splittedWords.length; i++) {
      // 중복 단어 체크
      if (splittedWords[i - 1] == splittedWords[i]) {
        targetWords.add('${splittedWords[i - 1]} ${splittedWords[i - 1]}');
      }
      targetWords.remove(" ");
    }
  }

  // ☞ 에러리포트 만들기: 다운로드시 다시 한번 최종본에 대한 문장체크를 실시하고, 에러리포트에 반영
  String _makeErrorReportFile(List<String> afterResult) {
    for (int i = 0; i < afterResult.length; i++) {
      int sum = 0;
      splittedWords.clear();
      aftertext = afterResult[i].replaceAll('\n', ' ');
      splittedWords = aftertext.split(' ');
      tempSpaceFinding = "";
      errorType1.clear();
      errorType2 = 0;
      errorType3.clear();
      errorType4.clear();
      wrongWordsOutput.clear();
      targetWords.clear();
      errorType1IndexList.clear();
      errorType2IndexList.clear();
      errorType3IndexList.clear();
      errorType4IndexList.clear();

      //에러타입 1 : 더블 quote 찾기
      for (int i = 1; i < splittedWords.length; i++) {
        if (splittedWords[i].contains('..')) {
          errorType1.add('');
          for (int j = i; j > 0; j--) {
            if (regExp2.hasMatch(splittedWords[j])) {
              //에러타입1의 인덱스를 찾아 넣기

              errorType1IndexList.add(splittedWords[j]
                  .toString()
                  .substring(0, splittedWords[j].length - 1));
              break;
            }
          }
        }
      }

      //에러타입 3 : referencebook에서 내용 비교해  틀린 단어 갯수 세기
      for (int i = 0; i < wrongWords.length; i++) {
        //
        for (int j = 0; j < splittedWords.length; j++) {
          if (wrongWords[i] == splittedWords[j]) {
            errorType3.add(wrongWords[i]);
            for (int k = j; k > 0; k--) {
              if (regExp2.hasMatch(splittedWords[k])) {
                errorType3IndexList.add(splittedWords[k]
                    .toString()
                    .substring(0, splittedWords[k].length - 1));
                break;
              }
            }
          }
        }
      }

      //에러타입 4 : 중복 단어 체크
      for (int i = 1; i < splittedWords.length - 1; i++) {
        if (splittedWords[i - 1] == splittedWords[i]) {
          errorType4.add('${splittedWords[i - 1]} ${splittedWords[i - 1]}');
          for (int j = i; j > 0; j--) {
            if (regExp2.hasMatch(splittedWords[j])) {
              //에러 타입4의 인덱스를 찾아 넣기

              errorType4IndexList.add(splittedWords[j]
                  .toString()
                  .substring(0, splittedWords[j].length - 1));
              break;
            }
          }
        }

        errorType4.remove(" ");

        //에러타입 2: 중복 공백 => 일단 임시로 ☆로 대체 (공백이 눈에 띄게 하기 위함)
        if (splittedWords[i] == "" &&
            !regExp.hasMatch(splittedWords[i - 1]) &&
            !regExp.hasMatch(splittedWords[i + 1])) {
          splittedWords[i] = splittedWords[i].replaceAll("", "☆");
          if (splittedWords[i] == "☆" && splittedWords[i - 1] == "☆") {
            // "더블이 아닌 triple space에 대한 예외 처리"

            splittedWords.removeAt(i - 1);
          }
          for (int j = i; j > 0; j--) {
            if (regExp2.hasMatch(splittedWords[j])) {
              //에러 타입4의 인덱스를 찾아 넣기

              errorType2IndexList.add(splittedWords[j]
                  .toString()
                  .substring(0, splittedWords[j].length - 1));
              break;
            }
          }
        }
      }
      //에러타입 2: 중복 공백 => ☆로 대체된 거 갯수 세면 끝!
      for (int i = 0; i < splittedWords.length; i++) {
        if (splittedWords[i].contains('☆')) {
          ++errorType2;
        }
        ;
      }

      sum = errorType1.length +
          (errorType2) +
          errorType3IndexList.length +
          errorType4.length;

      if (sum == 0) {
        errorReport +=
            "\n[${splittedWords[11].toUpperCase()}]\n●Converting Finished.\n";
      } else {
        errorReport +=
            "\n[${splittedWords[11].toUpperCase()}]\n●문법 오류 총 ${sum}건 발생\n\t - Double Quotes : ${errorType1.length}건  ${errorType1IndexList.toList()}\n \t - Double Space: ${errorType2}건  ${errorType2IndexList.toSet().toList()}\n \t - Frequently Error: ${errorType3IndexList.length}건  ${errorType3IndexList.toList()}\n \t - Duplicate words: ${errorType4.length}건  ${errorType4IndexList.toList()}\n";
      }
    }
    return errorReport;
  }

// ☞ 패턴체크에 필요한 자료형을 반환 해주는 함수.
  List<Contents> getPatternCheckData(String inputString) {
    inputString = resultController.text;
    indexOrValue = inputString.substring(98).split("\n");
    for (int i = 0; i < indexOrValue.length; i++) {
      indexOrValue.remove("");
    }
    for (int i = 0; i < indexOrValue.length; i++) {
      if (i % 2 != 0) {
        patternCheckData.add(({
          'contents':
              '${indexOrValue[i]}(${indexOrValue[i - 1].replaceAll(';', '')})'
        }));
      }
    }

    patternResult = patternCheckData
        .map(
          (item) => Contents(
            contents: item['contents'] as String,
          ),
        )
        .toList();

    return patternResult;
  }

  //☞ 현재 파일의 내용들을 검색에 필요한 리스트 요소로 만들기
  List<SearchData> getSearchData(String inputString) {
    searchDataList.clear();
    inputString = resultController.text;
    indexOrValue = inputString.substring(98).split("\n");
    for (int i = 0; i < indexOrValue.length; i++) {
      indexOrValue.remove("");
    }
    for (int i = 0; i < indexOrValue.length; i++) {
      if (i % 2 != 0) {
        searchDataList.add(SearchData(
            '${indexOrValue[i - 1].replaceAll(';', '')}',
            '${indexOrValue[i]}'));
      }
    }

    return searchDataList;
  }

  //☞  텍스트필드에 유저가 지정한 엑셀파일들의 인덱스로 해당 파일의 컨버팅된 결과를 반환
  TextEditingController _onChangedTextController(int index) {
    Future.delayed(const Duration(milliseconds: 30), () {
      resultController.text = afterResult[index];
      resultController.selection =
          TextSelection.collapsed(offset: resultController.text.length);
      //print(resultController.text.substring(1,150));
    });
    return resultController;
  }

  //☞  검증모드시 텍스트필드는 텍스트모드로 전환됨. 따라서 해당 인덱스에 따라 컨버팅된 결과를 반환
  String _onSetText(int index) {
    Future.delayed(const Duration(milliseconds: 30), () {
      resultController.text = afterResult[index];
      resultController.selection =
          TextSelection.collapsed(offset: resultController.text.length);
      //print(resultController.text.substring(1,150));
      highLightText = resultController.text;
      //print("온셋텍스트함수에서 바뀌었나? : ${highLightText.substring(0,92)}");
    });

    return highLightText;
  }

  //☞ 최종 결과 (afterResult) 리스트를 받아 지정된 경로에 다운로드 하는 함수
  Future<bool> _writeData(List<String> afterResult) async {

    // 스크립트 파일 생성 부분
    final dirPath = await _getDirPath();
    var downloadCancel;
    prefix = "${prefixController.text.toUpperCase()}_";
    suffix = "_${suffixController.text.toUpperCase()}";


    if (dirPath == "null") {
      print("다운로드 경로 지정안하고 취소.");
      downloadCancel = true;

      return downloadCancel;
    } else {
      downloadCancel = false;
      //Script 파일 생성 부분
      for (int i = 0; i < afterResult.length; i++) {
        if (prefix != "" && suffix != "") {
          Iterable<RegExpMatch> firstMatches =
              regExp3.allMatches(afterResult[i]);
          for (var m in firstMatches) {

            //afterResult[i] = afterResult[i].replaceAll(m[0].toString(), (prefix + (m[0].toString().substring(0,m[0].toString().length-1))+suffix)+";");
            afterResult[i] = afterResult[i].replaceFirst(m[0].toString(),
                "${prefix}${m[0].toString().substring(0, (m[0].toString().length - 1))}${suffix};");
          }

          Iterable<RegExpMatch> secondMatches =
              regExp4.allMatches(afterResult[i]);
          for (var m in secondMatches) {
            afterResult[i] = afterResult[i].replaceFirst(m[0].toString(),
                "${m[0].toString().substring(0, (m[0].toString().length - suffix.length - 1))};");
          }

          Iterable<RegExpMatch> thirdMatches =
              regExp5.allMatches(afterResult[i]);
          for (var m in thirdMatches) {
            afterResult[i] = afterResult[i].replaceFirst(
                m[0].toString(),
                "${m[0].toString().substring(
                      prefix.length,
                    )}");
          }
        }

        // print(afterResult[i]);

        final myFile =
            File('$dirPath/${languageList[i].toUpperCase()}_SCRIPT.txt');
        await myFile.writeAsString(afterResult[i]);
      }
      //에러 리포트 파일 생성 부분
      _makeErrorReportFile(afterResult);

      final errorReportFile = File(
          '$dirPath/ErrorReport_${DateFormat('yyMMddHHmms').format(DateTime.now())}.txt');
      await errorReportFile.writeAsString(errorReport);

      //★★MZ_Edited 사본 엑셀 파일 생성 부분★★//

      CellStyle cellStyle = CellStyle(
        backgroundColorHex: '#8C8C8C',
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        bold: true,
        fontSize: 11,
        fontColorHex: '#F6F6F6',
        fontFamily: getFontFamily(FontFamily.Candara),
      );
      cellStyle.underline = Underline.Single;
      var decoder;
      var table;
      var editStringCell;
      var sheetObject_var;

      for (int i = 0; i < filesList.length; i++) {
        var bytes = File(filesList[i]).readAsBytesSync(); //엑셀파일을 바이트로 표현
        excel = Excel.decodeBytes(bytes);
        decoder = SpreadsheetDecoder.decodeBytes(bytes, update: true);
        table = decoder.tables.keys.first;
        Sheet sheetObject = excel[table];
        sheetObject_var = sheetObject;
        var cell = sheetObject.cell(
            CellIndex.indexByString(languageList[i] == "eng" ? 'E4' : 'F4'));
        cell.cellStyle = cellStyle;
        cell.value = 'Mediazen Comment';
        sheetObject.setColumnWidth(0, 10);
        sheetObject.setColumnWidth(1, 30);
        sheetObject.setColumnWidth(2, 30);
        if (languageList[i] == "eng") {
          sheetObject.setColumnWidth(3, 10);
          sheetObject.setColumnWidth(4, 30);
        } else {
          sheetObject.setColumnWidth(3, 30);
          sheetObject.setColumnWidth(4, 10);
          sheetObject.setColumnWidth(5, 30);
        }
        orgExcelValues.clear();
        for (int a = 4; a < excel.tables[table]!.maxRows - 1; a++) {
          if (decoder.tables[table]!.rows[a][table == "UK_English" ? 3 : 4] ==
                  "New" ||
              decoder.tables[table]!.rows[a][table == "UK_English" ? 3 : 4] ==
                  "Changed") {
            orgExcelValues[
                    '${getCellId(table == "UK_English" ? 3 - 1 : 4 - 1, a).toString()}'] =
                '${decoder.tables[table]!.rows[a][table == "UK_English" ? 2 : 3].toString().replaceAll("\n", " ").trimRight()}';
          }
        }
        //print("오알지 : ${orgExcelValues.values.toList()}");

        // 이부분부터는 프로그램에서 수정한 부분을 고쳐준다.

        editedTextForMZExcelFile.clear();

        indexOrValue.clear();
        indexOrValue = afterResult[i].substring(98).split("\n");
        for (int i = 0; i < indexOrValue.length; i++) {
          indexOrValue.remove("");
        }

        for (int j = 0; j < indexOrValue.length; j++) {
          if (j % 2 != 0) {
            editedTextForMZExcelFile[
                    '${indexOrValue[j - 1].replaceAll(';', '')}'] =
                '${indexOrValue[j]}';
          }
        }
        //  print(" 에디티드 엑셀 파일 : ${editedTextForMZExcelFile.values.toList()}");

        for (int i = 0; i < orgExcelValues.length; i++) {
          if (orgExcelValues.values.toList()[i] !=
              editedTextForMZExcelFile.values.toList()[i]) {
            editStringCell = sheetObject_var.cell(CellIndex.indexByString(
                orgExcelValues.keys.toList()[i].toString()));
            editStringCell.value =
                "${editedTextForMZExcelFile.values.toList()[i]}";
          }
        }

        String myFile2 =
            "$dirPath/(MZ_Edited)${filesList[i].substring(filesList[i].lastIndexOf('\\') + 1)}";

        File(join(myFile2))
          ..createSync(recursive: true)
          ..writeAsBytesSync(excel.encode()!);
      }

      // String myFile2 = "$dirPath/${filesList[i].substring(filesList[i].lastIndexOf('\\')+1).substring(0,filesList[i].indexOf('.xlsx'))}_MZ_Edited.xlsx";

      return downloadCancel;
    }
  }

  //☞  _selectFolder에 이어서 선택된 경로 지정 함수
  Future<String> _getDirPath() async {
    final path = await FilePicker.platform.getDirectoryPath();
    String dir = await path.toString();

    return dir;
  }

  //☞  수정모드 on/off 함수
  void _onSwitchChanged(bool value) {
    isEditMode = value;
  }

  //☞  임의 수정시에 헤더파일을 건드릴 경우 save 못하게 알려주는 스낵바
  SnackBar editFailMessageSnackBar() {
    return SnackBar(
      duration: Duration(seconds: 5),
      content: Text("스트립트 양식에 맞지 않아 , 저장 할 수 없습니다."),
      action: SnackBarAction(
        onPressed: () {},
        label: "Done",
        textColor: Colors.blue,
      ),
    );
  }

  SnackBar isDownloading() {
    return SnackBar(
      duration: const Duration(milliseconds: 3000),
      backgroundColor: Colors.redAccent.withOpacity(0.5),
      content: const Text("다운로드중입니다."),
    );
  }

  SnackBar downloadComplete() {
    return SnackBar(
      duration: const Duration(milliseconds: 1000),
      backgroundColor: Colors.redAccent.withOpacity(0.5),
      content: const Text("다운로드가 완료되었습니다."),
    );
  }

  SnackBar downloadCancel() {
    return SnackBar(
      duration: const Duration(milliseconds: 1000),
      backgroundColor: Colors.redAccent.withOpacity(0.5),
      content: const Text("다운로드 시도를 취소하였습니다."),
    );
  }

  SnackBar requireEditandDownload() {
    return SnackBar(
      duration: const Duration(milliseconds: 3000),
      backgroundColor: Colors.redAccent.withOpacity(0.5),
      content: const Text("수정한 내용이 있습니다. 수정 반영된 문서를 다운로드 시작합니다."),
    );
  }
//★★function 모음 끝★★//
}
//★★_ResultScreen 끝★★//

// ☞ 패턴체크에 필요한 자료를 활용한 모델 클래스

/*class referenceDataModel {
  String? language;
  String? errorType;
  String? wrong;
  String? corrected;

  referenceDataModel(
      {this.language, this.errorType, this.wrong, this.corrected});

  referenceDataModel.fromJson(Map<String, dynamic> json) {
    language = json['Language'];
    errorType = json['Error type'];
    wrong = json['Wrong'];
    corrected = json['Corrected'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['Language'] = this.language;
    data['Error type'] = this.errorType;
    data['Wrong'] = this.wrong;
    data['Corrected'] = this.corrected;
    print(data);
    return data;
  }

}*/
