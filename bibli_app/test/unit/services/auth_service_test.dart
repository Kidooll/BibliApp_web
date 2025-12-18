import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bibli_app/features/auth/services/auth_service.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockAuthResponse extends Mock implements AuthResponse {}
class MockUser extends Mock implements User {}

void main() {
  group('AuthService', () {
    late AuthService authService;
    late MockSupabaseClient mockClient;
    late MockGoTrueClient mockAuth;

    setUp(() {
      mockClient = MockSupabaseClient();
      mockAuth = MockGoTrueClient();
      authService = AuthService(mockClient);
      
      when(() => mockClient.auth).thenReturn(mockAuth);
    });

    group('signUp', () {
      test('deve chamar signUp com parâmetros corretos', () async {
        final mockResponse = MockAuthResponse();
        final mockUser = MockUser();
        
        when(() => mockAuth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          data: any(named: 'data'),
        )).thenAnswer((_) async => mockResponse);
        
        when(() => mockResponse.user).thenReturn(mockUser);

        await authService.signUp(
          email: 'test@example.com',
          password: 'Password123@',
          name: 'Test User',
        );

        verify(() => mockAuth.signUp(
          email: 'test@example.com',
          password: 'Password123@',
          data: {'name': 'Test User'},
        )).called(1);
      });

      test('deve lançar exceção para email inválido', () async {
        expect(
          () => authService.signUp(
            email: 'invalid-email',
            password: 'Password123@',
            name: 'Test User',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('deve lançar exceção para senha fraca', () async {
        expect(
          () => authService.signUp(
            email: 'test@example.com',
            password: 'weak',
            name: 'Test User',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('signIn', () {
      test('deve chamar signIn com parâmetros corretos', () async {
        final mockResponse = MockAuthResponse();
        final mockUser = MockUser();
        
        when(() => mockAuth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => mockResponse);
        
        when(() => mockResponse.user).thenReturn(mockUser);

        await authService.signInWithEmail(
          email: 'test@example.com',
          password: 'Password123@',
        );

        verify(() => mockAuth.signInWithPassword(
          email: 'test@example.com',
          password: 'Password123@',
        )).called(1);
      });

      test('deve lançar exceção para email inválido', () async {
        expect(
          () => authService.signInWithEmail(
            email: 'invalid-email',
            password: 'Password123@',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('signOut', () {
      test('deve chamar signOut', () async {
        when(() => mockAuth.signOut()).thenAnswer((_) async {});

        await authService.signOut();

        verify(() => mockAuth.signOut()).called(1);
      });
    });
  });
}