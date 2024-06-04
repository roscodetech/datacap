import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:media_upload/services/upload_services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:provider/provider.dart';

import '../models/media_data.dart';
import '../providers/media_provider.dart';

class PhotoScreen extends StatelessWidget {
  static const routeName = '/home';

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
                      icon: const Icon(Icons.camera),
                      label: const Text('Photo'),
                      onPressed: () => _pickMedia(ImageSource.camera, false),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Photo from Gallery'),
                      onPressed: () => _pickMedia(ImageSource.gallery, false),
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
              leading: media.filePath.endsWith('.mp4')
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
