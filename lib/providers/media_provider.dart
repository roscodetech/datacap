import 'package:flutter/material.dart';

import '../models/media_data.dart';

class MediaProvider with ChangeNotifier {
  final List<MediaData> _mediaList = [];

  List<MediaData> get mediaList => _mediaList;

  void addMedia(MediaData mediaData) {
    _mediaList.add(mediaData);
    notifyListeners();
  }
}
