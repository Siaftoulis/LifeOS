import 'package:flutter/material.dart';

/// Graphic Integrity Engine for smooth keyboard transitions.
/// Bypasses Flutter's layout engine (Scaffold resize) to use 100% GPU-accelerated translations.
class SmoothKeyboardIntegrity extends StatefulWidget {
  final Widget child;
  final bool isActive;

  const SmoothKeyboardIntegrity({
    super.key,
    required this.child,
    required this.isActive,
  });

  @override
  State<SmoothKeyboardIntegrity> createState() => _SmoothKeyboardIntegrityState();
}

class _SmoothKeyboardIntegrityState extends State<SmoothKeyboardIntegrity> {
  final GlobalKey _wrapperKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final keyboardHeight = mq.viewInsets.bottom;
    
    double translationY = 0.0;
    
    // Εάν είναι η ενεργή οθόνη και το πληκτρολόγιο είναι ανοιχτό,
    // υπολογίζουμε το offset για να μην κρυφτεί το πεδίο εισαγωγής.
    if (widget.isActive && keyboardHeight > 0) {
      final focusNode = FocusManager.instance.primaryFocus;
      if (focusNode != null && focusNode.context != null) {
        try {
          final wrapperBox = _wrapperKey.currentContext?.findRenderObject() as RenderBox?;
          final fieldBox = focusNode.context!.findRenderObject() as RenderBox?;
          
          if (wrapperBox != null && fieldBox != null) {
            // Βρίσκουμε τη θέση του TextField ΣΧΕΤΙΚΑ με το wrapper.
            // Έτσι, το localToGlobal αγνοεί το δικό μας Transform!
            final offset = fieldBox.localToGlobal(Offset.zero, ancestor: wrapperBox);
            
            // Το κάτω μέρος του πεδίου
            final fieldBottom = offset.dy + fieldBox.size.height;
            
            // Το ορατό ύψος της οθόνης (χωρίς το πληκτρολόγιο)
            final visibleHeight = mq.size.height - keyboardHeight;
            
            // Αφήνουμε 24px αέρα (padding)
            final desiredBottom = visibleHeight - 24.0;
            
            // Αν το πεδίο πέφτει κάτω από το ορατό όριο, το σπρώχνουμε προς τα πάνω!
            if (fieldBottom > desiredBottom) {
              translationY = -(fieldBottom - desiredBottom);
            }
          }
        } catch (e) {
          // Fallback if render boxes are detached
        }
      }
    }

    // Το AnimatedContainer εξομαλύνει οποιαδήποτε "σπασίματα" (chuncky updates) από το λειτουργικό
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      transform: Matrix4.translationValues(0, translationY, 0),
      child: KeyedSubtree(
        key: _wrapperKey,
        child: MediaQuery(
          // Μηδενίζουμε το viewInsets, ώστε το εσωτερικό Scaffold (πχ. KnowledgeBase)
          // να νομίζει ότι το πληκτρολόγιο είναι ΠΑΝΤΑ κλειστό και να μην κάνει padding/rebuild!
          data: mq.copyWith(
            viewInsets: EdgeInsets.zero,
            viewPadding: EdgeInsets.zero,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
