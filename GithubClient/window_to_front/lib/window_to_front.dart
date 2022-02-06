import 'dart:async';

import 'package:flutter/services.dart';

class WindowToFront {
  static const MethodChannel _channel = MethodChannel('window_to_front');

  static Future<void> activate() {
    return _channel.invokeMethod('activate');
  }
}
