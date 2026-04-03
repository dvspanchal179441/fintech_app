import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class VaultCardWidget extends StatelessWidget {
  final Map<String, dynamic> card;
  final bool isExpanded;

  const VaultCardWidget({
    super.key,
    required this.card,
    this.isExpanded = false,
  });

  Color _getBankColor() {
    final number = card['cardNumber'] ?? '';
    final bank = _detectBank(number);
    switch (bank) {
      case 'HDFC Bank': return AppTheme.hdfcBlue;
      case 'ICICI Bank': return AppTheme.iciciOrange;
      case 'SBI': return AppTheme.sbiBlue;
      default: return const Color(0xFF1E1E1E);
    }
  }

  String _detectBank(String number) {
    if (number.length >= 4) {
      final p = number.substring(0, 4);
      if (['4386', '4016', '5110', '4156'].contains(p)) return 'HDFC Bank';
      if (['4477', '4053', '4136', '4798'].contains(p)) return 'ICICI Bank';
      if (['4304', '5294', '4201', '4166'].contains(p)) return 'SBI';
    }
    return 'Bank';
  }

  @override
  Widget build(BuildContext context) {
    final color = _getBankColor();
    final number = card['cardNumber'] ?? '•••• •••• •••• ••••';
    final bank = _detectBank(number);
    final last4 = number.length >= 4 ? number.substring(number.length - 4) : '••••';

    return Container(
      height: 200,
      decoration: AppTheme.cardDecoration(color),
      child: Stack(
        children: [
          // Background Gradient Overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [Colors.white.withAlpha(20), Colors.transparent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          
          // Card Content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(bank.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                    Icon(Icons.contactless_rounded, color: Colors.white.withAlpha(180), size: 24),
                  ],
                ),
                
                // Chip
                Container(
                  width: 45, height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white.withAlpha(50)),
                  ),
                  child: Center(
                    child: Container(
                      width: 25, height: 18,
                      decoration: BoxDecoration(border: Border.all(color: Colors.white.withAlpha(30)), borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('•••• •••• •••• $last4', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.normal, letterSpacing: 3)),
                    const Text('VISA', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
