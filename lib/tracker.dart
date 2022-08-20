import 'dart:isolate';
import 'dart:ui';
import 'package:background_locator/background_locator.dart';
import 'package:background_locator/location_dto.dart';
import 'package:background_locator/settings/android_settings.dart';
import 'package:background_locator/settings/ios_settings.dart';
import 'package:background_locator/settings/locator_settings.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:salesPlus/core/data/data_model/location.dart';
import 'package:salesPlus/core/di/di.dart';
import 'package:salesPlus/core/service/old_tracker/tracker_callback_handler.dart';
import 'package:salesPlus/core/service/old_tracker/tracker_handler.dart';
import 'package:salesPlus/features/debug/domain/repositories/debug_repository.dart';

class Tracker {
  ReceivePort port = ReceivePort();
  bool? isRunning;
  static LocationDto? lastLocation;

  Tracker() {
    if (IsolateNameServer.lookupPortByName(TrackerHandler.isolateName) !=
        null) {
      IsolateNameServer.removePortNameMapping(TrackerHandler.isolateName);
    }
    IsolateNameServer.registerPortWithName(
        port.sendPort, TrackerHandler.isolateName);
    port.listen((dynamic locationDto) async {
      await _updateNotificationText(locationDto);
      lastLocation = locationDto;
      getIt<DebugRepository>().insertLocation(Location(
          timestamp: DateTime.now().toIso8601String(),
          lat: lastLocation?.latitude,
          lng: lastLocation?.longitude,
          accuracy: lastLocation?.accuracy,
          speed: lastLocation?.speed,
          speedAccuracy: lastLocation?.speedAccuracy,
          heading: lastLocation?.heading,
          altitude: lastLocation?.altitude,
          isMocked: lastLocation?.isMocked,
          provider: lastLocation?.provider));
    });
    _initPlatformState();
  }

  Future<void> _updateNotificationText(LocationDto? locationDto) async {
    if (locationDto == null) {
      return;
    }

    await BackgroundLocator.updateNotificationText(
        title: "new location received",
        msg: "${DateTime.now()}",
        bigMsg: "${locationDto.latitude}, ${locationDto.longitude}");
  }

  Future<void> _initPlatformState() async {
    if (await _checkLocationPermission()) {
      await BackgroundLocator.initialize();
      await _startLocator();
      isRunning = await BackgroundLocator.isServiceRunning();
    } else {
      // show error
    }
  }

  Future<bool> _checkLocationPermission() async {
    final access = await Permission.location.status;
    switch (access) {
      case PermissionStatus.denied:
      case PermissionStatus.restricted:
      case PermissionStatus.limited:
        final permissionStatus = await Permission.location.request();
        if (permissionStatus == PermissionStatus.granted) {
          return true;
        } else {
          return false;
        }
        break;
      case PermissionStatus.granted:
        return true;
        break;
      default:
        return false;
        break;
    }
  }

  Future<void> _startLocator() async {
    Map<String, dynamic> data = {'countInit': 1};
    return await BackgroundLocator.registerLocationUpdate(
        TrackerCallbackHandler.callback,
        initCallback: TrackerCallbackHandler.initCallback,
        initDataCallback: data,
        disposeCallback: TrackerCallbackHandler.disposeCallback,
        iosSettings: const IOSSettings(
            accuracy: LocationAccuracy.NAVIGATION, distanceFilter: 0),
        autoStop: false,
        androidSettings: const AndroidSettings(
            accuracy: LocationAccuracy.NAVIGATION,
            interval: 5,
            distanceFilter: 5,
            client: LocationClient.google,
            androidNotificationSettings: AndroidNotificationSettings(
                notificationChannelName: 'Location tracking',
                notificationTitle: 'Start Location Tracking',
                notificationMsg: 'Track location in background',
                notificationBigMsg:
                    'Background location is on to keep the app up-tp-date with your location. This is required for main features to work properly when the app is not running.',
                notificationIconColor: Colors.grey,
                notificationTapCallback:
                    TrackerCallbackHandler.notificationCallback)));
  }
}
