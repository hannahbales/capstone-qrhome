import 'classes.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';

class FilesForm extends StatefulWidget {
  final ApplicationData data;

  const FilesForm({Key? key, required this.data}) : super(key: key);
  @override
  _FilesFormState createState() => _FilesFormState();
}

class _FilesFormState extends State<FilesForm> {
  File? pickedFile;

  // Function to pick a file using the file_picker
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      PlatformFile file = result.files.first;
      setState(() {
        pickedFile = File(file.path!);
      });
      print('File picked: ${file.name}');
      // TODO: Handle the picked file, move it to uploads?
    }
  }

 @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Button to pick a file
        ElevatedButton(
          onPressed: _pickFile,
          child: Text('Pick File'),
        ),
        SizedBox(height: 16),

        // Display the selected file based on platform (web or mobile)
        if (pickedFile != null) ...[
          if (!kIsWeb) 
            Image.file(pickedFile!),

          if (kIsWeb) 
          Text('Selected file: ${pickedFile!.path}'),
        ],

        Text("Please upload documents here"),
      ],
    );
  }
}