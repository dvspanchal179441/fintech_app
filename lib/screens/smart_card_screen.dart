import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../theme/app_theme.dart';
import 'smart_card_detail_screen.dart';

class SmartCardScreen extends StatefulWidget {
  const SmartCardScreen({super.key});

  @override
  State<SmartCardScreen> createState() => _SmartCardScreenState();
}

class _SmartCardScreenState extends State<SmartCardScreen> {
  List<Map<String, String>> _cards = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final saved = await LocalStorageService.loadCards();
    setState(() {
      _cards = saved;
      _loading = false;
    });
  }

  Future<void> _persist() async {
    await LocalStorageService.saveCards(_cards);
  }

  String _detectBank(String number) {
    if (number.length >= 4) {
      final p = number.substring(0, 4);
      if (['4386', '4016', '5110', '4156'].contains(p)) return 'HDFC Bank';
      if (['4477', '4053', '4136', '4798'].contains(p)) return 'ICICI Bank';
      if (['4304', '5294', '4201', '4166'].contains(p)) return 'SBI';
      if (['4376', '4375', '4181'].contains(p)) return 'Axis Bank';
    }
    return 'Bank';
  }

  Color _cardColor(String number) {
    switch (_detectBank(number)) {
      case 'HDFC Bank': return const Color(0xFF1A237E);
      case 'ICICI Bank': return const Color(0xFF4A0E0E);
      case 'SBI': return const Color(0xFF004D40);
      case 'Axis Bank': return const Color(0xFF37004D);
      default: return const Color(0xFF1A1A2E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Cards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Add Card',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final newCard = await Navigator.push<Map<String, String>>(
                context,
                MaterialPageRoute(builder: (_) => const AddSmartCardScreen()),
              );
              if (newCard != null) {
                setState(() => _cards.add(newCard));
                await _persist();
                if (mounted) {
                  messenger.showSnackBar(const SnackBar(content: Text('✅ Card added successfully!')));
                }
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : _cards.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                  itemCount: _cards.length,
                  itemBuilder: (context, index) {
                    final card = _cards[index];
                    return _buildCardTile(card, index);
                  },
                ),
    );
  }

  Widget _buildCardTile(Map<String, String> card, int index) {
    final number = card['cardNumber'] ?? '';
    final last4 = number.length >= 4 ? number.substring(number.length - 4) : '????';
    final holder = card['cardHolderName'] ?? 'Unknown';
    final expiry = card['expiryDate'] ?? '--/--';
    final bank = _detectBank(number);
    final color = _cardColor(number);
    final network = number.startsWith('4') ? 'VISA' : number.startsWith('5') ? 'MC' : 'RUPAY';

    return Dismissible(
      key: Key(number + index.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: AppTheme.danger,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_rounded, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text('Delete', style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
      onDismissed: (_) async {
        setState(() => _cards.removeAt(index));
        await _persist();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Card removed')));
        }
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SmartCardDetailScreen(
                card: card,
                onDelete: () async {
                  setState(() => _cards.removeAt(index));
                  await _persist();
                },
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 18),
          height: 185,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, Color.lerp(color, Colors.black, 0.35) ?? color],
            ),
            boxShadow: [
              BoxShadow(color: color.withAlpha(160), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.credit_card_rounded, color: Colors.white.withAlpha(180), size: 28),
                    Row(
                      children: [
                        const Icon(Icons.touch_app_rounded, color: Colors.white38, size: 14),
                        const SizedBox(width: 4),
                        Text('Tap to view', style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 11)),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(network, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  '•••• •••• •••• $last4',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 3),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CARD HOLDER', style: TextStyle(color: Colors.white.withAlpha(130), fontSize: 9, letterSpacing: 1.5)),
                        const SizedBox(height: 2),
                        Text(holder.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('VALID THRU', style: TextStyle(color: Colors.white.withAlpha(130), fontSize: 9, letterSpacing: 1.5)),
                        const SizedBox(height: 2),
                        Text(expiry, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('BANK', style: TextStyle(color: Colors.white.withAlpha(130), fontSize: 9, letterSpacing: 1.5)),
                        const SizedBox(height: 2),
                        Text(bank, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.credit_card_off_rounded, color: AppTheme.whiteTertiary, size: 72),
          const SizedBox(height: 16),
          const Text('No cards added yet', style: TextStyle(color: AppTheme.white, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Tap + to add your first card', style: TextStyle(color: AppTheme.whiteTertiary, fontSize: 14)),
        ],
      ),
    );
  }
}

// ── Add Smart Card Screen ────────────────────────────────────────────────────

class AddSmartCardScreen extends StatefulWidget {
  const AddSmartCardScreen({super.key});

  @override
  State<AddSmartCardScreen> createState() => _AddSmartCardScreenState();
}

class _AddSmartCardScreenState extends State<AddSmartCardScreen> {
  final _formKey = GlobalKey<FormState>();
  String cardNumber = '';
  String expiryDate = '';
  String cardHolderName = '';
  String cvv = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Card')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Preview mini-card
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                ),
                border: Border.all(color: AppTheme.primaryBlue.withAlpha(80)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.credit_card_rounded, color: AppTheme.primaryBlue),
                  Text(
                    cardNumber.isEmpty ? '•••• •••• •••• ••••' : cardNumber,
                    style: const TextStyle(color: AppTheme.white, letterSpacing: 3, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            _field(
              label: 'Card Number',
              icon: Icons.credit_card_rounded,
              hint: '16-digit card number',
              keyboardType: TextInputType.number,
              maxLength: 16,
              onChanged: (v) => setState(() => cardNumber = v),
              validator: (v) => (v == null || v.length < 12) ? 'Enter valid card number' : null,
            ),
            const SizedBox(height: 16),
            _field(
              label: 'Card Holder Name',
              icon: Icons.person_rounded,
              hint: 'Full name on card',
              onChanged: (v) => cardHolderName = v,
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _field(
                    label: 'Expiry (MM/YY)',
                    icon: Icons.calendar_today_rounded,
                    hint: '12/25',
                    maxLength: 5,
                    onChanged: (v) => expiryDate = v,
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _field(
                    label: 'CVV',
                    icon: Icons.lock_rounded,
                    hint: '•••',
                    maxLength: 4,
                    obscure: true,
                    keyboardType: TextInputType.number,
                    onChanged: (v) => cvv = v,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_card_rounded),
              label: const Text('Save Card'),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  Navigator.pop(context, {
                    'cardNumber': cardNumber,
                    'cardHolderName': cardHolderName,
                    'expiryDate': expiryDate.isEmpty ? '12/99' : expiryDate,
                    'cvv': cvv,
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required IconData icon,
    required String hint,
    required Function(String) onChanged,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLength,
    bool obscure = false,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.primaryBlue, size: 20),
        counterText: '',
      ),
      keyboardType: keyboardType,
      maxLength: maxLength,
      obscureText: obscure,
      onChanged: onChanged,
      validator: validator,
      style: const TextStyle(color: AppTheme.white),
    );
  }
}
