import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geofence_service/geofence_service.dart';

const kPrimaryColor = Color(0xFFFC5C5E);
const kSecondaryColor = Color(0xFFFF601F);
const mainTextColor = Color(0xFF4B4A4A);
const darkTextColor = Color(0xFF1A1A1A);
const softTextColor = Color(0xFF777A7D);
const mainBackColor = Color(0xFFF2F6FF);
const secBackColor = Color(0xFFF5F5F5);
const orgMainColor = Color(0xFF2B65EC);
const descColor = Color(0xFF8D8D8D);
const searchBorder = Color(0xFFACABAB);

var initialRouteIncrement = 0;
var currentIndex = 0;
const double defaultPadding = 16.0;

/// Global variables
/// * [GlobalKey<NavigatorState>]
class GlobalVariable {

  /// This global key is used in material app for navigation through firebase notifications.
  /// [navState] usage can be found in [notification_notifier.dart] file.
  static final GlobalKey<NavigatorState> navState = GlobalKey<NavigatorState>();
}


