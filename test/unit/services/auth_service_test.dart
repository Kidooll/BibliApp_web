import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bibli_app/features/auth/services/auth_service.dart';
import 'package:bibli_app/core/constants/app_strings.dart';
import '../../mocks.dart';

void main() {
  group('AuthService', () {
    late AuthService authService;
    late MockSupabaseClient mockClient;
    late MockGoTrueClient mockAuth;

    setUp(() {
      mockClient = MockSupabaseClient();
      mockAuth = MockGoTrueClient();
      when(mockClient.auth).thenReturn(mockAuth);
      authService = AuthService(mockClient);
    });

    group('signUp', () {
      test('deve criar usuário com sucesso', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'Test123!';
        final mockResponse = AuthResponse(
          user: User(
            id: 'user-id',
            appMetadata: {},
            userMetadata: {},
            aud: 'authenticated',
            createdAt: DateTime.now().toIso8601String(),
          ),
          session: null,
        );

        when(mockAuth.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => mockResponse);

        // Act
        final result = await authService.signUp(email: email, password: password);

        // Assert
        expect(result, isTrue);
        verify(mockAuth.signUp(email: email, password: password)).called(1);
      });

      test('deve retornar false quando signup falha', () async {
        // Arrange
        when(mockAuth.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(AuthException('Erro de autenticação'));

        // Act
        final result = await authService.signUp(
          email: 'test@example.com',
          password: 'Test123!',
        );

        // Assert
        expect(result, isFalse);
      });
    });

    group('signIn', () {
      test('deve fazer login com sucesso', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'Test123!';
        final mockResponse = AuthResponse(
          user: User(
            id: 'user-id',
            appMetadata: {},
            userMetadata: {},
            aud: 'authenticated',
            createdAt: DateTime.now().toIso8601String(),
          ),
          session: Session(
            accessToken: 'access-token',
            refreshToken: 'refresh-token',
            expiresIn: 3600,
            tokenType: 'bearer',
            user: User(
              id: 'user-id',
              appMetadata: {},
              userMetadata: {},
              aud: 'authenticated',
              createdAt: DateTime.now().toIso8601String(),
            ),
          ),
        );

        when(mockAuth.signInWithPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => mockResponse);

        // Act
        final result = await authService.signIn(email: email, password: password);

        // Assert
        expect(result, isTrue);
        verify(mockAuth.signInWithPassword(email: email, password: password)).called(1);
      });

      test('deve retornar false quando login falha', () async {
        // Arrange
        when(mockAuth.signInWithPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(AuthException('Credenciais inválidas'));

        // Act
        final result = await authService.signIn(
          email: 'test@example.com',
          password: 'wrong-password',
        );

        // Assert
        expect(result, isFalse);
      });
    });

    group('signOut', () {
      test('deve fazer logout com sucesso', () async {
        // Arrange
        when(mockAuth.signOut()).thenAnswer((_) async => {});

        // Act
        await authService.signOut();

        // Assert
        verify(mockAuth.signOut()).called(1);
      });
    });

    group('getCurrentUser', () {
      test('deve retornar usuário atual quando autenticado', () {
        // Arrange
        final mockUser = User(
          id: 'user-id',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
        );
        when(mockAuth.currentUser).thenReturn(mockUser);

        // Act
        final user = authService.getCurrentUser();

        // Assert
        expect(user, equals(mockUser));
      });

      test('deve retornar null quando não autenticado', () {
        // Arrange
        when(mockAuth.currentUser).thenReturn(null);

        // Act
        final user = authService.getCurrentUser();

        // Assert
        expect(user, isNull);
      });
    });
  });
}