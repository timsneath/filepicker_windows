import 'dart:io';

import 'package:flutter/material.dart';
import 'package:filepicker_windows/filepicker_windows.dart' as picker;

import 'wallpaper.dart';

void main() => runApp(FilePickerExample());

class FilePickerExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(home: HomePage());
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? path;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(path != null ? path.toString() : 'Select a file'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height / 2,
                width: MediaQuery.of(context).size.width - 100,
                child: path == null ? const Placeholder() : Image.file(path!),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        final file = picker.OpenFilePicker();
                        file.hidePinnedPlaces = true;
                        file.forcePreviewPaneOn = true;
                        file.filterSpecification = {
                          'JPEG Files': '*.jpg;*.jpeg',
                          'Bitmap Files': '*.bmp',
                          'All Files (*.*)': '*.*'
                        };
                        file.title = 'Select an image';
                        final result = file.getFiles();
                        if (result != null) {
                          setState(() {
                            path = result.first;
                          });
                        }
                      },
                      child: const Text('Open file dialog'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (path != null) {
                          Wallpaper.set(path!);
                        }
                      },
                      child: const Text('Set Wallpaper'),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
