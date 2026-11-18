import 'package:flutter/material.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'chat_screen.dart';

/// Shopping lists from the coach, with local offers when a place is set.
class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final TextEditingController _place = TextEditingController();
  final TextEditingController _stores = TextEditingController();
  bool _editShop = false;

  @override
  void dispose() {
    _place.dispose();
    _stores.dispose();
    super.dispose();
  }

  void _openChat(String prompt) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (BuildContext _) => ChatScreen(initialPrompt: prompt)));
  }

  Widget _shopCard(AppState state) {
    final AppColors c = AppColors.of(context);
    final ShopSettings shop = state.shop;
    if (!_editShop) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SectionLabel('Einkaufen in'),
            const SizedBox(height: 8),
            Text(
              shop.place.trim().isEmpty ? 'Noch kein Ort eingetragen' : shop.place.trim(),
              style: bodyStyle(context, size: 16, weight: FontWeight.w700),
            ),
            if (shop.stores.isNotEmpty)
              Text(shop.stores.join(', '), style: bodyStyle(context, size: 14, color: c.text2)),
            const SizedBox(height: 4),
            Text(
              'Mit Ort sucht der Coach aktuelle Angebote in deiner Nähe.',
              style: bodyStyle(context, size: 13, color: c.text2),
            ),
            const SizedBox(height: 10),
            SecondaryButton(
              label: shop.place.trim().isEmpty ? 'Ort eintragen' : 'Ändern',
              height: 46,
              fontSize: 17,
              onPressed: () {
                _place.text = shop.place;
                _stores.text = shop.stores.join(', ');
                setState(() => _editShop = true);
              },
            ),
          ],
        ),
      );
    }
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
            controller: _place,
            style: bodyStyle(context, size: 16),
            cursorColor: c.accentText,
            decoration: fieldDecoration(context, 'PLZ oder Ort', hint: 'z. B. 5020 Salzburg'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _stores,
            style: bodyStyle(context, size: 16),
            cursorColor: c.accentText,
            decoration: fieldDecoration(context, 'Lieblingsmärkte (optional)', hint: 'z. B. Hofer, Spar, Lidl'),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Speichern',
            height: 48,
            fontSize: 18,
            onPressed: () {
              final List<String> stores = _stores.text
                  .split(',')
                  .map((String e) => e.trim())
                  .where((String e) => e.isNotEmpty)
                  .toList();
              state.saveShop(ShopSettings(place: _place.text.trim(), stores: stores));
              FocusScope.of(context).unfocus();
              setState(() => _editShop = false);
            },
          ),
        ],
      ),
    );
  }

  Widget _list(AppState state, ShoppingList list) {
    final AppColors c = AppColors.of(context);
    final List<Widget> rows = <Widget>[];
    for (final String cat in kShoppingCategories) {
      final List<ShoppingItem> items = list.items.where((ShoppingItem i) => i.category == cat).toList();
      if (items.isEmpty) {
        continue;
      }
      rows.add(Padding(padding: const EdgeInsets.only(top: 14, bottom: 6), child: SectionLabel(cat)));
      for (final ShoppingItem i in items) {
        rows.add(InkWell(
          onTap: () => state.toggleShoppingItem(i),
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
            child: Row(
              children: <Widget>[
                AnimatedContainer(
                  duration: kFast,
                  curve: kEase,
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: i.done ? c.accent : Colors.transparent,
                    border: Border.all(color: i.done ? c.accent : c.border, width: 2),
                    borderRadius: BorderRadius.circular(kRadius),
                  ),
                  child: i.done ? Icon(Icons.check, size: 16, color: c.onAccent) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        i.name,
                        style: bodyStyle(context, size: 15, weight: FontWeight.w600, color: i.done ? c.text3 : c.text)
                            .copyWith(decoration: i.done ? TextDecoration.lineThrough : null),
                      ),
                      if (i.offer.isNotEmpty)
                        Text(i.offer, style: bodyStyle(context, size: 13, weight: FontWeight.w600, color: c.accentText)),
                    ],
                  ),
                ),
                if (i.amount.isNotEmpty) Text(i.amount, style: bodyStyle(context, size: 14, color: c.text2)),
              ],
            ),
          ),
        ));
      }
    }
    final int open = list.items.where((ShoppingItem i) => !i.done).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(child: Text(list.title.toUpperCase(), style: heading(context, 30))),
            Text('$open offen', style: bodyStyle(context, size: 14, color: c.text2)),
          ],
        ),
        if (list.note.trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: 6),
          Text(list.note, style: bodyStyle(context, size: 14, color: c.text2)),
        ],
        ...rows,
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => state.deleteShoppingList(list),
            child: Text('Liste löschen', style: bodyStyle(context, size: 13, color: c.text2)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final AppColors c = AppColors.of(context);
    final ShoppingList? current = state.shopping.isEmpty ? null : state.shopping.first;
    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        const PageHeader(kicker: 'Passend zu deinem Training', title: 'Essen'),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AnimatedSize(duration: kFast, curve: kEase, alignment: Alignment.topCenter, child: _shopCard(state)),
              const SizedBox(height: 14),
              PrimaryButton(
                label: 'Einkaufsliste erstellen',
                height: 60,
                fontSize: 21,
                onPressed: () => _openChat(
                  'Erstelle mir eine Einkaufsliste für die nächsten 7 Tage, passend zu meinem Ziel und Training. '
                  'Nutze aktuelle Angebote in meiner Nähe, wenn es welche gibt.',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Der Coach schreibt die Liste im Chat. Du übernimmst sie mit einem Tipp.',
                style: bodyStyle(context, size: 13, color: c.text2),
              ),
              const SizedBox(height: 22),
              if (current == null)
                Text('Noch keine Einkaufsliste.', style: bodyStyle(context, size: 15, color: c.text2))
              else
                _list(state, current),
            ],
          ),
        ),
      ],
    );
  }
}
