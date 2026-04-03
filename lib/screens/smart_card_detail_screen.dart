import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class SmartCardDetailScreen extends StatefulWidget {
  final Map<String, String> card;
  final VoidCallback onDelete;

  const SmartCardDetailScreen({
    super.key,
    required this.card,
    required this.onDelete,
  });

  @override
  State<SmartCardDetailScreen> createState() => _SmartCardDetailScreenState();
}

class _SmartCardDetailScreenState extends State<SmartCardDetailScreen> {
  bool _cardNumberRevealed = false;
  bool _cvvRevealed = false;

  String get _cardNumber => widget.card['cardNumber'] ?? '';
  String get _holder => widget.card['cardHolderName'] ?? '';
  String get _expiry => widget.card['expiryDate'] ?? '';
  String get _cvv => widget.card['cvv'] ?? '•••';
  String get _network => widget.card['network'] ?? _detectNetwork();
  String get _bankName => widget.card['bankName'] ?? _detectBank();

  String _detectNetwork() {
    if (_cardNumber.startsWith('4')) return 'Visa';
    if (_cardNumber.startsWith('5')) return 'Mastercard';
    if (_cardNumber.startsWith('6')) return 'RuPay';
    return 'Unknown';
  }

  String _detectBank() {
    if (_cardNumber.length >= 4) {
      final prefix = _cardNumber.substring(0, 4);
      if (['4386', '4016', '5110', '4156'].contains(prefix)) return 'HDFC Bank';
      if (['4477', '4053', '4136', '4798'].contains(prefix)) return 'ICICI Bank';
      if (['4304', '5294', '4201', '4166'].contains(prefix)) return 'SBI';
      if (['4376', '4375', '4181'].contains(prefix)) return 'Axis Bank';
    }
    return 'Bank';
  }

  Color get _cardGradientStart {
    switch (_detectBank()) {
      case 'HDFC Bank': return const Color(0xFF1A237E);
      case 'ICICI Bank': return const Color(0xFF4A0E0E);
      case 'SBI': return const Color(0xFF004D40);
      case 'Axis Bank': return const Color(0xFF37004D);
      default: return const Color(0xFF1A1A2E);
    }
  }

  Color get _cardGradientEnd {
    switch (_detectBank()) {
      case 'HDFC Bank': return const Color(0xFF283593);
      case 'ICICI Bank': return const Color(0xFF7B1111);
      case 'SBI': return const Color(0xFF00695C);
      case 'Axis Bank': return const Color(0xFF6A1B9A);
      default: return const Color(0xFF16213E);
    }
  }

  String get _maskedNumber {
    if (_cardNumber.length >= 16) {
      return '${_cardNumber.substring(0, 4)} •••• •••• ${_cardNumber.substring(12)}';
    }
    return '**** **** **** ****';
  }

  String get _formattedNumber {
    final n = _cardNumber;
    if (n.length >= 16) {
      return '${n.substring(0, 4)} ${n.substring(4, 8)} ${n.substring(8, 12)} ${n.substring(12)}';
    }
    return n;
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard')),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        title: const Text('Delete Card', style: TextStyle(color: AppTheme.white)),
        content: Text(
          'Remove $_bankName card ending in ${_cardNumber.length >= 4 ? _cardNumber.substring(_cardNumber.length - 4) : "****"}?',
          style: const TextStyle(color: AppTheme.whiteSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.whiteTertiary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);     // close dialog
              widget.onDelete();
              Navigator.pop(context); // go back to list
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(_bankName),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Card Visual ────────────────────────────────────
            Container(
              height: 210,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_cardGradientStart, _cardGradientEnd],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _cardGradientStart.withAlpha(180),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.credit_card_rounded, color: Colors.white.withAlpha(180), size: 32),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _network.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 2),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _cardNumberRevealed ? _formattedNumber : _maskedNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 3,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CARD HOLDER', style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 9, letterSpacing: 1.5)),
                            const SizedBox(height: 2),
                            Text(_holder.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('VALID THRU', style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 9, letterSpacing: 1.5)),
                            const SizedBox(height: 2),
                            Text(_expiry, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── Card Details ───────────────────────────────────
            const Text('CARD DETAILS', style: TextStyle(color: AppTheme.whiteTertiary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.4)),
            const SizedBox(height: 14),

            _detailTile(
              icon: Icons.credit_card_rounded,
              label: 'Card Number',
              value: _cardNumberRevealed ? _formattedNumber : _maskedNumber,
              onReveal: () => setState(() => _cardNumberRevealed = !_cardNumberRevealed),
              isRevealed: _cardNumberRevealed,
              onCopy: () => _copyToClipboard(_cardNumber, 'Card number'),
            ),
            _detailTile(
              icon: Icons.person_rounded,
              label: 'Card Holder',
              value: _holder.toUpperCase(),
              onCopy: () => _copyToClipboard(_holder, 'Card holder name'),
            ),
            _detailTile(
              icon: Icons.calendar_today_rounded,
              label: 'Expiry Date',
              value: _expiry,
              onCopy: () => _copyToClipboard(_expiry, 'Expiry date'),
            ),
            _detailTile(
              icon: Icons.lock_rounded,
              label: 'CVV',
              value: _cvvRevealed ? _cvv : '•••',
              onReveal: () => setState(() => _cvvRevealed = !_cvvRevealed),
              isRevealed: _cvvRevealed,
              onCopy: () => _copyToClipboard(_cvv, 'CVV'),
            ),
            _detailTile(
              icon: Icons.account_balance_rounded,
              label: 'Bank',
              value: _bankName,
            ),
            _detailTile(
              icon: Icons.contactless_rounded,
              label: 'Network',
              value: _network,
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailTile({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onReveal,
    bool isRevealed = true,
    VoidCallback? onCopy,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.gold.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.gold, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppTheme.whiteTertiary, fontSize: 11, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.w600, fontSize: 15, letterSpacing: 1)),
              ],
            ),
          ),
          if (onReveal != null)
            IconButton(
              onPressed: onReveal,
              icon: Icon(isRevealed ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: AppTheme.whiteTertiary, size: 20),
            ),
          if (onCopy != null)
            IconButton(
              onPressed: onCopy,
              icon: const Icon(Icons.copy_rounded, color: AppTheme.whiteTertiary, size: 18),
            ),
        ],
      ),
    );
  }
}
