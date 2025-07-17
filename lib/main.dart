import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:targetteam_multiplatform/TargetTeamApp.dart';
import 'package:targetteam_multiplatform/position_provider.dart';


void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => PositionProvider.instance,
      child: const TargetTeamApp(),
    ),
  );
}

//TODO: Add the abiity to click the radio lable to change value