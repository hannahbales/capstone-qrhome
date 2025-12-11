import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

const devAPIPort = 3456;

String? localhost;

bool isInTest() {
  try {
    // Platform.environment isn't allowed in web
    return Platform.environment.containsKey('FLUTTER_TEST');
  } catch (e) {
    return false;
  }
}

Future<String> getApiUrl() async {
  if (localhost == null) {
    if (!isInTest()) {
      if (kDebugMode && !kIsWeb) {
        final plugin = DeviceInfoPlugin();
        if (Platform.isAndroid) {
          final info = await plugin.androidInfo;
          if (!info.isPhysicalDevice) {
            localhost = 'http://10.0.2.2:$devAPIPort';
          }
        }
      } else if (!kDebugMode) {
        // TODO: Return the url that we'll use in production.
        localhost = '.';
      }
    }

    // Default url to use while debugging.
    localhost ??= 'http://localhost:$devAPIPort';
  }
  print('Url: $localhost');
  return localhost!;
}

Future<String> getPageUrl() async {
  if (kIsWeb) {
    return Uri.base.toString();
  } else {
    // TODO: This needs to be updated to use the correct URL for mobile apps.
    return 'https://sdp.boisestate.edu/s25-stack-overflow-survivors/';
  }
}
