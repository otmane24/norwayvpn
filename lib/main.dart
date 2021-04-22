import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:liquid_progress_indicator/liquid_progress_indicator.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FirebaseStorage _firebaseStorage = FirebaseStorage.instance;
  FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  GlobalKey _sAlertDialogKey = GlobalKey();
  FileType _pickType = FileType.any;
  ListResult list;
  List listItem = [];
  List nameServer = [];
  List urlServer = [];
  String path;
  // ignore: deprecated_member_use
  List<UploadTask> uploadedTasks = List();
  // ignore: deprecated_member_use
  List<File> selectedFiles = List();
  UploadTask task;
  String nameFile;

  get myStream => null;

  Future<void> _showAlertGialog(
      List nameServer, List urlServer, int index, String filePath) async {
    return showDialog<void>(

        context: context,
        barrierDismissible: true,
        builder: (context) {
          return AlertDialog(
           
            title: Text("Delete Server"),
            content: Text("Do you want to delete ${nameServer[index]} ?"),
            actions: [
              // ignore: deprecated_member_use
              RaisedButton(child: Text("No"), onPressed: (){
                  return Navigator.of(context).pop();   
              }
              ),
              // ignore: deprecated_member_use
              RaisedButton(
                  child: Text("Yes"),
                  onPressed: () {
                    deleteServer(
                        nameServer, urlServer, index, urlServer[index]);
                    Navigator.of(context).pop();
                  }
          ),
            ],
          );
        });
  }

  deleteServer(
      List nameServer, List urlServer, int index, String filePath) async {
    await _firebaseStorage.refFromURL(filePath).delete();
    setState(() {
      nameServer.removeAt(index);
      urlServer.removeAt(index);
    });
    print(
        "name : ${uploadedTasks.asMap().values} \n url : ${urlServer.length}");
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      duration: Duration(milliseconds: 600),
      content: Container(
        height: 20,
        child: Center(
            child: Text(
          "Delete success",
          style: TextStyle(fontSize: 20),
        )),
      ),
    ));
  }

  writeFileToStorage(fileUrl) {
    path = fileUrl;
  }

  saveFileUrlToFirebase(UploadTask task) {
    task.snapshotEvents.listen((snapShot) {
      if (snapShot.state == TaskState.success) {
        snapShot.ref.getDownloadURL().then((fileUrl) {
          setState(() {
            //nameServer.single();
            urlServer.add(fileUrl);
          });
        });
      }
    });
    _scaffoldKey.currentState.showSnackBar(SnackBar(
        backgroundColor: Colors.transparent,
        content: Center(
          child: StreamBuilder<TaskSnapshot>(
              stream: task.snapshotEvents,
              builder: (context, snapShot) {
                if (snapShot.hasData) {
                  final snap = snapShot.data;
                  final progress = snap.bytesTransferred / snap.totalBytes;
                  final percentage = (progress * 100).toStringAsFixed(2);
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Uploading :',
                        style:
                            TextStyle(fontSize: 24, color: Colors.blueAccent),
                      ),
                      SizedBox(
                        height: 15.0,
                      ),
                        LiquidLinearProgressIndicator(
                          value: 0.5, // Defaults to 0.5.
                          valueColor: AlwaysStoppedAnimation(Colors.black), // Defaults to the current Theme's accentColor.
                          backgroundColor: Colors.white, // Defaults to the current Theme's backgroundColor.
                          borderColor: Colors.deepPurpleAccent,
                          borderWidth: 1.0,
                          borderRadius: 2.0,
                          direction: Axis.vertical, // The direction the liquid moves (Axis.vertical = bottom to top, Axis.horizontal = left to right). Defaults to Axis.horizontal.
                          center: Text("Loading..."),
                        ),

                     /* LinearProgressIndicator(
                        value: progress,
                        minHeight: 5.5,
                        backgroundColor: Colors.white,
                        semanticsLabel: "up",
                        semanticsValue: "up",
                      ), */
                      SizedBox(
                        height: 15.0,
                      ),
                      Text(
                        '$percentage %',
                        style:
                            TextStyle(fontSize: 24, color: Colors.blueAccent),
                      )
                    ],
                  );
                } else {
                  return Container();
                }
              }),
        ))); 
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      duration: Duration(milliseconds: 600),
      content: Container(
        height: 20,
        child: Center(
            child: Text(
          "The upload success",
          style: TextStyle(fontSize: 20),
        )),
      ),
    ));
  }

  uploadFileToStorage(File file) {
    UploadTask task =
        _firebaseStorage.ref().child("${nameFile.toString()}").putFile(file);
    task.snapshotEvents.listen((event) {
      print("cas ::{$event.state.toString()}");
    });
    _firebaseStorage.setMaxUploadRetryTime(Duration(seconds: 2));
    return task;
  }

  Future selectFileToUpload() async {
    try {
      FilePickerResult result = await FilePicker.platform
          .pickFiles(allowMultiple: false, type: _pickType);
      List<String> name = result.names.toList();
      nameFile = name
          .asMap()
          .values
          .toString()
          .replaceAll(")", "")
          .replaceAll("(", "");
      if (result != null) {
        selectedFiles.clear();
        result.files.forEach((selectedFile) {
          File file = File(selectedFile.path);
          selectedFiles.add(file);
        });
        selectedFiles.forEach((file) {
          final UploadTask task = uploadFileToStorage(file);
          saveFileUrlToFirebase(task);

          setState(() {
            nameServer.add(nameFile);
            uploadedTasks.add(task);
          });
        });
      } else {
        print('error');
      }
    } catch (e) {
      print('eorre : $e');
    }
  }

  @override
  void initState() {
    FirebaseStorage.instance.ref().listAll().then((value) {
      setState(() {
        list = value;
        for (int index = 0; index < list.items.length; index++) {
          nameServer.add(list.items
              .asMap()
              .values
              .elementAt(index)
              .fullPath
              .replaceAll(".ovpn", ""));
          print(nameServer[index]);

        }
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          selectFileToUpload();
        },
        tooltip: 'Add server',
        child: Icon(Icons.add),
      ),
      body: nameServer.length == 0
          ? Center(
              child: Text(
                "Import Server",
                style: TextStyle(fontSize: 20),
              ),
            )
          : ListView.separated(
              itemBuilder: (context, index) {
                return StreamBuilder<TaskSnapshot>(
                  builder: (context, snapShot) {
                    if (snapShot.hasError) {
                      return AlertDialog(
                          content:
                              Text("There is some error in uploading file"));
                    } else {
                      return snapShot.hasData
                          ? (Container(
                              child: ListTile(
                                title: Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: Text(
                                    nameServer[index],
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Container(
                                      child: IconButton(
                                          icon: Icon(Icons.clear),
                                          onPressed: () {
                                            _showAlertGialog(
                                                nameServer,
                                                urlServer,
                                                index,
                                                urlServer[
                                                    index]); // deleteServer(nameServer,urlServer,index,urlServer[index]);
                                          }),
                                    )
                                  ],
                                ),
                              ),
                            ))
                          : Container();
                    }
                  },
                  stream: myStream ,
                );
              },
              separatorBuilder: (context, index) => Divider(),
              itemCount: nameServer.length),

      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
