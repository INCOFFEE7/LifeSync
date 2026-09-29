import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:lifesync_app/data/providers/google_auth_client.dart';
import 'package:lifesync_app/config/app_variant.dart';
import 'package:lifesync_app/main.dart';

final googleAuthServiceProvider = Provider((ref) => GoogleAuthService());

class GoogleAuthService {
  final _storage = const FlutterSecureStorage();
  
  String get _spreadsheetIdKey => 
      AppEnvironment.config.variant == AppVariant.beebee 
          ? 'google_spreadsheet_id_beebee' 
          : 'google_spreadsheet_id';
  
  final gsi.GoogleSignIn _googleSignIn = gsi.GoogleSignIn(
    scopes: [
      drive.DriveApi.driveFileScope,
      sheets.SheetsApi.spreadsheetsScope,
    ],
  );

  gsi.GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  Future<gsi.GoogleSignInAccount?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      return account;
    } catch (e) {
      return null;
    }
  }
  
  Future<gsi.GoogleSignInAccount?> signInSilently() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (e) {
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.disconnect();
    await _storage.delete(key: _spreadsheetIdKey);
  }
  
  Future<http.Client?> getAuthenticatedClient() async {
    final user = _googleSignIn.currentUser;
    if (user == null) return null;
    
    final auth = await user.authentication;
    final token = auth.accessToken;
    
    if (token == null) return null;
    
    return GoogleAuthClient({'Authorization': 'Bearer $token'});
  }
  
  Future<void> saveSpreadsheetId(String id) async {
    await _storage.write(key: _spreadsheetIdKey, value: id);
  }
  
  Future<String?> getSpreadsheetId() async {
    return await _storage.read(key: _spreadsheetIdKey);
  }
}
