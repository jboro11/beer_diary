import 'package:flutter_test/flutter_test.dart';
import 'package:beer_diary/core/models/beer.dart';
import 'package:beer_diary/core/models/beer_log.dart';
import 'package:beer_diary/core/models/user_profile.dart';
import 'package:beer_diary/core/models/friendship.dart';
import 'package:beer_diary/core/models/team.dart';

void main() {
  group('Beer model', () {
    test('fromJson creates correct instance', () {
      final json = {
        'id': 1,
        'name': 'Pilsner Urquell',
        'brewery': 'Plzeňský Prazdroj',
        'style': 'Lager',
        'abv': 4.4,
        'image_url': 'https://example.com/pilsner.jpg',
        'created_by': 'user-123',
        'created_at': '2025-01-01T12:00:00Z',
      };

      final beer = Beer.fromJson(json);

      expect(beer.id, 1);
      expect(beer.name, 'Pilsner Urquell');
      expect(beer.brewery, 'Plzeňský Prazdroj');
      expect(beer.style, 'Lager');
      expect(beer.abv, 4.4);
    });

    test('toJson produces correct map', () {
      const beer = Beer(
        name: 'Kozel',
        brewery: 'Velkopopovický Kozel',
        style: 'Lager',
        abv: 4.0,
        createdBy: 'user-456',
      );

      final json = beer.toJson();

      expect(json['name'], 'Kozel');
      expect(json['brewery'], 'Velkopopovický Kozel');
      expect(json.containsKey('id'), false);
    });
  });

  group('BeerLog model', () {
    test('fromJson creates correct instance', () {
      final json = {
        'id': 42,
        'user_id': 'user-123',
        'beer_id': 1,
        'beer_name': 'Pilsner Urquell',
        'rating': 5,
        'note': 'Skvělé!',
        'latitude': 49.7477,
        'longitude': 13.3776,
        'venue_name': 'Na Spilce',
        'logged_at': '2025-06-15T20:30:00Z',
        'created_at': '2025-06-15T20:30:01Z',
      };

      final log = BeerLog.fromJson(json);

      expect(log.id, 42);
      expect(log.beerName, 'Pilsner Urquell');
      expect(log.rating, 5);
      expect(log.latitude, 49.7477);
      expect(log.longitude, 13.3776);
      expect(log.venueName, 'Na Spilce');
    });

    test('toJson includes geolocation when present', () {
      final log = BeerLog(
        userId: 'user-123',
        beerName: 'Budvar',
        rating: 4,
        latitude: 48.975,
        longitude: 14.474,
        loggedAt: DateTime.parse('2025-06-15T20:00:00Z'),
      );

      final json = log.toJson();

      expect(json['beer_name'], 'Budvar');
      expect(json['latitude'], 48.975);
      expect(json['longitude'], 14.474);
      expect(json.containsKey('user_id'), true);
    });

    test('toJson omits null optional fields', () {
      final log = BeerLog(
        userId: 'user-123',
        beerName: 'Kozel',
        loggedAt: DateTime.parse('2025-06-15T20:00:00Z'),
      );

      final json = log.toJson();

      expect(json.containsKey('latitude'), false);
      expect(json.containsKey('longitude'), false);
      expect(json.containsKey('rating'), false);
      expect(json.containsKey('venue_name'), false);
    });

    test('copyWith creates modified copy', () {
      final original = BeerLog(
        userId: 'user-123',
        beerName: 'Kozel',
        rating: 3,
        loggedAt: DateTime.parse('2025-06-15T20:00:00Z'),
      );

      final modified = original.copyWith(rating: 5, venueName: 'U Fleků');

      expect(modified.rating, 5);
      expect(modified.venueName, 'U Fleků');
      expect(modified.beerName, 'Kozel');
      expect(modified.userId, 'user-123');
    });
  });

  group('UserProfile model', () {
    test('fromJson creates correct instance', () {
      final json = {
        'id': 'user-abc',
        'username': 'pivonka',
        'display_name': 'Jan Pivoňka',
        'avatar_url': 'https://example.com/avatar.jpg',
        'bio': 'Milovník piva',
        'created_at': '2025-01-01T00:00:00Z',
      };

      final profile = UserProfile.fromJson(json);

      expect(profile.id, 'user-abc');
      expect(profile.username, 'pivonka');
      expect(profile.displayName, 'Jan Pivoňka');
    });

    test('toJson produces correct map', () {
      const profile = UserProfile(
        id: 'user-abc',
        username: 'pivonka',
        displayName: 'Jan Pivoňka',
      );

      final json = profile.toJson();

      expect(json['username'], 'pivonka');
      expect(json['display_name'], 'Jan Pivoňka');
    });
  });

  group('Friendship model', () {
    test('fromJson creates correct instance', () {
      final json = {
        'id': 1,
        'requester_id': 'user-a',
        'addressee_id': 'user-b',
        'status': 'accepted',
        'created_at': '2025-01-01T00:00:00Z',
      };

      final friendship = Friendship.fromJson(json);

      expect(friendship.status, FriendshipStatus.accepted);
      expect(friendship.requesterId, 'user-a');
      expect(friendship.addresseeId, 'user-b');
    });

    test('toJson includes status as string', () {
      const friendship = Friendship(
        requesterId: 'user-a',
        addresseeId: 'user-b',
        status: FriendshipStatus.pending,
      );

      final json = friendship.toJson();

      expect(json['status'], 'pending');
    });
  });

  group('Team model', () {
    test('fromJson creates correct instance', () {
      final json = {
        'id': 1,
        'name': 'Plzeňáci',
        'description': 'Tým fanoušků Pilsneru',
        'owner_id': 'user-123',
        'created_at': '2025-01-01T00:00:00Z',
      };

      final team = Team.fromJson(json);

      expect(team.id, 1);
      expect(team.name, 'Plzeňáci');
      expect(team.ownerId, 'user-123');
    });
  });

  group('TeamMember model', () {
    test('fromJson creates correct instance', () {
      final json = {
        'team_id': 1,
        'user_id': 'user-123',
        'role': 'admin',
        'joined_at': '2025-01-01T00:00:00Z',
      };

      final member = TeamMember.fromJson(json);

      expect(member.teamId, 1);
      expect(member.userId, 'user-123');
      expect(member.role, 'admin');
    });

    test('toJson defaults role to member', () {
      const member = TeamMember(
        teamId: 1,
        userId: 'user-456',
      );

      final json = member.toJson();

      expect(json['role'], 'member');
    });
  });
}
