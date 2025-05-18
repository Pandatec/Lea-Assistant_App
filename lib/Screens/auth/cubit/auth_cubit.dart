import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lea_connect/Data/Models/Auth.dart';
import 'package:lea_connect/Data/Models/User.dart';
import 'package:lea_connect/Data/Repository/auth_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:lea_connect/Data/Repository/user_session.dart';
import 'package:lea_connect/Utilities/api_client.dart';

part 'auth_state.dart';

class AuthenticateCubit extends Cubit<AuthenticateState> {
  AuthenticateCubit() :
    super(AppStart());

  Future<void> resume({storage = const AuthStorage(), repo = const UserRepository()}) async {
    if (!await repo.isBuildUpToDate())
      emit(Outdated());
    else
      tryLoginFromPersisted(storage: storage, repo: repo);
  }

  Future<void> tryLoginFromPersisted({storage = const AuthStorage(), repo = const UserRepository()}) async {
    final auth = await storage.fetchAuth();
    if (auth == null)
      emit(Unauthenticated());
    else
      await tryLoginFromAuth(auth, false, repo: repo);
  }

  Future<void> tryLoginFromAuth(Auth auth, bool persistIfSuccess, {repo = const UserRepository()}) async {
    final value = await repo.getUser(auth.token);
    either(null, value)((v) async {
      if (persistIfSuccess)
        await authStorage.persistAuth(auth);
      wsRepository.login(auth);
      final user = User.fromJson(v['user']);
      if (user.isVerified())
        emit(Authenticated(auth.email, auth.token, user));
      else
        emit(Unverified(auth.email, auth.token, user));
    }, (e) {
      emit(Unauthenticated());
    });
  }

  void persistAuth(Auth auth) {
    authStorage.persistAuth(auth);
  }

  void logout({storage = const AuthStorage()}) {
    storage.deleteToken();
    wsRepository.logout();
    emit(Unauthenticated());
  }
}
