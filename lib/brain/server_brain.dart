import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:get_ip/get_ip.dart';
import 'package:http_server/http_server.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sharile/brain/html_generator.dart';

class ServerBrain {
  HttpServer _server;
  String _ipAddress = '0.0.0.0';
  HtmlGenerator _htmlGenerator = HtmlGenerator();
  Map<String, String> _filePaths = {};

  startServer({int port}) async {
    // getting Gateway ip Address;
    _ipAddress = await GetIp.ipAddress;
    // Starting the server
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    // Appending the port to the ip Address
    _ipAddress += ':${_server.port}';
    print(_ipAddress);
  }

  stopServer() {
    // Stops the Server
    _server.close();
    // Clear Temporary Files
    FilePicker.platform.clearTemporaryFiles();
    // Deleting all Data in _filePaths
    _filePaths = {};
  }

  sendFile() async {
    // Select Files

    FilePickerResult result = await FilePicker.platform
        .pickFiles(allowMultiple: true, withData: false, withReadStream: true);
    // Converting to Map of <String, String>
    if (result != null) {
      List<String> tempPaths = result.paths;
      List<String> tempNames = result.names;
      for (int i = 0; i < result.count; i++) {
        _filePaths.addAll({'${tempPaths[i]}': tempNames[i]});
        print(_filePaths);
      }
//      _filePaths = Map.fromIterable(result.paths, key: (e) => e)
    }

//    _filePaths = await FilePicker.platform.getMultiFilePath(); //Old Legacy Code of File Picker

    // Creating Virtual Directory
    VirtualDirectory staticFiles = VirtualDirectory('.')
      ..allowDirectoryListing = true
      ..jailRoot = false;

    // Getting dirPath
    String dirPath = (await getExternalStorageDirectory()).path;
    print('DirPath :' + dirPath);

    //Generating index.html for selected files.
    _htmlGenerator.generateSendIndexHtml(filePaths: _filePaths);

    // Writing index.html to dirPath
    _htmlGenerator.writeIndexHTML(path: dirPath);

    // Listening Request
    _server.listen((req) {
      //This is to limit the maximum conneciton
      // active connections 4 means max 3 connection:
      // 1 for browser to view index.html, 2 for downloading
      if (_server.connectionsInfo().active < 5) {
        //Serving index file
        staticFiles.directoryHandler = (dir, request) {
          var indexUri = Uri.file(dir.path).resolve('$dirPath/index.html');
          staticFiles.serveFile(File(indexUri.toFilePath()), request);
        };
        // req.response.write("Reached Maximum Connection Limit");
        // req.response.close();
        // print("Active: ${_server.connectionsInfo().active}");
        // print("Total: ${_server.connectionsInfo().total}");
        // print("Idle: ${_server.connectionsInfo().idle}");
        // print("Closing: ${_server.connectionsInfo().closing}");
        staticFiles.serveRequest(req);
      }
    });
  }

  uploadFile() async {
    Directory rootDir = (await getExternalStorageDirectory());
    print(rootDir.path);
    // Splitting Dir Path
    List<String> dirPathList = rootDir.path.split('/');
    // getting Position of 'Android'
    int posAndroidDir = dirPathList.indexOf('Android');
    // Adding 'SHARiLE' at the position of 'Android'
    dirPathList.insert(posAndroidDir, 'SHARiLE');
    //Joining the List<Strings> to generate the dirPath
    String dirPath = dirPathList.sublist(0, posAndroidDir + 1).join('/');
    print(dirPath);

    //Create Directory on Android Device
    Directory sharileDirPath = Directory(dirPath);
    if (!sharileDirPath.existsSync()) {
      print('Creating Dir');
      await sharileDirPath.create(recursive: true);
//      Directory(dirPath)
//          .create(recursive: true)
//          .then((Directory directory) => print('Path: ${directory.path}'));
      print('Created Dir');
    } else {
      print('Already Existed');
    }

    _server.listen((request) async {
      if (request.uri.path == '/') {
        //starting page to upload file (not accessing endpoint '/upload')
        request.response
          ..headers.contentType = ContentType.html
          //HTML form
          ..write(_htmlGenerator.generateReceiveIndexHtml());
      } else if (request.uri.path == '/app.css') {
        //starting page to upload file (not accessing endpoint '/app.css')
        request.response
          ..headers.contentType = ContentType('text', 'css')
          //CSS style
          ..write(_htmlGenerator.generateReceiveIndexCSS());
      } else if (request.uri.path == '/upload') {
        // accessing 'upload' endpoint
        List<int> dataBytes = [];

        await for (var data in request) {
          // received data but don't know the file name & type
          dataBytes.addAll(data);
        }
        // Converting Data to Stream & getting file name and type
        String boundary = request.headers.contentType.parameters['boundary'];
        final transformer = MimeMultipartTransformer(boundary);

        final bodyStream = Stream.fromIterable([dataBytes]);
        final parts = await transformer.bind(bodyStream).toList();

        for (var part in parts) {
          //getting the content info
          final contentDisposition = part.headers['content-disposition'];
          print(contentDisposition);
          // getting content/file in form of list
          final content = await part.toList();
          // logic to get file name from contentDisposition
          final int startPos =
              contentDisposition.indexOf('filename="') + 'filename="'.length;
          final int endPos = contentDisposition.length - 1;
          // set filename variable
          final filename = contentDisposition.substring(startPos, endPos);
          // Write file to phone storage
          await File('$dirPath/$filename').writeAsBytes(content[0]);
        }
      }
      //closing the request
      await request.response.close();
    });
  }

  getIpAddress() {
    // Returns the Gateway ip Address with port
    return _ipAddress;
  }
}
