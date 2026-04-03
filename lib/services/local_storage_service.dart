import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const _cardsKey = 'smart_cards';
  static const _giftCardsKey = 'gift_cards';
  static const _transactionsKey = 'transactions';
  static const _billsKey = 'bills';
  static const _utilityBillersKey = 'utility_billers';
  static const _backupEnabledKey = 'backup_enabled';
  static const _lastBackupKey = 'last_backup_time';
  static const _notesKey = 'notes';
  static const _tasksKey = 'tasks';

  // ── Smart Cards ──────────────────────────────────────────
  static Future<void> saveCards(List<Map<String, dynamic>> cards) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cardsKey, jsonEncode(cards));
  }

  static Future<List<Map<String, dynamic>>> loadCards() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cardsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // ── Gift Cards ────────────────────────────────────────────
  static Future<void> saveGiftCards(List<Map<String, dynamic>> cards) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_giftCardsKey, jsonEncode(cards));
  }

  static Future<List<Map<String, dynamic>>> loadGiftCards() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_giftCardsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // ── Transactions ──────────────────────────────────────────
  static Future<void> saveTransactions(List<Map<String, dynamic>> txns) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_transactionsKey, jsonEncode(txns));
  }

  static Future<List<Map<String, dynamic>>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_transactionsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // ── Bills ─────────────────────────────────────────────────
  static Future<void> saveBills(List<Map<String, dynamic>> bills) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_billsKey, jsonEncode(bills));
  }

  static Future<List<Map<String, dynamic>>> loadBills() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_billsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // ── Utility Billers ──────────────────────────────────────
  static Future<void> saveUtilityBillers(List<Map<String, dynamic>> billers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_utilityBillersKey, jsonEncode(billers));
  }

  static Future<List<Map<String, dynamic>>> loadUtilityBillers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_utilityBillersKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // ── Backup Settings ───────────────────────────────────────
  static Future<bool> getBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_backupEnabledKey) ?? false;
  }

  static Future<void> setBackupEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_backupEnabledKey, value);
  }

  static Future<String?> getLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastBackupKey);
  }

  static Future<void> setLastBackupTime(String time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastBackupKey, time);
  }

  // ── Notes ─────────────────────────────────────────────────
  static Future<void> saveNotes(List<Map<String, dynamic>> notes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_notesKey, jsonEncode(notes));
  }

  static Future<List<Map<String, dynamic>>> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_notesKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // ── Tasks ─────────────────────────────────────────────────
  static Future<void> saveTasks(List<Map<String, dynamic>> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tasksKey, jsonEncode(tasks));
  }

  static Future<List<Map<String, dynamic>>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_tasksKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // ── Full Export (for Drive backup) ────────────────────────
  static Future<String> exportAllAsJson() async {
    final cards = await loadCards();
    final giftCards = await loadGiftCards();
    final transactions = await loadTransactions();
    final bills = await loadBills();
    final utilityBillers = await loadUtilityBillers();
    final notes = await loadNotes();
    final tasks = await loadTasks();
    return jsonEncode({
      'smart_cards': cards,
      'gift_cards': giftCards,
      'transactions': transactions,
      'bills': bills,
      'utility_billers': utilityBillers,
      'notes': notes,
      'tasks': tasks,
      'exported_at': DateTime.now().toIso8601String(),
    });
  }
}
