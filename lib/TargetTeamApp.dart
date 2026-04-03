import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'position_provider.dart';

class TargetTeamApp extends StatelessWidget {
  const TargetTeamApp({super.key});

  static final String name = "Target Team v2.0.1";
  static final String version = "2.0.1";

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: name,
      theme: ThemeData.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const PositionScreen(),
    );
  }
}

class PositionScreen extends StatelessWidget {
  const PositionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<PositionProvider>(context);

    final now = DateTime.now();
    bool redColor = false;
    if (provider.position != null && provider.position!.timestamp != null) {
      redColor = now.difference(provider.position!.timestamp).inSeconds > 15;
    }

    return Scaffold(
      appBar: AppBar(title: Text(TargetTeamApp.name)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              GestureDetector(
                onTap: () => provider.showChangeHeightDialog(context),
                child: Card(
                  color: Colors.grey[900],
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        const Icon(Icons.height),
                        const SizedBox(width: 10),
                        Text(
                          l10n.heightCorrectionFactor(
                            provider.heightCorrection,
                          ),
                          style: const TextStyle(fontSize: 18),
                        ),
                        const Spacer(),
                        const Icon(Icons.edit, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                color: Colors.grey[900],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildRadio(
                        context,
                        provider,
                        LocationMode.latLong,
                        l10n.latLon,
                      ),
                      _buildRadio(
                        context,
                        provider,
                        LocationMode.wgs84,
                        l10n.wgs84,
                      ),
                      _buildRadio(
                        context,
                        provider,
                        LocationMode.etrs89,
                        l10n.etrs89,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      title: l10n.currentTime,
                      value: provider.getFormattedTime(now),
                    ),
                  ),
                  Expanded(
                    child: _InfoCard(
                      title: l10n.lastUpdate,
                      redData: redColor,
                      value: provider.position != null
                          ? provider.getFormattedTime(
                        provider.position!.timestamp,
                      )
                          : '',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _InfoCard(
                title: l10n.position,
                fullWidth: true,
                textAlign: TextAlign.end,
                redData: redColor,
                value: provider.getFormattedPosition(),
                valueStyle: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: redColor ? Colors.red : Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      title: l10n.altitudeM,
                      redData: redColor,
                      value: provider.position != null
                          ? provider.getFormattedAltitude().split('/')[0]
                          : '',
                    ),
                  ),
                  Expanded(
                    child: _InfoCard(
                      title: l10n.altitudeFt,
                      redData: redColor,
                      value: provider.position != null
                          ? provider.getFormattedAltitude().split('/')[1]
                          : '',
                    ),
                  ),
                  Expanded(
                    child: _InfoCard(
                      title: l10n.accuracy,
                      redData: redColor,
                      value: provider.getFormattedAccuracy(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.share),
                  label: Text(l10n.share),
                  onPressed: () => _showShareDialog(context, provider),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadio(
      BuildContext context,
      PositionProvider provider,
      LocationMode mode,
      String label,
      ) {
    return InkWell(
      onTap: () => provider.setLocationMode(mode),
      customBorder: const StadiumBorder(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<LocationMode>(
            value: mode,
            groupValue: provider.locationMode,
            onChanged: (val) {
              if (val != null) provider.setLocationMode(val);
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 15, 0),
            child: Text(label, style: const TextStyle(fontSize: 20)),
          ),
        ],
      ),
    );
  }

  void _showShareDialog(BuildContext context, PositionProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.shareCommentTitle),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: l10n.commentOptional),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              provider.sharePosition(context, comment: controller.text);
              Navigator.pop(context);
            },
            child: Text(l10n.shareAction),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final TextStyle? valueStyle;
  final bool? fullWidth;
  final bool redData;
  final TextAlign textAlign;

  const _InfoCard({
    required this.title,
    required this.value,
    this.valueStyle,
    this.fullWidth,
    this.textAlign = TextAlign.left,
    this.redData = false,
  });

  @override
  Widget build(BuildContext context) {
    var card = Card(
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: fullWidth == true
              ? CrossAxisAlignment.stretch
              : CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: textAlign,
              style: valueStyle ??
                  TextStyle(
                    fontSize: 20,
                    color: redData ? Colors.red : Colors.white,
                  ),
            ),
          ],
        ),
      ),
    );

    if (fullWidth == true) {
      return SizedBox(width: double.infinity, child: card);
    } else {
      return card;
    }
  }
}