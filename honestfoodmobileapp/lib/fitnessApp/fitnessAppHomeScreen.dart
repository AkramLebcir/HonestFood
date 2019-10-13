import 'dart:convert';
import 'dart:io';

import 'package:best_flutter_ui_templates/fitnessApp/models/tabIconData.dart';
import 'package:best_flutter_ui_templates/fitnessApp/traning/trainingScreen.dart';
import 'package:flutter/material.dart';
import 'bottomNavigationView/bottomBarView.dart';
import 'fintnessAppTheme.dart';
import 'myDiary/myDiaryScreen.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toast/toast.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:io';


class FitnessAppHomeScreen extends StatefulWidget {
  @override
  _FitnessAppHomeScreenState createState() => _FitnessAppHomeScreenState();
}

class _FitnessAppHomeScreenState extends State<FitnessAppHomeScreen>
    with TickerProviderStateMixin {

   File _image;
   String test = "chakla";
   String food_class="";
   List<ImageLabel> _labels;
  AnimationController animationController;

  List<TabIconData> tabIconsList = TabIconData.tabIconsList;

  Widget tabBody = Container(
    color: FintnessAppTheme.background,
  );

  @override
  void initState() {
    
    tabIconsList.forEach((tab) {
      tab.isSelected = false;
    });
    tabIconsList[0].isSelected = true;

    animationController =
        AnimationController(duration: Duration(milliseconds: 600), vsync: this);
    tabBody = MyDiaryScreen(animationController: animationController);
    super.initState();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: FintnessAppTheme.background,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: FutureBuilder(
          future: getData(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return SizedBox();
            } else {
              return Stack(
                children: <Widget>[
                  tabBody,
                  bottomBar(),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Future<bool> getData() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return true;
  }

    Map _object;
  Map<String, double> dataMap = new Map();
  bool isLoad = false;

   Future recognizeImage(File image) async {
     print("aaaaaaaaaaaaaaaaaaaaapppppppppppppppp");
    // Toast.show("You clicker me", context);
    String apiUrl = 'https://sirbmvp-249122.appspot.com/api/image';
    final length = await image.length();
    final request = new http.MultipartRequest('POST', Uri.parse(apiUrl))
      ..files.add(new http.MultipartFile('image',
          image.openRead(),
          length,
          filename: image.path,
          contentType: new MediaType('image', 'jpeg')));
    http.Response response = await http.Response.fromStream(await request.send());
    print("Result: ${response.body}");
    setState(() {
      _object = jsonDecode(response.body);
      double accuracy = (double.parse((_object['arr'][1]).toString())*100);
       setState(() {
          food_class = (_object['arr'][0]).toString();   
       });
      print("Food class is "+food_class.toString());
      Toast.show("Food class is "+food_class.toString(), context);
      //dataMap.remove("CN");
      //dataMap.remove("NI");
      //dataMap.putIfAbsent("NI", () => a);
      //dataMap.putIfAbsent("CN", () => b);
      isLoad = true;
      
      _showModalBottomSheetfilter();
    });
  }

  void _showModalBottomSheetfilter() {
    showModalBottomSheet(
        context: context,
        builder: (builder) {
          return new Container(
            height: 150.0,
            color: Colors.black54,
            child: new Container(
                padding: const EdgeInsets.all(30.0),
                decoration: new BoxDecoration(
                    color: Colors.white,
                    borderRadius: new BorderRadius.only(
                        topLeft: const Radius.circular(20.0),
                        topRight: const Radius.circular(20.0))),
                child: Container(
                    child: _object['arr'] == null ? Text(""):
                    Align(
  alignment: Alignment.center, // Align however you like (i.e .centerRight, centerLeft)
  child: Text(food_class,style: TextStyle(fontSize: 20.0,fontWeight: FontWeight.bold),),
),
                )
            ),
          );
        });
  }
  
  Widget bottomBar() {
    return Column(
      children: <Widget>[
        Expanded(
          child: SizedBox(),
        ),
        BottomBarView(
          tabIconsList: tabIconsList,
          addClick: () async {
            print("alooooha");
            _image = await ImagePicker.pickImage(source: ImageSource.camera);
              setState(() {
                _image = _image;
              });
              recognizeImage(_image);
              
          },
          changeIndex: (index) {
            if (index == 0 || index == 2) {
              animationController.reverse().then((data) {
                if (!mounted) return;
                setState(() {
                  tabBody =
                      MyDiaryScreen(animationController: animationController);
                });
              });
            } else if (index == 1 || index == 3) {
              animationController.reverse().then((data) {
                if (!mounted) return;
                setState(() {
                  tabBody =
                      TrainingScreen(animationController: animationController);
                });
              });
            }
          },
        ),
      ],
    );
  }
}
