import 'package:flutter_test/flutter_test.dart';
import 'package:navodayan/models/auth_user.dart';
import 'package:navodayan/models/batch.dart';
import 'package:navodayan/models/chat_models.dart';
import 'package:navodayan/models/event_item.dart';
import 'package:navodayan/models/mentorship_request.dart';
import 'package:navodayan/models/notification_item.dart';
import 'package:navodayan/models/profile.dart';
import 'package:navodayan/models/school.dart';

void main() {
  group('AuthUser & UserProfile Models', () {
    test('serializes and deserializes AuthUser correctly', () {
      final json = {
        'id': 'user-123',
        'email': 'alumni@navodaya.org',
        'role': 'ADMIN',
        'profile': {
          'id': 'prof-456',
          'fullName': 'Rahul Sharma',
          'openToMentor': true,
          'approvalStatus': 'APPROVED',
        },
      };

      final user = AuthUser.fromJson(json);
      expect(user.id, 'user-123');
      expect(user.email, 'alumni@navodaya.org');
      expect(user.role, 'ADMIN');
      expect(user.isAdmin, true);
      expect(user.isApproved, true);
      expect(user.profile?.id, 'prof-456');
      expect(user.profile?.fullName, 'Rahul Sharma');
      expect(user.profile?.openToMentor, true);

      final serialized = user.toJson();
      expect(serialized['id'], 'user-123');
      expect(serialized['email'], 'alumni@navodaya.org');
      expect(serialized['role'], 'ADMIN');
      expect((serialized['profile'] as Map)['fullName'], 'Rahul Sharma');
    });
  });

  group('School & Batch Models', () {
    test('deserializes School correctly', () {
      final json = {
        'jnv_id': '101',
        'name': 'JNV Patna',
        'distt': 'Patna',
        'state': {'id': 1, 'name': 'Bihar'},
      };

      final school = School.fromJson(json);
      expect(school.jnvId, '101');
      expect(school.name, 'JNV Patna');
      expect(school.distt, 'Patna');
      expect(school.state?.name, 'Bihar');
      expect(school.displayName, 'JNV Patna, Patna (Bihar)');
    });

    test('deserializes Batch correctly', () {
      final json = {
        'id': 'batch-2015',
        'startYear': 2008,
        'endYear': 2015,
      };

      final batch = Batch.fromJson(json);
      expect(batch.id, 'batch-2015');
      expect(batch.startYear, 2008);
      expect(batch.endYear, 2015);
      expect(batch.displayName, '2008-2015');
    });
  });

  group('EventItem Model', () {
    test('deserializes and checks isUpcoming', () {
      final futureDate = DateTime.now().add(const Duration(days: 10));
      final json = {
        'id': 'evt-1',
        'title': 'Navodayan Annual Meetup',
        'description': 'Meet fellow alumni in Bengaluru',
        'eventDate': futureDate.toIso8601String(),
        'location': 'Bengaluru',
        '_count': {'eventrsvp': 25},
      };

      final event = EventItem.fromJson(json);
      expect(event.id, 'evt-1');
      expect(event.title, 'Navodayan Annual Meetup');
      expect(event.location, 'Bengaluru');
      expect(event.rsvpCount, 25);
      expect(event.isUpcoming, true);
    });
  });

  group('MentorshipRequest Model', () {
    test('deserializes MentorshipRequest correctly', () {
      final json = {
        'id': 'req-1',
        'requesterId': 'p-1',
        'mentorId': 'p-2',
        'message': 'Looking for career advice in AI',
        'status': 'ACCEPTED',
        'requester': {
          'id': 'p-1',
          'fullName': 'Amit',
          'batchYear': '2018',
          'user': {'email': 'amit@navodaya.org'},
        },
        'mentor': {
          'id': 'p-2',
          'fullName': 'Dr. Sharma',
          'currentRole': 'AI Researcher',
          'user': {'email': 'sharma@navodaya.org'},
        },
      };

      final req = MentorshipRequest.fromJson(json);
      expect(req.id, 'req-1');
      expect(req.status, MentorshipStatus.accepted);
      expect(req.requester?.fullName, 'Amit');
      expect(req.mentor?.fullName, 'Dr. Sharma');
      expect(req.mentor?.user?.email, 'sharma@navodaya.org');
    });
  });

  group('Profile Model', () {
    test('serializes and deserializes Profile with nested objects', () {
      final json = {
        'id': 'p-1',
        'fullName': 'Priya Singh',
        'currentRole': 'Software Engineer',
        'company': 'Google',
        'location': 'Bengaluru, India',
        'openToMentor': true,
        'industry': 'Technology',
        'skills': [
          {'skill': {'id': 's-1', 'name': 'Flutter'}},
          'Dart',
        ],
      };

      final profile = Profile.fromJson(json);
      expect(profile.id, 'p-1');
      expect(profile.fullName, 'Priya Singh');
      expect(profile.currentRole, 'Software Engineer');
      expect(profile.company, 'Google');
      expect(profile.openToMentor, true);
      expect(profile.skills.length, 2);
      expect(profile.skills[0].name, 'Flutter');
      expect(profile.skills[1].name, 'Dart');

      final serialized = profile.toJson();
      expect(serialized['fullName'], 'Priya Singh');
      expect(serialized['openToMentor'], true);
    });
  });

  group('NotificationItem Model', () {
    test('serializes and deserializes NotificationItem correctly', () {
      final json = {
        'id': 'notif-1',
        'title': 'New Mentorship Request',
        'body': 'Priya sent you a mentorship request',
        'type': 'mentorshipRequest',
        'createdAt': DateTime.now().toIso8601String(),
        'isRead': false,
        'data': {'mentorId': 'p-1'},
      };

      final notif = NotificationItem.fromJson(json);
      expect(notif.id, 'notif-1');
      expect(notif.title, 'New Mentorship Request');
      expect(notif.type, NotificationType.mentorshipRequest);
      expect(notif.isRead, false);

      final copy = notif.copyWith(isRead: true);
      expect(copy.isRead, true);

      final serialized = copy.toJson();
      expect(serialized['isRead'], true);
      expect(serialized['type'], 'mentorshipRequest');
    });
  });

  group('Chat Models', () {
    test('serializes and deserializes ChatRequest and ChatMessage', () {
      final reqJson = {
        'id': 'req-1',
        'senderId': 'u-1',
        'senderName': 'Aarav Patel',
        'receiverId': 'u-2',
        'receiverName': 'Neha Sharma',
        'message': 'Hi Neha, lets connect!',
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
      };

      final req = ChatRequest.fromJson(reqJson);
      expect(req.id, 'req-1');
      expect(req.status, ChatRequestStatus.pending);
      expect(req.senderName, 'Aarav Patel');

      final msgJson = {
        'id': 'msg-1',
        'conversationId': 'conv-1',
        'senderId': 'u-1',
        'receiverId': 'u-2',
        'text': 'Hello world',
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': true,
      };

      final msg = ChatMessage.fromJson(msgJson);
      expect(msg.text, 'Hello world');
      expect(msg.conversationId, 'conv-1');
      expect(msg.isRead, true);
    });
  });
}
