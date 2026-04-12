import 'package:flutter/foundation.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import '../models/models.dart';

/// Offline-first SMS intelligence engine for Indian banking SMS formats.
/// All parsing is done on-device — no network calls are made.
class SMSParserService {
  static final SmsQuery _query = SmsQuery();

  // ─── Regex Patterns for Indian Banks ─────────────────────────────────────

  // HDFC / ICICI credit card statement
  static final RegExp hdfcIciciRegExp = RegExp(
    r'(?:statement|bill).*?(?:card|a\/c|ac).*?(?:ending|no\.?|x+)[\s*]*(\d{4})'
    r'.*?(?:total\s+)?(?:amt\s+)?due.*?(?:rs\.?|inr|₹)\s*([\d,]+\.?\d*)'
    r'.*?(?:due\s+date|pay\s+by)\s*[:\-]?\s*(\d{1,2}[-\/\s]\w+[-\/\s]?\d{0,4})',
    caseSensitive: false,
    dotAll: true,
  );

  // SBI credit card statement
  static final RegExp sbiRegExp = RegExp(
    r'sbi\s+(?:credit\s+)?card.*?(?:ending|no\.?|x+)[\s*]*(\d{4})'
    r'.*?(?:total\s+)?due.*?(?:rs\.?|inr|₹)\s*([\d,]+\.?\d*)'
    r'.*?(?:by|before|due\s+date)\s*[:\-]?\s*(\d{1,2}[-\/\s]\w+)',
    caseSensitive: false,
    dotAll: true,
  );

  // Axis Bank credit card
  static final RegExp axisRegExp = RegExp(
    r'axis\s+bank.*?(?:card|a\/c).*?(\d{4})'
    r'.*?(?:minimum|total)\s+(?:amount\s+)?due.*?(?:rs\.?|inr|₹)\s*([\d,]+\.?\d*)'
    r'.*?(?:due|by)\s*[:\-]?\s*(\d{1,2}[-\/\s]\w+)',
    caseSensitive: false,
    dotAll: true,
  );

  // UPI payment detection
  static final RegExp upiRegExp = RegExp(
    r'(?:debited|sent|paid|transferred).*?(?:rs\.?|inr|₹)\s*([\d,]+\.?\d*)'
    r'.*?(?:to|trf\s+to)\s+([\w\s@.]+?)(?:\s+on|\s+ref|\s+upi|\.|$)',
    caseSensitive: false,
    dotAll: true,
  );

  /// Known banking sender address keywords.
  static const List<String> _bankingSenders = [
    'HDFCBK', 'ICICIB', 'SBICRD', 'SBMSMS', 'AXISBK', 'KOTAKB',
    'INDUSB', 'YESBNK', 'PNBSMS', 'BOISMS', 'CBSSBI', 'PAYTMB',
    'ATMMSG', 'NPCI', 'BARODASMS', 'UNIONB', 'CREDTC',
  ];

  static bool _isBankingSender(String address) {
    final upper = address.toUpperCase();
    return _bankingSenders.any((s) => upper.contains(s)) ||
        upper.startsWith('VM-') ||
        upper.startsWith('VD-') ||
        upper.startsWith('AX-') ||
        upper.startsWith('BZ-');
  }

  /// Reads the actual device SMS inbox and parses banking messages.
  /// Returns a list of [Bill] objects detected from real SMS data.
  static Future<List<Bill>> scanInboxForBills() async {
    _enforceOfflinePrivacy();

    final cutoff = DateTime.now().subtract(const Duration(days: 60));

    List<SmsMessage> messages = [];
    try {
      messages = await _query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: 500,
        // Only fetch 500 messages, and filter dates locally
      );
    } catch (e) {
      debugPrint('❌ Error reading SMS: $e');
      return [];
    }

    debugPrint('📩 Total SMS read: ${messages.length}');

    final List<Bill> detectedBills = [];

