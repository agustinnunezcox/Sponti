import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SpontiLogo extends StatelessWidget {
  final bool onDark;
  final double fontSize;

  const SpontiLogo({super.key, this.onDark = true, this.fontSize = 28});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Spont',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: onDark ? Colors.white : AppTheme.dark,
            letterSpacing: -0.5,
            height: 1,
          ),
        ),
        SizedBox(
          width: fontSize * 0.62,
          height: fontSize * 1.15,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Icon(
                Icons.location_on_rounded,
                color: AppTheme.accent,
                size: fontSize * 1.05,
              ),
              Positioned(
                top: fontSize * 0.14,
                child: Container(
                  width: fontSize * 0.28,
                  height: fontSize * 0.28,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
