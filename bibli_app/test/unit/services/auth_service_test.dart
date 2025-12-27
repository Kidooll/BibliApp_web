import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bibli_app/features/auth/services/auth_service.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockAuthResponse extends Mock implements AuthResponse {}
class MockUser extends Mock implements User {}
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}
class MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder<dynamic> {}

void main() {
  group('AuthService', () {
    late AuthService authService;
    late MockSupabaseClient mockClient;
    late MockGoTrueClient mockAuth;
    late MockSupabaseQueryBuilder mockQueryBuilder;
    late MockPostgrestFilterBuilder mockFilterBuilder;
    late MockUser mockCurrentUser;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
    });

    setUp(() {
      mockClient = MockSupabaseClient();
      mockAuth = MockGoTrueClient();
      mockQueryBuilder = MockSupabaseQueryBuilder();
      mockFilterBuilder = MockPostgrestFilterBuilder();
      mockCurrentUser = MockUser();
      authService = AuthService(mockClient);
      
      when(() => mockClient.auth).thenReturn(mockAuth);
      when(() => mockAuth.currentUser).thenReturn(mockCurrentUser);
      when(() => mockCurrentUser.id).thenReturn('user-id');
      when(() => mockClient.from(any())).thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.insert(any()))
          .thenAnswer((_) => mockFilterBuilder);
      when(() => mockQueryBuilder.upsert(
            any(),
            onConflict: any(named: 'onConflict'),
          )).thenAnswer((_) => mockFilterBuilder);
      when(() => mockQueryBuilder.update(any()))
          .thenAnswer((_) => mockFilterBuilder);
      when(() => mockFilterBuilder.eq(any(), any()))
          .thenAnswer((_) => mockFilterBuilder);
      when(() => mockFilterBuilder.then<dynamic>(
            any(),
            onError: any(named: 'onError'),
          )).thenAnswer((invocation) async {
        final onValue = invocation.positionalArguments.first as dynamic;
        return onValue(<String, dynamic>{});
      });
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
        when(() => mockUser.id).thenReturn('user-id');

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

      test('deve propagar exceção do Supabase para email inválido', () async {
        when(() => mockAuth.signUp(
              email: any(named: 'email'),
              password: any(named: 'password'),
              data: any(named: 'data'),
            )).thenThrow(const AuthException('Email inválido'));

        expect(
          () => authService.signUp(
            email: 'invalid-email',
            password: 'Password123@',
            name: 'Test User',
          ),
          throwsA(isA<AuthException>()),
        );
      });

      test('deve propagar exceção do Supabase para senha fraca', () async {
        when(() => mockAuth.signUp(
              email: any(named: 'email'),
              password: any(named: 'password'),
              data: any(named: 'data'),
            )).thenThrow(const AuthException('Senha inválida'));

        expect(
          () => authService.signUp(
            email: 'test@example.com',
            password: 'weak',
            name: 'Test User',
          ),
          throwsA(isA<AuthException>()),
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
        
        when(() => mockResponse.user).thenReturn(null);

        await authService.signInWithEmail(
          email: 'test@example.com',
          password: 'Password123@',
        );

        verify(() => mockAuth.signInWithPassword(
          email: 'test@example.com',
          password: 'Password123@',
        )).called(1);
      });

      test('deve propagar exceção do Supabase para email inválido', () async {
        when(() => mockAuth.signInWithPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(const AuthException('Email inválido'));

        expect(
          () => authService.signInWithEmail(
            email: 'invalid-email',
            password: 'Password123@',
          ),
          throwsA(isA<AuthException>()),
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
