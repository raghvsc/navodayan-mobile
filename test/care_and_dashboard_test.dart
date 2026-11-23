import 'package:flutter_test/flutter_test.dart';
import 'package:navodayan/models/care_session.dart';
import 'package:navodayan/models/profile.dart';

void main() {
  group('CareSession Model Tests', () {
    test('Parses CareSession from JSON properly', () {
      final json = {
        'id': 'session-123',
        'title': 'UPSC Civil Services Preparation',
        'note': 'Strategies for prelims and mains.',
        'status': 'OPEN',
        'audiences': ['STUDENTS', 'ALUMNI'],
        'wantsToLearn': true,
        'canLead': false,
        'consentCount': 12,
        'consented': false,
      };

      final session = CareSession.fromJson(json);

      expect(session.id, 'session-123');
      expect(session.title, 'UPSC Civil Services Preparation');
      expect(session.note, 'Strategies for prelims and mains.');
      expect(session.status, 'OPEN');
      expect(session.audiences, ['STUDENTS', 'ALUMNI']);
      expect(session.wantsToLearn, true);
      expect(session.canLead, false);
      expect(session.consentCount, 12);
      expect(session.consented, false);

      final updated = session.copyWith(consented: true, consentCount: 13);
      expect(updated.consented, true);
      expect(updated.consentCount, 13);
    });

    test('Handles missing and null fields gracefully', () {
      final json = <String, dynamic>{
        'id': 'empty-session',
        'title': 'General Meet',
      };

      final session = CareSession.fromJson(json);
      expect(session.id, 'empty-session');
      expect(session.title, 'General Meet');
      expect(session.note, isNull);
      expect(session.audiences, isEmpty);
      expect(session.consentCount, 0);
      expect(session.consented, false);
    });
  });

  group('Profile Web Parity Tests', () {
    test('Parses full privacy settings, posting status, and verification', () {
      final json = {
        'id': 'user-999',
        'fullName': 'Suresh Kumar',
        'currentRole': 'Senior Architect',
        'company': 'GovTech',
        'postingStatus': 'SCHOOL',
        'jnvVerified': true,
        'approvalStatus': 'ACTIVE',
        'profileVisibility': 'PUBLIC',
        'emailVisibility': 'JNV',
        'phoneVisibility': 'NONE',
        'educationVisibility': 'JNV',
      };

      final profile = Profile.fromJson(json);
      expect(profile.id, 'user-999');
      expect(profile.fullName, 'Suresh Kumar');
      expect(profile.postingStatus, 'SCHOOL');
      expect(profile.postingStatusLabel, 'Posted at a JNV');
      expect(profile.isJnvVerified, isTrue);
      expect(profile.profileVisibility, 'PUBLIC');
      expect(profile.emailVisibility, 'JNV');
      expect(profile.phoneVisibility, 'NONE');
      expect(profile.educationVisibility, 'JNV');

      final serialized = profile.toJson();
      expect(serialized['postingStatus'], 'SCHOOL');
      expect(serialized['profileVisibility'], 'PUBLIC');
      expect(serialized['emailVisibility'], 'JNV');
      expect(serialized['phoneVisibility'], 'NONE');
    });
  });
}

