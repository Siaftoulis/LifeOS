import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class HighlightCurtain extends StatelessWidget {
  const HighlightCurtain({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: EverforestColors.bg1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: EverforestColors.bg2),
      ),
      title: Text(
        'Highlights & Notes',
        style: TextStyle(color: EverforestColors.fg),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: ListView.separated(
          itemCount: 3,
          separatorBuilder: (context, index) => Divider(color: EverforestColors.bg2),
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(
                '"This is a beautiful sentence highlighted from the book."',
                style: TextStyle(color: EverforestColors.fg, fontStyle: FontStyle.italic, fontSize: 14),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'My thoughts on this quote...',
                  style: TextStyle(color: EverforestColors.grey, fontSize: 12),
                ),
              ),
              trailing: IconButton(
                icon: Icon(Icons.send_to_mobile, color: EverforestColors.green),
                onPressed: () {
                  // Export to Zen Editor logic (+2 Point Stars)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exported to Zen Editor (+2 Stars)')),
                  );
                },
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          child: Text('Close', style: TextStyle(color: EverforestColors.grey)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
