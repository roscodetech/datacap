import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:media_upload/services/upload_services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:provider/provider.dart';

import './models/media_data.dart';
import './providers/media_provider.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Media Upload App')),
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

  Future<void> _pickMedia(ImageSource source, bool isVideo) async {
    final pickedFile = isVideo
        ? await _picker.pickVideo(source: source)
        : await _picker.pickImage(
            source: source,
            maxWidth: 600,
            imageQuality: 85,
          );

    if (pickedFile == null) {
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
      isVideo: isVideo, // Ensure this field is set correctly
    );

    Provider.of<MediaProvider>(context, listen: false).addMedia(mediaData);
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
      padding: EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _animalController,
            decoration: InputDecoration(labelText: 'Animal Name'),
          ),
          TextField(
            controller: _farmController,
            decoration: InputDecoration(labelText: 'Farm Name'),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.camera),
                      label: Text('Photo'),
                      onPressed: () => _pickMedia(ImageSource.camera, false),
                    ),
                    ElevatedButton.icon(
                      icon: Icon(Icons.video_call),
                      label: Text('Video'),
                      onPressed: () => _pickMedia(ImageSource.camera, true),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.photo_library),
                      label: Text('Photo from Gallery'),
                      onPressed: () => _pickMedia(ImageSource.gallery, false),
                    ),
                    ElevatedButton.icon(
                      icon: Icon(Icons.video_library),
                      label: Text('Video from Gallery'),
                      onPressed: () => _pickMedia(ImageSource.gallery, true),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.upload),
                  label: Text('Upload'),
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
              leading: media.filePath.endsWith('.mp4')
                  ? Icon(Icons.video_library)
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
