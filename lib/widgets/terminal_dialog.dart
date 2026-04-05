import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_provider.dart';

class TerminalDialog extends StatelessWidget {
  final String headerTag;
  final String title;
  final String body;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final bool isDestructive;

  final Widget? customBody;

  const TerminalDialog({
    super.key,
    required this.headerTag,
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.onConfirm,
    this.isDestructive = false,
    this.customBody,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.redAccent : const Color(0xFF00E5FF);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Icon(Icons.shield_rounded, color: color.withValues(alpha: 0.5), size: 14),
                  const SizedBox(width: 8),
                  Text(
                    headerTag.toUpperCase(),
                    style: AppLocalization.digitalFont(
                      context,
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'SESSION_ID: 0x${DateTime.now().millisecondsSinceEpoch.toRadixString(16).toUpperCase()}',
                    style: GoogleFonts.sourceCodePro(
                      color: Colors.white.withValues(alpha: 0.15),
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: AppLocalization.digitalFont(
                      context,
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    body,
                    style: AppLocalization.digitalFont(context, 
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  if (customBody != null) ...[
                    const SizedBox(height: 24),
                    customBody!,
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: onConfirm,
                    child: Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          colors: [
                            color.withValues(alpha: 0.8),
                            color,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          confirmLabel.toUpperCase(),
                          style: AppLocalization.digitalFont(
                            context,
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Center(
                        child: Text(
                          cancelLabel.toUpperCase(),
                          style: AppLocalization.digitalFont(
                            context,
                            color: Colors.white.withValues(alpha: 0.4),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Bottom Progress Line
            Container(
              height: 2,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.1),
                    color,
                    color.withValues(alpha: 0.1),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
