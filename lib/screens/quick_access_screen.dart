import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/local_storage_service.dart';
import '../widgets/vault_card_widget.dart';

class QuickAccessScreen extends StatefulWidget {
  const QuickAccessScreen({super.key});

  @override
  State<QuickAccessScreen> createState() => _QuickAccessScreenState();
}

class _QuickAccessScreenState extends State<QuickAccessScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _cards = [];
  bool _loading = true;
  int? _selectedIndex;
  
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _loadCards();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    final saved = await LocalStorageService.loadCards();
    setState(() {
      _cards = saved;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
    if (_cards.isEmpty) return _emptyState();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Text('Quick Access', style: TextStyle(color: AppTheme.white, fontSize: 24, fontWeight: FontWeight.w800)),
                  Spacer(),
                  Icon(Icons.more_vert_rounded, color: AppTheme.whiteSecondary),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  // Overlapping Stacked Cards
                  for (int i = 0; i < _cards.length; i++)
                    _buildAnimatedCard(i),
                  
                  // Bottom Section (Transit Card / Quick Setup)
                  Positioned(
                    bottom: 40,
                    left: 20,
                    right: 20,
                    child: _buildFooterSection(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedCard(int index) {
    final bool isTop = _selectedIndex == index;
    final bool isAnySelected = _selectedIndex != null;
    
    // Calculate vertical offset
    double topOffset = 80.0 + (index * 45.0);
    if (isAnySelected) {
      if (isTop) {
        topOffset = 60.0; // Bring to top
      } else {
        topOffset = 600.0; // Push others down
      }
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: Curves.fastOutSlowIn,
      top: topOffset,
      left: 20,
      right: 20,
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (_selectedIndex == index) {
              _selectedIndex = null;
            } else {
              _selectedIndex = index;
            }
          });
        },
        child: Hero(
          tag: 'card_${_cards[index]['cardNumber']}',
          child: VaultCardWidget(
            card: _cards[index],
            isExpanded: isTop,
          ),
        ),
      ),
    );
  }

  Widget _buildFooterSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.primaryBlue.withAlpha(20), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.directions_bus_rounded, color: AppTheme.primaryBlue),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Transit Card', style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold)),
                Text('Set up for easy travel', style: TextStyle(color: AppTheme.whiteSecondary, fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _setupTransitCard(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
            ),
            child: const Text('SETUP', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  void _setupTransitCard() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        title: const Text('Issuing Transit Card', style: TextStyle(color: AppTheme.white)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryBlue),
            SizedBox(height: 20),
            Text('Contacting regional transit server...', style: TextStyle(color: AppTheme.whiteSecondary)),
          ],
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Virtual Transit Card Issued Successfully!')));
      }
    });
  }

  Widget _emptyState() {
     return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.credit_card_off_rounded, color: AppTheme.whiteTertiary, size: 72),
          const SizedBox(height: 16),
          const Text('No cards found', style: TextStyle(color: AppTheme.white, fontSize: 18, fontWeight: FontWeight.w600)),
          const Text('Add cards in Smart Cards page first', style: TextStyle(color: AppTheme.whiteTertiary, fontSize: 12)),
        ],
      ),
    );
  }
}
