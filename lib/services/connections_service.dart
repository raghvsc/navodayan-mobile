import 'package:flutter/foundation.dart';
import '../models/connection.dart';
import 'api_client.dart';

class ConnectionsService {
  final ApiClient _client;

  ConnectionsService({ApiClient? client}) : _client = client ?? ApiClient();

  Future<ConnectionsData> getConnections() async {
    try {
      final response = await _client.get('/connect');
      return ConnectionsData.fromJson(response);
    } catch (e) {
      debugPrint('ConnectionsService.getConnections error: $e');
      rethrow;
    }
  }

  Future<bool> respondToRequest(String requestId, {required bool accept}) async {
    try {
      await _client.post(
        '/connect/$requestId/respond',
        {'status': accept ? 'ACCEPTED' : 'REJECTED'},
      );
      return true;
    } catch (e) {
      debugPrint('ConnectionsService.respondToRequest error: $e');
      rethrow;
    }
  }

  Future<bool> sendConnectionRequest(String targetUserId, {String? note}) async {
    try {
      await _client.post(
        '/connect',
        {
          'targetUserId': targetUserId,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );
      return true;
    } catch (e) {
      debugPrint('ConnectionsService.sendConnectionRequest error: $e');
      rethrow;
    }
  }
}
