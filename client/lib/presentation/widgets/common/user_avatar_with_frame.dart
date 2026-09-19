import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class AvatarFrameStyle {
  final String id;
  final String label;
  final List<Color> colors;
  final List<BoxShadow> shadows;
  final double borderWidth;

  const AvatarFrameStyle({
    required this.id,
    required this.label,
    required this.colors,
    required this.shadows,
    this.borderWidth = 2.5,
  });
}

class UserAvatarFrames {
  static const List<AvatarFrameStyle> all = [
    AvatarFrameStyle(
      id: 'none',
      label: 'Standard',
      colors: [EverforestColors.bg2, EverforestColors.bg2],
      shadows: [],
      borderWidth: 1.5,
    ),
    AvatarFrameStyle(
      id: 'neon-green',
      label: 'Neon Green',
      colors: [EverforestColors.green, EverforestColors.aqua],
      shadows: [
        BoxShadow(color: EverforestColors.green, blurRadius: 10, spreadRadius: 1),
      ],
      borderWidth: 3.0,
    ),
    AvatarFrameStyle(
      id: 'cyber-aqua',
      label: 'Cyber Aqua',
      colors: [EverforestColors.aqua, EverforestColors.blue],
      shadows: [
        BoxShadow(color: EverforestColors.aqua, blurRadius: 10, spreadRadius: 1),
      ],
      borderWidth: 3.0,
    ),
    AvatarFrameStyle(
      id: 'golden-royal',
      label: 'Royal Gold',
      colors: [EverforestColors.yellow, EverforestColors.orange],
      shadows: [
        BoxShadow(color: EverforestColors.yellow, blurRadius: 10, spreadRadius: 1),
      ],
      borderWidth: 3.0,
    ),
    AvatarFrameStyle(
      id: 'crimson-fire',
      label: 'Crimson Flame',
      colors: [EverforestColors.red, EverforestColors.orange],
      shadows: [
        BoxShadow(color: EverforestColors.red, blurRadius: 10, spreadRadius: 1),
      ],
      borderWidth: 3.0,
    ),
    AvatarFrameStyle(
      id: 'purple-galaxy',
      label: 'Purple Galaxy',
      colors: [EverforestColors.purple, EverforestColors.blue],
      shadows: [
        BoxShadow(color: EverforestColors.purple, blurRadius: 10, spreadRadius: 1),
      ],
      borderWidth: 3.0,
    ),
    AvatarFrameStyle(
      id: 'everforest-wood',
      label: 'Deep Forest',
      colors: [EverforestColors.green, EverforestColors.bg2],
      shadows: [
        BoxShadow(color: EverforestColors.green, blurRadius: 6, spreadRadius: 0.5),
      ],
      borderWidth: 2.5,
    ),
  ];

  static AvatarFrameStyle getStyle(String id) {
    return all.firstWhere((s) => s.id == id, orElse: () => all.first);
  }
}

class NameStyleOption {
  final String id;
  final String label;
  final TextStyle Function(TextStyle base) styleBuilder;

  const NameStyleOption({
    required this.id,
    required this.label,
    required this.styleBuilder,
  });
}

class UserNameStyles {
  static final List<NameStyleOption> all = [
    NameStyleOption(
      id: 'default',
      label: 'Default',
      styleBuilder: (base) => base.copyWith(color: EverforestColors.fg),
    ),
    NameStyleOption(
      id: 'glow-green',
      label: 'Glow Green',
      styleBuilder: (base) => base.copyWith(
        color: EverforestColors.green,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(color: EverforestColors.green.withValues(alpha: 0.8), blurRadius: 8),
        ],
      ),
    ),
    NameStyleOption(
      id: 'cyber-neon',
      label: 'Cyber Aqua',
      styleBuilder: (base) => base.copyWith(
        color: EverforestColors.aqua,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        shadows: [
          Shadow(color: EverforestColors.aqua.withValues(alpha: 0.8), blurRadius: 8),
        ],
      ),
    ),
    NameStyleOption(
      id: 'royal-gold',
      label: 'Royal Gold',
      styleBuilder: (base) => base.copyWith(
        color: EverforestColors.yellow,
        fontWeight: FontWeight.w800,
        shadows: [
          Shadow(color: EverforestColors.yellow.withValues(alpha: 0.6), blurRadius: 6),
        ],
      ),
    ),
    NameStyleOption(
      id: 'crimson-bold',
      label: 'Crimson Fire',
      styleBuilder: (base) => base.copyWith(
        color: EverforestColors.red,
        fontWeight: FontWeight.w800,
        shadows: [
          Shadow(color: EverforestColors.red.withValues(alpha: 0.7), blurRadius: 8),
        ],
      ),
    ),
    NameStyleOption(
      id: 'purple-galaxy',
      label: 'Purple Galaxy',
      styleBuilder: (base) => base.copyWith(
        color: EverforestColors.purple,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(color: EverforestColors.purple.withValues(alpha: 0.8), blurRadius: 8),
        ],
      ),
    ),
  ];

  static TextStyle apply(String styleId, TextStyle base) {
    final opt = all.firstWhere((o) => o.id == styleId, orElse: () => all.first);
    return opt.styleBuilder(base);
  }
}

class UserAvatarWithFrame extends StatelessWidget {
  final String avatarAsset;
  final String username;
  final String frameId;
  final double radius;
  final bool isOnline;

  const UserAvatarWithFrame({
    super.key,
    required this.avatarAsset,
    required this.username,
    this.frameId = 'none',
    this.radius = 24,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    final frame = UserAvatarFrames.getStyle(frameId);
    final size = radius * 2;

    Widget avatarContent;
    if (avatarAsset.startsWith('http://') || avatarAsset.startsWith('https://')) {
      avatarContent = Image.network(
        avatarAsset,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, __, ___) => _fallbackAvatar(),
      );
    } else if (avatarAsset.startsWith('preset:')) {
      final emoji = avatarAsset.replaceFirst('preset:', '');
      avatarContent = Center(
        child: Text(
          emoji,
          style: TextStyle(fontSize: radius * 1.1),
        ),
      );
    } else if (avatarAsset.isNotEmpty && !avatarAsset.contains('/')) {
      avatarContent = Center(
        child: Text(
          avatarAsset,
          style: TextStyle(fontSize: radius * 1.1),
        ),
      );
    } else {
      avatarContent = _fallbackAvatar();
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size + (frame.borderWidth * 2) + 4,
          height: size + (frame.borderWidth * 2) + 4,
          padding: EdgeInsets.all(frame.borderWidth),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: frame.colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: frame.shadows,
          ),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: EverforestColors.bg0,
            ),
            clipBehavior: Clip.antiAlias,
            child: avatarContent,
          ),
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: EverforestColors.green,
                shape: BoxShape.circle,
                border: Border.all(color: EverforestColors.bg0, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: EverforestColors.green.withValues(alpha: 0.8),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _fallbackAvatar() {
    final letter = username.isNotEmpty ? username[0].toUpperCase() : '?';
    return Center(
      child: Text(
        letter,
        style: TextStyle(
          color: EverforestColors.green,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.9,
        ),
      ),
    );
  }
}