    for (final msg in messages) {
      final address = msg.address ?? '';
      final body = msg.body ?? '';
      final smsDate = msg.date ?? DateTime.now();

      if (smsDate.isBefore(cutoff)) continue;
      if (body.isEmpty) continue;
      if (!_isBankingSender(address)) continue;

      // Try HDFC/ICICI
      final hdfcMatch = hdfcIciciRegExp.firstMatch(body);
      if (hdfcMatch != null) {
        final bill = _buildBill(hdfcMatch, 'HDFC/ICICI', smsDate);
        if (bill != null) {
          detectedBills.add(bill);
          debugPrint('✅ HDFC/ICICI bill detected: ₹${bill.amount}');
          continue;
        }
      }

      // Try SBI
      final sbiMatch = sbiRegExp.firstMatch(body);
      if (sbiMatch != null) {
        final bill = _buildBill(sbiMatch, 'SBI', smsDate);
        if (bill != null) {
          detectedBills.add(bill);
          debugPrint('✅ SBI bill detected: ₹${bill.amount}');
          continue;
        }
      }

      // Try Axis Bank
      final axisMatch = axisRegExp.firstMatch(body);
      if (axisMatch != null) {
        final bill = _buildBill(axisMatch, 'Axis Bank', smsDate);
        if (bill != null) {
          detectedBills.add(bill);
          debugPrint('✅ Axis bill detected: ₹${bill.amount}');
          continue;
        }
      }
    }

    debugPrint('📊 Total bills detected: ${detectedBills.length}');
    return detectedBills;
  }

  /// Builds a [Bill] from a regex match.
  static Bill? _buildBill(
      RegExpMatch match, String bankName, DateTime smsDate) {
    try {
      final cardEnding = match.group(1) ?? '????';
      final amountStr = match.group(2)?.replaceAll(',', '') ?? '0';
      final dueDateStr = match.group(3) ?? '';
      final amount = double.tryParse(amountStr) ?? 0.0;

      if (amount <= 0) return null;

      final dueDate = _parseDueDate(dueDateStr) ??
          DateTime.now().add(const Duration(days: 15));

      return Bill(
        id: 'SMS-${bankName.replaceAll('/', '')}-$cardEnding'
            '-${smsDate.millisecondsSinceEpoch}',
        amount: amount,
        isPaid: false,
        dueDate: dueDate,
        billerName: '$bankName Card (••••$cardEnding)',
        cardId: '$bankName-$cardEnding',
      );
    } catch (e) {
      debugPrint('⚠️ Error building bill: $e');
      return null;
    }
  }

  /// Parses Indian banking date formats: "25-Apr-26", "25 Apr 2026", "25/04/2026".
  static DateTime? _parseDueDate(String raw) {
    raw = raw.trim().replaceAll(RegExp(r'\s+'), ' ');

    const months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };

    // Pattern 1: dd-Mon-yy or dd Mon yyyy  e.g. "25 Apr 26"
    final p1 = RegExp(r'(\d{1,2})[-\/\s]([a-z]{3})[-\/\s]?(\d{2,4})',
        caseSensitive: false);
    final m1 = p1.firstMatch(raw);
    if (m1 != null) {
      final day = int.tryParse(m1.group(1)!);
      final month = months[m1.group(2)!.toLowerCase()];
      var year = int.tryParse(m1.group(3)!);
      if (year != null && year < 100) year += 2000;
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    // Pattern 2: dd/MM/yyyy or dd-MM-yyyy
    final p2 = RegExp(r'(\d{1,2})[-\/](\d{1,2})[-\/](\d{2,4})');
    final m2 = p2.firstMatch(raw);
    if (m2 != null) {
      final day = int.tryParse(m2.group(1)!);
      final month = int.tryParse(m2.group(2)!);
      var year = int.tryParse(m2.group(3)!);
      if (year != null && year < 100) year += 2000;
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    return null;
  }

  /// Matches UPI SMS against pending bills and auto-marks them paid.
  static void detectAndMatchUpiPayments(
    String message,
    DateTime smsTimestamp,
    List<Bill> pendingBills,
  ) {
    _enforceOfflinePrivacy();
    final m = upiRegExp.firstMatch(message);
    if (m != null) {
      final paidAmount =
          double.tryParse(m.group(1)?.replaceAll(',', '') ?? '0') ?? 0.0;
      for (final bill in pendingBills) {
        if (!bill.isPaid && (bill.amount - paidAmount).abs() < 1.0) {
          bill.isPaid = true;
          debugPrint(
              '✅ Auto-matched UPI ₹$paidAmount → bill ${bill.id}');
          break;
        }
      }
    }
  }

  static void _enforceOfflinePrivacy() {
    debugPrint('🔒 SMS parsing — strictly on-device, no network calls.');
  }
}
