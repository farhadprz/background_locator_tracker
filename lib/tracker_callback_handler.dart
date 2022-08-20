import 'dart:async';

import 'package:background_locator/location_dto.dart';

import 'tracker_handler.dart';

class TrackerCallbackHandler {
  static Future<void> initCallback(Map<dynamic, dynamic> params) async {
    TrackerHandler trackerRepository = TrackerHandler();
    await trackerRepository.init(params);
  }

  static Future<void> disposeCallback() async {
    TrackerHandler trackerRepository = TrackerHandler();
    await trackerRepository.dispose();
  }

  static Future<void> callback(LocationDto locationDto) async {
    TrackerHandler trackerRepository = TrackerHandler();
    await trackerRepository.callback(locationDto);
  }

  static Future<void> notificationCallback() async {
    print('***notificationCallback');
  }
}
