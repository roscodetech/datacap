import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:media_upload/services/upload_services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/media_data.dart';
import '../providers/media_provider.dart';

class VideoScreen extends StatelessWidget {
  static const routeName = '/video-screen';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Media Upload App')),
      body: Column(
        children: [
          Expanded(child: MediaList()),
          Flexible(
            fit: FlexFit.loose,
            child: MediaInput(),
          ),
        ],
      ),
    );
  }
}

class MediaInput extends StatefulWidget {
  @override
  _MediaInputState createState() => _MediaInputState();
}

class _MediaInputState extends State<MediaInput> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _animalController = TextEditingController();
  final TextEditingController _farmController = TextEditingController();

  Future<void> _pickMedia(ImageSource source) async {
    try {
      // Request permissions
      await [
        Permission.camera,
        Permission.storage,
        Permission.microphone,
      ].request();

      final pickedFile = await _picker.pickVideo(source: source);

      if (pickedFile == null) {
        print('No video selected.');
        return;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final fileName = pickedFile.path.split('/').last;
      final savedFile =
          await File(pickedFile.path).copy('${appDir.path}/$fileName');

      final mediaData = MediaData(
        filePath: savedFile.path,
        animalName: _animalController.text,
        farmName: _farmController.text,
        timestamp: DateTime.now(),
        isVideo: true,
      );

      Provider.of<MediaProvider>(context, listen: false).addMedia(mediaData);
      print('Video saved to: ${savedFile.path}');
    } catch (e) {
      print('Error picking video: $e');
    }
  }

  Future<void> _uploadAllMedia(BuildContext context) async {
    final mediaList =
        Provider.of<MediaProvider>(context, listen: false).mediaList;
    final uploadService = UploadService();

    for (var media in mediaList) {
      await uploadService.uploadMedia(media);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _animalController,
            decoration: const InputDecoration(labelText: 'Animal Name'),
          ),
          TextField(
            controller: _farmController,
            decoration: const InputDecoration(labelText: 'Farm Name'),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.video_call),
                      label: const Text('Record Video'),
                      onPressed: () => _pickMedia(ImageSource.camera),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.video_library),
                      label: const Text('Pick Video from Gallery'),
                      onPressed: () => _pickMedia(ImageSource.gallery),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.upload),
                  label: const Text('Upload'),
                  onPressed: () => _uploadAllMedia(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MediaList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<MediaProvider>(
      builder: (ctx, mediaProvider, child) {
        return ListView.builder(
          itemCount: mediaProvider.mediaList.length,
          itemBuilder: (ctx, index) {
            final media = mediaProvider.mediaList[index];
            return ListTile(
              leading: media.isVideo
                  ? const Icon(Icons.video_library)
                  : Image.file(File(media.filePath), width: 50, height: 50),
              title: Text(media.animalName),
              subtitle: Text('${media.farmName} - ${media.timestamp}'),
            );
          },
        );
      },
    );
  }
}
