import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

bool get isIOS => defaultTargetPlatform == TargetPlatform.iOS;
bool get isAndroid => defaultTargetPlatform == TargetPlatform.android;
