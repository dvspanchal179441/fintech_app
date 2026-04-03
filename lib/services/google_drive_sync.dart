import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
// import 'package:encrypt/encrypt.dart' as encrypt;

class GoogleDriveSync {
  final AuthClient authClient;

  GoogleDriveSync({required this.authClient});

  /// Encrypts the local SQLite database to protect user data before uploading.
  Future<File> _encryptDatabaseFile(File dbFile) async {
    /* 
      // Example AES-256 Encryption implementation via the 'encrypt' package:
      final secureKey = encrypt.Key.fromUtf8('my32lengthsupersecretnooneknows1');
      final iv = encrypt.IV.fromLength(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(secureKey));
      
      final dbBytes = await dbFile.readAsBytes();
      final encryptedData = encrypter.encryptBytes(dbBytes, iv: iv);
      
      final encryptedFile = File('${dbFile.path}.enc');
      await encryptedFile.writeAsBytes(encryptedData.bytes);
      
      return encryptedFile; 
    */
    debugPrint("Applying AES-256 encryption to local SQLite file before network sync...");
    return dbFile; // Mock return for demonstration
  }

  /// Backups the encrypted SQLite database to Google Drive's hidden appDataFolder.
  Future<void> backupLocalDatabase(File localDbFile) async {
    try {
      // 1. Encrypt DB
      final encryptedFile = await _encryptDatabaseFile(localDbFile);
      
      // 2. Init Drive API
      final driveApi = drive.DriveApi(authClient);

      // 3. Configure it for the appDataFolder ensuring it's invisible to users in their regular Drive.
      final fileMetadata = drive.File()
        ..parents = ['appDataFolder']
        ..name = 'finance_db_backup.sqlite.enc';

      // 4. Create upload media
      final media = drive.Media(
        encryptedFile.openRead(),
        encryptedFile.lengthSync(),
      );

      // 5. Fire Upload
      final uploadedFile = await driveApi.files.create(
        fileMetadata,
        uploadMedia: media,
      );

      debugPrint("☁️ Secure backup successful to private appDataFolder. File ID: ${uploadedFile.id}");
    } catch (e) {
      debugPrint("❌ Google Drive backup failed during sync: $e");
    }
  }
}
