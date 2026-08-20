import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:navodayan/services/api_client.dart';
import 'package:navodayan/services/contact_service.dart';
import 'package:navodayan/services/events_service.dart';
import 'package:navodayan/services/mentorship_service.dart';
import 'package:navodayan/services/schools_batches_service.dart';

void main() {
  group('SchoolsBatchesService Tests', () {
    test('fetches schools and batches correctly', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/schools')) {
          return http.Response(
            jsonEncode([
              {'jnv_id': '1', 'name': 'JNV Bangalore Urban', 'distt': 'Bangalore'}
            ]),
            200,
          );
        } else if (request.url.path.endsWith('/batches')) {
          return http.Response(
            jsonEncode([
              {'id': 'b-1', 'startYear': 2010, 'endYear': 2017}
            ]),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final api = ApiClient(baseUrl: 'http://test.local/api', client: mockClient);
      final service = SchoolsBatchesService(apiClient: api);

      final schools = await service.getSchools();
      expect(schools.length, 1);
      expect(schools.first.name, 'JNV Bangalore Urban');

      final batches = await service.getBatches();
      expect(batches.length, 1);
      expect(batches.first.displayName, '2010-2017');
    });
  });

  group('EventsService Tests', () {
    test('fetches events and creates event', () async {
      final mockClient = MockClient((request) async {
        if (request.method == 'GET' && request.url.path.endsWith('/events')) {
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 'e-1',
                  'title': 'Alumni Meet 2026',
                  'description': 'Annual gathering',
                  'location': 'New Delhi',
                  'eventDate': '2026-10-10T10:00:00Z',
                  '_count': {'eventrsvp': 10}
                }
              ]
            }),
            200,
          );
        } else if (request.method == 'POST' && request.url.path.endsWith('/events')) {
          return http.Response(jsonEncode({'success': true}), 201);
        } else if (request.method == 'POST' && request.url.path.endsWith('/rsvp')) {
          return http.Response(jsonEncode({'success': true}), 200);
        }
        return http.Response('Not found', 404);
      });

      final api = ApiClient(baseUrl: 'http://test.local/api', client: mockClient);
      final service = EventsService(apiClient: api);

      final events = await service.getEvents();
      expect(events.length, 1);
      expect(events.first.title, 'Alumni Meet 2026');

      await expectLater(
        service.createEvent(
          title: 'Test',
          description: 'Desc',
          eventDate: '2026-10-10T10:00:00Z',
          location: 'Delhi',
          token: 'token123',
        ),
        completes,
      );

      await expectLater(
        service.rsvpEvent(eventId: 'e-1', token: 'token123'),
        completes,
      );
    });
  });

  group('MentorshipService Tests', () {
    test('fetches mentors and sends mentorship request', () async {
      final mockClient = MockClient((request) async {
        if (request.method == 'GET' && request.url.path.endsWith('/directory/search')) {
          expect(request.url.queryParameters['openToMentor'], 'true');
          return http.Response(
            jsonEncode({
              'data': [
                {'id': 'm-1', 'fullName': 'Mentor One', 'openToMentor': true}
              ]
            }),
            200,
          );
        } else if (request.method == 'POST' && request.url.path.endsWith('/mentorship/request')) {
          return http.Response(jsonEncode({'success': true}), 200);
        }
        return http.Response('Not found', 404);
      });

      final api = ApiClient(baseUrl: 'http://test.local/api', client: mockClient);
      final service = MentorshipService(apiClient: api);

      final mentors = await service.getMentors();
      expect(mentors.length, 1);
      expect(mentors.first.fullName, 'Mentor One');

      await expectLater(
        service.sendMentorshipRequest(
          mentorId: 'm-1',
          message: 'Hello, need guidance',
          token: 'token123',
        ),
        completes,
      );
    });
  });

  group('ContactService Tests', () {
    test('submits contact message', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path.endsWith('/contact'), true);
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['name'], 'User Test');
        expect(body['email'], 'test@example.com');
        return http.Response(jsonEncode({'message': 'Sent'}), 200);
      });

      final api = ApiClient(baseUrl: 'http://test.local/api', client: mockClient);
      final service = ContactService(apiClient: api);

      await expectLater(
        service.submitContact(
          name: 'User Test',
          email: 'test@example.com',
          subject: 'Feedback',
          message: 'Great app!',
        ),
        completes,
      );
    });
  });
}
