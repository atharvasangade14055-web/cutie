import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/message_model.dart';

class FirebaseService {
  FirebaseService._();

  static final FirebaseService instance = FirebaseService._();

  static const _userCacheKey = 'current_user_id';
  static const Map<String, String> _allowedUserIds = {
    'atharva': 'atharva',
    'sonal': 'sonal',
    'gf': 'sonal',
  };
  static const Map<String, Map<String, String>> _defaultUsers = {
    'atharva': {'password': 'Badboy', 'name': 'Atharva'},
    'sonal': {'password': 'Goodgirl', 'name': 'Sonal'},
  };

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _seedDefaultUsers();
  }

  String? getCurrentUser() => _prefs?.getString(_userCacheKey);

  Future<void> logout() async {
    await _prefs?.remove(_userCacheKey);
  }

  Future<bool> loginUser(String rawId, String password) async {
    final normalizedId = _normalizeUserId(rawId);
    if (normalizedId == null) {
      return false;
    }

    try {
      final snapshot = await _database.ref('users/$normalizedId').get();
      if (!snapshot.exists) {
        return false;
      }

      final data = snapshot.value;
      if (data is! Map) {
        return false;
      }

      final map = Map<dynamic, dynamic>.from(data);
      final storedPassword = map['password']?.toString() ?? '';

      if (storedPassword != password) {
        return false;
      }

      await _prefs?.setString(_userCacheKey, normalizedId);
      return true;
    } catch (error, stackTrace) {
      debugPrint('Login failed: $error');
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  Future<void> sendMessage(String text, String sender) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Message cannot be empty');
    }

    final normalizedSender = _normalizeUserId(sender) ?? sender;

    try {
      final ref = _database.ref('chat').push();
      await ref.set({
        'sender': normalizedSender,
        'text': trimmed,
        'timestamp': ServerValue.timestamp,
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to send message: $error');
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  Stream<List<Message>> getMessagesStream() {
    final ref = _database.ref('chat').orderByChild('timestamp');
    return ref.onValue.map((event) {
      final snapshot = event.snapshot;
      final value = snapshot.value;

      if (value == null) {
        return <Message>[];
      }

      final messages = <Message>[];

      if (value is List) {
        for (final entry in value) {
          if (entry is Map) {
            messages.add(_messageFromMap(entry));
          }
        }
      } else if (value is Map) {
        value.forEach((key, entry) {
          if (entry is Map) {
            messages.add(_messageFromMap(entry));
          }
        });
      }

      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Auto-mark messages from other users as delivered
      _markOtherMessagesDelivered(messages);

      return messages;
    });
  }

  Future<void> markMessageDelivered(String messageId) async {
    try {
      await _database.ref('chat/$messageId/deliveredAt').set(ServerValue.timestamp);
    } catch (error, stackTrace) {
      debugPrint('Failed to mark message delivered: $error');
      debugPrint('$stackTrace');
    }
  }

  Future<void> markMessageRead(String messageId) async {
    try {
      await _database.ref('chat/$messageId/readAt').set(ServerValue.timestamp);
    } catch (error, stackTrace) {
      debugPrint('Failed to mark message read: $error');
      debugPrint('$stackTrace');
    }
  }

  Future<void> markUnreadMessagesAsRead(String currentUser) async {
    try {
      final snapshot = await _database.ref('chat').orderByChild('timestamp').get();
      final value = snapshot.value;
      if (value is! Map) return;

      value.forEach((key, msgData) {
        if (msgData is Map) {
          final sender = msgData['sender']?.toString();
          final readAt = msgData['readAt'];
          if (sender != null && sender != currentUser && readAt == null) {
            _database.ref('chat/$key/readAt').set(ServerValue.timestamp);
          }
        }
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to mark unread messages as read: $error');
      debugPrint('$stackTrace');
    }
  }

  void _markOtherMessagesDelivered(List<Message> messages) {
    final currentUser = getCurrentUser();
    if (currentUser == null) return;

    for (final msg in messages) {
      if (msg.sender != currentUser && msg.deliveredAt == null) {
        // Fire-and-forget: mark as delivered in the background
        _database.ref('chat').orderByChild('timestamp').equalTo(msg.timestamp).once().then((event) {
          final snapshot = event.snapshot;
          if (snapshot.value is Map) {
            (snapshot.value as Map).forEach((key, value) {
              if (value is Map && value['sender'] == msg.sender) {
                _database.ref('chat/$key/deliveredAt').set(ServerValue.timestamp);
              }
            });
          }
        });
      }
    }
  }

  Message _messageFromMap(Map<dynamic, dynamic> data) {
    return Message.fromMap(Map<dynamic, dynamic>.from(data));
  }

  String? _normalizeUserId(String rawId) {
    final sanitized = rawId.trim().toLowerCase();
    if (sanitized.isEmpty) {
      return null;
    }

    return _allowedUserIds[sanitized];
  }

  Future<void> _seedDefaultUsers() async {
    try {
      final usersRef = _database.ref('users');
      final snapshot = await usersRef.get();
      final existing = snapshot.value is Map
          ? Map<dynamic, dynamic>.from(snapshot.value as Map)
          : <dynamic, dynamic>{};

      for (final entry in _defaultUsers.entries) {
        if (!existing.containsKey(entry.key)) {
          await usersRef.child(entry.key).set(entry.value);
        }
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to seed default users: $error');
      debugPrint('$stackTrace');
    }
  }
}
