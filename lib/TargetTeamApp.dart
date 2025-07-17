import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'position_provider.dart';

class TargetTeamApp extends StatelessWidget {
  const TargetTeamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Target Team',
      theme: ThemeData.dark(),
      home: const PositionScreen(),
    );
  }
}

class PositionScreen extends StatelessWidget {
  const PositionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PositionProvider>(context);

    final now = DateTime.now();
    bool redColor = false;
    if (provider.position != null && provider.position!.timestamp != null) {
      redColor = now.difference(provider.position!.timestamp).inSeconds > 15;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Target Team')),
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
                          'Höhenausgleich: ${provider.heightCorrection.toStringAsFixed(2)}',
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildRadio(
                        context,
                        provider,
                        LocationMode.latLong,
                        'Lat/Lon',
                      ),
                      _buildRadio(
                        context,
                        provider,
                        LocationMode.wgs84,
                        'WGS84',
                      ),
                      _buildRadio(
                        context,
                        provider,
                        LocationMode.etrs89,
                        'ETRS89',
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
                      title: 'Aktuelle Zeit',
                      value: provider.getFormattedTime(now),
                    ),
                  ),
                  Expanded(
                    child: _InfoCard(
                      title: 'Letztes Update',
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
                title: 'Position',
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
                      title: 'Höhe (m)',
                      redData: redColor,
                      value: provider.position != null
                          ? provider.getFormattedAltitude().split('/')[0]
                          : '',
                    ),
                  ),
                  Expanded(
                    child: _InfoCard(
                      title: 'Höhe (ft)',
                      redData: redColor,
                      value: provider.position != null
                          ? provider.getFormattedAltitude().split('/')[1]
                          : '',
                    ),
                  ),
                  Expanded(
                    child: _InfoCard(
                      title: 'Genauigkeit',
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
                  label: const Text('Teilen'),
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
    return Row(
      children: [
        Radio<LocationMode>(
          value: mode,
          groupValue: provider.locationMode,
          onChanged: (val) {
            if (val != null) provider.setLocationMode(val);
          },
        ),
        Text(label),
      ],
    );
  }

  void _showShareDialog(BuildContext context, PositionProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kommentar zum Teilen'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Kommentar (optional)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              provider.sharePosition(context, comment: controller.text);
              Navigator.pop(context);
            },
            child: const Text('Teilen'),
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
              style:
                  valueStyle ??
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
