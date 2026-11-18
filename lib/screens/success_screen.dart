import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class SuccessScreen extends StatelessWidget {
  final Plan plan;

  const SuccessScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: Center(
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: c.accent, width: 4),
                    ),
                    child: Icon(Icons.check, size: 88, color: c.accentText),
                  ),
                ),
              ),
              Center(child: SectionLabel('Training abgeschlossen', color: c.accentText)),
              const SizedBox(height: 10),
              Center(child: Text('GESCHAFFT!', style: heading(context, 72))),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  '${plan.name} · ${plan.items.length} Übungen',
                  style: bodyStyle(context, size: 15, color: c.text2),
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Fertig',
                height: 64,
                fontSize: 22,
                onPressed: () => Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
