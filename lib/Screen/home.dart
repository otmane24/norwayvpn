import 'dart:async';
import 'dart:io';

import 'package:connectivity/connectivity.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Home extends StatefulWidget {
  Home({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  FirebaseStorage _firebaseStorage = FirebaseStorage.instance;
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  FileType _pickType = FileType.any;
  ListResult list;
  List nameServer = [];
  List urlServer = [];
  String path;
  // ignore: deprecated_member_use
  List<UploadTask> uploadedTasks = List();
  // ignore: deprecated_member_use
  List<File> selectedFiles = List();
  UploadTask task;
  String nameFile;

  @override
  void initState() {
    checkConnection();
    _connectivity.onConnectivityChanged.listen(_connectionChange);
    nameServer.clear();
    super.initState();
  }

  Future<void> _showAlertDialogDelete(
      List nameServer, List urlServer, int index, String filePath) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Delete Server",
          ),
          content: Text(
            "Do you want to delete ${nameServer[index]} ?",
          ),
          actions: [
            // ignore: deprecated_member_use
            RaisedButton(
                child: Text(
                  "No",
                ),
                onPressed: () {
                  return Navigator.of(context).pop();
                }),
            // ignore: deprecated_member_use
            RaisedButton(
                child: Text("Yes"),
                onPressed: () {
                  deleteServer(
                    nameServer,
                    urlServer,
                    index,
                    urlServer[index],
                  );
                  Navigator.of(context).pop();
                }),
          ],
        );
      },
    );
  }

  Future<void> _showAlertDialogUploading(UploadTask task) async {
    return showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return Container(
            height: 100,
            child: AlertDialog(
              title: Text("Delete Server"),
              content: StreamBuilder<TaskSnapshot>(
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
                            style: TextStyle(
                                fontSize: 24, color: Colors.blueAccent),
                          ),
                          SizedBox(
                            height: 15.0,
                          ),
                          LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: Colors.white,
                            valueColor:
                                AlwaysStoppedAnimation(Colors.deepOrange),
                          ),
                          SizedBox(
                            height: 15.0,
                          ),
                          Text(
                            '$percentage %',
                            style: TextStyle(
                                fontSize: 24, color: Colors.blueAccent),
                          )
                        ],
                      );
                    } else {
                      return Container();
                    }
                  }),
            ),
          );
        });
  }

  deleteServer(
      List nameServer, List urlServer, int index, String filePath) async {
    await _firebaseStorage.refFromURL(filePath).delete();
    setState(() {
      uploadedTasks.removeAt(index);
      nameServer.removeAt(index);
      urlServer.removeAt(index);
    });
    print(
        "name : ${uploadedTasks.asMap().values} \n url : ${urlServer.length}");
    // ignore: deprecated_member_use
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      backgroundColor: Colors.grey[900],
      duration: Duration(
        milliseconds: 900,
      ),
      content: Container(
        height: 20,
        child: Center(
            child: Text(
          "Delete success",
          style: TextStyle(fontSize: 20, color: Colors.deepOrange),
        )),
      ),
    ));
    int i, j = 0;
    while (j < nameServer.length) {
      if (nameServer[j] != '') {
        nameServer[i] = nameServer[j];
        uploadedTasks[i] = uploadedTasks[j];
        urlServer[i] = urlServer[j];
        i++;
        j++;
      } else {
        j++;
      }
    }
  }

  saveFileUrlToFirebase(UploadTask task, bool state) {
    if (state) {
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
      _scaffoldKey.currentState.showSnackBar(
        SnackBar(
          backgroundColor: Colors.black54,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 8.0,
                          ),
                          child: Text(
                            'Uploading:',
                            style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        SizedBox(
                          height: 18.0,
                        ),
                        LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.white,
                          valueColor: AlwaysStoppedAnimation(Colors.deepOrange),
                        ),
                        SizedBox(
                          height: 18.0,
                        ),
                        Center(
                          child: Text(
                            '$percentage %',
                            style: TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      ],
                    );
                  } else {
                    return Container();
                  }
                }),
          ),
        ),
      );
      // ignore: deprecated_member_use
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        backgroundColor: Colors.grey[900],
        duration: Duration(milliseconds: 900),
        content: Container(
          height: 20,
          child: Center(
              child: Text(
            "The Upload Success",
            style: TextStyle(fontSize: 20, color: Colors.deepOrange),
          )),
        ),
      ));
    }
  }

  uploadFileToStorage(File file, String filename) {
    UploadTask task = _firebaseStorage.ref().child(filename).putFile(file);
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
      if (name.first.contains(".ovpn")) {
        nameFile = name
            .asMap()
            .values
            .toString()
            .replaceAll(")", "")
            .replaceAll("(", "");
        if (nameServer.contains(
            "${nameFile.substring(0, 1).toUpperCase()}${nameFile.substring(1).replaceAll('.ovpn', "")}")) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("Failed"),
                content: Text("The selected file is exist"),
                actions: [
                  // ignore: deprecated_member_use
                  RaisedButton(
                      child: Text("Ok"),
                      onPressed: () {
                        return Navigator.of(context).pop();
                      }),
                ],
              );
            },
          );
        } else if (result != null) {
          selectedFiles.clear();
          result.files.forEach((selectedFile) {
            File file = File(selectedFile.path);
            selectedFiles.add(file);
          });
          selectedFiles.forEach((file) {
            final UploadTask task = uploadFileToStorage(file, nameFile);
            saveFileUrlToFirebase(task, true);

            setState(() {
              nameServer.add(
                  "${nameFile.replaceAll(".ovpn", "").substring(0, 1).toUpperCase()}" +
                      "${nameFile.replaceAll(".ovpn", "").substring(1)}");
              uploadedTasks.add(task);
            });
          });
        } else {
          print('error');
        }
      } else {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("Failed"),
                content: Text("The selected file is not a vpn config"),
                actions: [
                  // ignore: deprecated_member_use
                  RaisedButton(
                      child: Text("Ok"),
                      onPressed: () {
                        return Navigator.of(context).pop();
                      }),
                ],
              );
            });
      }
    } catch (e) {
      print('error : $e');
    }
  }

  Future downLoadServer(String vpnItem) async {
    try {
      Reference reference = _firebaseStorage.ref().child('$vpnItem.ovpn');
      String url = await reference.getDownloadURL();

      final http.Response downLoadData = await http.get(url);
      final Directory systemTempDir = Directory.systemTemp;
      final File tempFile = File('${systemTempDir.path}/$vpnItem.ovpn');
      if (tempFile.existsSync()) {
        await tempFile.delete();
      }
      await tempFile.create();
      await tempFile.writeAsStringSync(downLoadData.body);

      final UploadTask task = uploadFileToStorage(tempFile, '$vpnItem.ovpn');
      saveFileUrlToFirebase(task, false);
      setState(() {
        urlServer.add(url);
        uploadedTasks.add(task);
      });
    } catch (e) {
      print("Error function download: ${e.toString()}");
    }
  }

  //--------------------------------------------------
  bool hasConnection = false;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult> subscription;

  Stream get connectionChange => connectionChangeController.stream;
  StreamController connectionChangeController = StreamController.broadcast();

  void _connectionChange(ConnectivityResult result) async {
    bool newStateConnection = await checkConnection();
    setState(() {
      hasConnection = newStateConnection;
    });
    if (hasConnection) {
      FirebaseStorage.instance.ref().listAll().then(
        (value) {
          setState(() async {
            list = value;
            for (int index = 0; index < list.items.length; index++) {
              await downLoadServer(
                list.items
                    .asMap()
                    .values
                    .elementAt(index)
                    .fullPath
                    .replaceAll(".ovpn", ""),
              );
              nameServer.add(
                  "${list.items.asMap().values.elementAt(index).fullPath.replaceAll(".ovpn", "").substring(0, 1).toUpperCase()}"
                  "${list.items.asMap().values.elementAt(index).fullPath.replaceAll(".ovpn", "").substring(1)}");
              print(nameServer[index]);
            }
          });
        },
      );
    }
  }

  Future<bool> checkConnection() async {
    bool previousConnection = hasConnection;

    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        setState(() {
          hasConnection = true;
        });
      } else {
        setState(() {
          hasConnection = false;
        });
      }
    } on SocketException catch (_) {
      setState(() {
        hasConnection = false;
      });
    }

    //The connection status changed send out an update to all listeners
    if (previousConnection != hasConnection) {
      connectionChangeController.add(hasConnection);
    }

    return hasConnection;
  }

  //--------------------------------------------------

  @override
  void dispose() async {
    // TODO: implement dispose
    super.dispose();
    //connectionChangeController.close();
    await subscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    //sleep(Duration(seconds: 5));
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: hasConnection
          ? FloatingActionButton(
              onPressed: () {
                selectFileToUpload();
              },
              tooltip: 'Add Server',
              child: Icon(Icons.add),
            )
          : null,
      body: hasConnection
          ? uploadedTasks.length == 0
              ? Center(
                  child: Text(
                    "Import Server",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : ListView.separated(
                  itemBuilder: (context, index) {
                    return StreamBuilder<TaskSnapshot>(
                      builder: (context, snapShot) {
                        if (snapShot.hasError) {
                          return Text(
                            "There is some error in uploading file",
                          );
                        } else {
                          //
                          // sleep(Duration(seconds: 5));
                          return snapShot.hasData && index >= 0
                              ? Container(
                                  child: ListTile(
                                    title: Padding(
                                      padding: const EdgeInsets.only(
                                        left: 10,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          left: 8.0,
                                        ),
                                        child: Text(
                                          nameServer[index],
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Container(
                                          child: IconButton(
                                            icon: Icon(Icons.clear),
                                            color: Colors.deepOrange[400],
                                            onPressed: () {
                                              _showAlertDialogDelete(
                                                nameServer,
                                                urlServer,
                                                index,
                                                urlServer[index],
                                              ); // deleteServer(nameServer,urlServer,index,urlServer[index]);
                                            },
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                )
                              : Container();
                        }
                      },
                      stream: uploadedTasks[index].snapshotEvents,
                    );
                  },
                  separatorBuilder: (context, index) => Divider(),
                  itemCount: nameServer.length,
                )
          : Center(
              child: Text(
                "There is no internet connection",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
/*
class DialogAlert {
  DialogAlert(this.context);

  final BuildContext context ;

  void hindAlert() {
    return Navigator.of(context).pop();
  }

  Future< void > _showAlertGialogUploading(UploadTask task) async {
    return showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return Container(
            height: 100,
            child: AlertDialog(

              title: Text("Delte Server"),
              content:  StreamBuilder<TaskSnapshot>(
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
                          LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: Colors.white,
                            valueColor: AlwaysStoppedAnimation(Colors.deepOrange),
                          ),
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
                    }  else {
                      return Container();
                    }
                  }),

            ),
          );
        });
  }

}*/
