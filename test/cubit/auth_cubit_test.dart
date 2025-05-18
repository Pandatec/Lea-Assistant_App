import 'package:bloc_test/bloc_test.dart';
import 'package:either_dart/either.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lea_connect/Data/Models/User.dart';
import 'package:lea_connect/Data/Repository/auth_repository.dart';
import 'package:lea_connect/Data/Repository/user_session.dart';
import 'package:lea_connect/Screens/auth/Login/cubit/login_cubit.dart';
import 'package:lea_connect/Screens/auth/Signup/cubit/signup_cubit.dart';
import 'package:lea_connect/Screens/auth/Welcome/cubit/welcome_cubit.dart';
import 'package:lea_connect/Screens/auth/cubit/auth_cubit.dart';
import 'package:lea_connect/Data/Models/Auth.dart';
import 'package:lea_connect/Utilities/api_client.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import './auth_cubit_test.mocks.dart';

@GenerateMocks([AuthStorage, UserSession, UserRepository])
void main() {
  group('Authenticate Tests -', () {
    late AuthenticateCubit authenticateCubit;

    late AuthStorage authStorage;
    late UserRepository userRepo;

    setUp(() {
      authenticateCubit = AuthenticateCubit();
      authStorage = MockAuthStorage();
      userRepo = MockUserRepository();
    });

    test("State should be AppStart", () {
      expect(authenticateCubit.state.runtimeType, AppStart);
    });

    final csettings = Settings(id: '0', darkModeIsDefault: false, darkMode: false, lang: 'fr', dnd: false,
      notifSafeZoneTracking: false, notifOfflinePatient: false, notifNewLogin: false, notifSettingModified: false);
    final cuser = User(id: '0', firstName: "U", lastName: "N", phone: "0", email: "somemail@bigcorp.biz", active: true, patients: [], virtual_patients_ids: [], settings: csettings);

    blocTest("Try fetch valid token",
      build: () => authenticateCubit,
      act: (AuthenticateCubit c) async => {
        when(authStorage.fetchAuth())
          .thenAnswer((_) async => Auth("somemail@bigcorp.biz", "123")),
        when(userRepo.getUser("123"))
          .thenAnswer((_) async => Right({
            "user": {
              "id": cuser.id, "first_name": cuser.firstName, "last_name": cuser.lastName, "phone": cuser.phone, "email": cuser.email, "active": true,
              "patients" : cuser.patients, "virtual_patients_ids": cuser.virtual_patients_ids,
              "settings": {
                "id": csettings.id, "dark_mode": csettings.darkMode, "lang": csettings.lang, "dnd": csettings.dnd,
                "notif_safe_zone_tracking": csettings.notifSafeZoneTracking, "notif_offline_patient": csettings.notifSafeZoneTracking,
                "notif_new_login": csettings.notifNewLogin, "notif_setting_modified": csettings.notifSettingModified
              }
            }
          })),
        await c.tryLoginFromPersisted(storage: authStorage, repo: userRepo)
      },
      expect: () => [Authenticated("somemail@bigcorp.biz", "123", cuser)]
    );

    blocTest("Try fetch invalid token",
      build: () => authenticateCubit,
      act: (AuthenticateCubit c) async => {
        when(authStorage.fetchAuth())
          .thenAnswer((_) async => null),
        await c.tryLoginFromPersisted(storage: authStorage)
      },
      expect: () => [Unauthenticated()]
    );

    blocTest("Try fetch outdated token",
      build: () => authenticateCubit,
      act: (AuthenticateCubit c) async => {
        when(authStorage.fetchAuth())
          .thenAnswer((_) async => Auth("somemail@bigcorp.biz", "123")),
        when(userRepo.getUser("123"))
          .thenAnswer((_) async => Left(ErrorDesc(403, 'SOME_MSG'))),
        await c.tryLoginFromPersisted(storage: authStorage, repo: userRepo)
      },
      expect: () => [Unauthenticated()]
    );

    blocTest("Try logout",
      build: () => authenticateCubit,
      act: (AuthenticateCubit c) => {
        when(authStorage.deleteToken())
          .thenAnswer((_) async => null),
        c.logout(storage: authStorage)
      },
      expect: () => [Unauthenticated()]
    );
  });

  group("Login Cubit tests", () {
    late UserRepository userRepository;
    late AuthenticateCubit authenticateCubit;
    late WelcomeCubit welcomeCubit;
    late LoginCubit loginCubit;

    setUp(() {
      userRepository = MockUserRepository();
      authenticateCubit = AuthenticateCubit();
      welcomeCubit = WelcomeCubit(authenticateCubit: authenticateCubit);
      loginCubit = LoginCubit(welcomeCubit: welcomeCubit);
    });
    test("State should be LoginInitial", () {
      expect(loginCubit.state.runtimeType, LoginInitial);
    });

    test("State should be WelcomeInitial", () {
      expect(welcomeCubit.state.runtimeType, WelcomeInitial);
    });

    blocTest("SignIn fail should show Loading then initial",
      build: () => loginCubit,
      act: (LoginCubit c) async => {
        when(userRepository.signIn("email", "password"))
          .thenAnswer((_) async => Left(ErrorDesc(403, 'SOME_MSG'))),
        await c.trySignIn("email", "password", true, repo: userRepository)
      },
      expect: () => [LoginLoading(), LoginInitial(errorMessage: 'SOME_MSG')]
    );

    blocTest("SignIn success should show loading",
      build: () => loginCubit,
      act: (LoginCubit c) async => {
        when(userRepository.signIn("email", "password"))
          .thenAnswer((_) async => Right({
            'access_token': 'sample_token'
          })),
        await c.trySignIn("email", "password", false, repo: userRepository)
      },
      expect: () => [LoginLoading()]
    );
  });

  group("Signup Cubit tests", () {
    late UserRepository userRepository;
    late AuthenticateCubit authenticateCubit;
    late WelcomeCubit welcomeCubit;
    late SignupCubit signupCubit;

    setUp(() {
      userRepository = MockUserRepository();
      authenticateCubit = AuthenticateCubit();
      welcomeCubit = WelcomeCubit(authenticateCubit: authenticateCubit);
      signupCubit = SignupCubit(welcomeCubit: welcomeCubit);
    });
    test("State should be SignupInitial", () {
      expect(signupCubit.state.runtimeType, SignupInitial);
    });

    blocTest("SignUp fail should show Loading then initial",
      build: () => signupCubit,
      act: (SignupCubit c) async => {
        when(userRepository.signUp("email", "password", "phone", "firstName", "lastName"))
          .thenAnswer((_) async => Left(ErrorDesc(403, 'SOME_MSG'))),
        await c.trySignUp("email", "password", "phone", "firstName", "lastName", repo: userRepository)
      },
      expect: () => [
        SignupLoading(),
        SignupInitial(email: "email", errorMessage: 'SOME_MSG')
      ]
    );

    blocTest("SignUp success should show loading",
      build: () => signupCubit,
      act: (SignupCubit c) async => {
        when(userRepository.signUp("email", "password", "phone", "firstName", "lastName"))
          .thenAnswer((_) async => Right({})),
        await c.trySignUp("email", "password", "phone", "firstName", "lastName", repo: userRepository)
      },
      expect: () => [
        SignupLoading()
      ]
    );
  });
}