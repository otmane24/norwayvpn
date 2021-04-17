import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
  FileType _pickType = FileType.any;
  ListResult list;
  List listItem = [];
  // ignore: deprecated_member_use
  List<UploadTask> uploadedTasks = List();
  // ignore: deprecated_member_use
  List<File> selectedFiles = List();
  UploadTask task ;
  String nameFile ;

  writeFileToStorage(fileUrl) {
    _firebaseFirestore.collection("vpn").add({"url": fileUrl}).whenComplete(
        () => print("$fileUrl is saved in firestore"));
  }

  saveFileUrlToFirebase(UploadTask task) {
    task.snapshotEvents.listen((snapShot) {
      if (snapShot.state == TaskState.success) {
        snapShot.ref
            .getDownloadURL()
            .then((fileUrl) => writeFileToStorage(fileUrl));
      }
    });
  }

  uploadFileToStorage(File file) {
    UploadTask task = _firebaseStorage
        .ref()
        .child("${nameFile.toString()}")
        .putFile(file);
    task.snapshotEvents.listen((event) {
      print("cas ::{$event.state.toString()}");
    });
    // not valide
    StreamBuilder<TaskSnapshot>(
        builder: (context , snapShot){
          return AlertDialog(
              content:Text(snapShot.data.state == TaskState.success ?
              "Completed" :
              snapShot.data.state == TaskState.running ? "In Progress" : "Error")
          );
        }
    );
    // not valide 
    return task;
  }

  Future selectFileToUpload() async {
    try {
      FilePickerResult result = await FilePicker.platform
          .pickFiles(allowMultiple: true, type: _pickType);
      List <String> name = result.names.toList();
      nameFile = name.asMap().values.toString().replaceAll(")", "").replaceAll("(", "") ;
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
            uploadedTasks.add(task);
          });
        });
      } else {
        print('error');
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    FirebaseStorage.instance.ref().listAll().then((value) {
      setState(() {
        list = value;
        //print("index : ${list.items.length}");
        for (int index = 0; index < list.items.length; index++) {
          listItem.add(list.items
              .asMap()
              .values
              .elementAt(index)
              .fullPath
              .replaceAll(".ovpn", ""));
        }
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: selectFileToUpload,
          tooltip: 'Add server',
          child: Icon(Icons.add),
        ),
        body: uploadedTasks.length == 0
            ? Center(
                child: Text("Import a server "),
              )
            : ListView.separated(
            itemBuilder: (context, index){
              return StreamBuilder<TaskSnapshot>(
                builder: (context, snapShot) {
                  return
                    snapShot.hasError
                        ? AlertDialog(content: Text("There is some error in uploading file"))
                        : snapShot.hasData ?
                       /* Center(
                          child: LinearProgressIndicator(
                            value: snapShot.data.bytesTransferred.ceilToDouble(),
                          ),
                        )*/
                  Container(
                    // TODO
                    child: ListTile(
                      title: Text('Upload Task #${task.hashCode}'),
                      subtitle: Text("text"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                            Container(
                              child: IconButton(
                                  icon: Icon(Icons.add),
                                  onPressed: () => task.cancel()),
                            )
                        ],
                      ),
                    ),
                   /* Center(
                      child: AlertDialog (
                        content: Text("${snapShot.data.bytesTransferred}/${snapShot.data.totalBytes} ${snapShot
                            .data.state == TaskState.success ? "Completed" : snapShot.data.state == TaskState.running ? "In Progress" : "Error"}"),
                      ),*/
                    ) : Container();
                },
                stream: uploadedTasks[index].snapshotEvents,
              );
            },
            separatorBuilder: (context , index) => Divider() ,
            itemCount: uploadedTasks.length
        )
        // This trailing comma makes auto-formatting nicer for build methods.
        );
  }
}
