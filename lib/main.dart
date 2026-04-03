import 'package:TargetTeam/AppInfo.dart';
import 'package:TargetTeam/TargetTeamApp.dart';
import 'package:TargetTeam/position_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appInfo = await AppInfo.load();
  runApp(
    ChangeNotifierProvider(
      create: (_) => PositionProvider.instance,
      child: TargetTeamApp(appInfo: appInfo),
    ),
  );

}