import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/connectivity/connectivity_checker.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    super.key,
    required this.child,
    this.connectivityChecker,
  });

  final Widget child;
  final ConnectivityChecker? connectivityChecker;

  @override
  Widget build(BuildContext context) {
    final checker = connectivityChecker ?? ConnectivityChecker();

    return StreamBuilder<bool>(
      stream: checker.isOnlineStream,
      initialData: true,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;
        return Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isOnline
                  ? const SizedBox.shrink()
                  : Material(
                      key: const ValueKey('offline-banner'),
                      color: const Color(0xFF5A1F24),
                      child: SafeArea(
                        bottom: false,
                        child: SizedBox(
                          width: double.infinity,
                          height: 34,
                          child: Center(
                            child: Text(
                              'Offline mode - cached data is being shown',
                              style: GoogleFonts.dmSans(
                                color: const Color(0xFFFFD6D6),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}
