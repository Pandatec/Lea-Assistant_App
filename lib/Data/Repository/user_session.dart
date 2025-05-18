import 'package:lea_connect/Data/Models/User.dart';
import 'package:lea_connect/Utilities/api_client.dart';

import '../../Constants/url.dart';

class UserRepository {
  const UserRepository();

  Future<APIResponse> getBuildAppAndroid() => wsClient.request(null, 'GET', '/build/app_android', {
    "reported_version": version
  }, {});
  Future<APIResponse> getBuildAppIOS() => wsClient.request(null, 'GET', '/build/app_ios', {
    "reported_version": version
  }, {});
  Future<APIResponse> getBuildApp() {
    if (platform == 'android')
      return getBuildAppAndroid();
    else if (platform == 'ios')
      return getBuildAppIOS();
    else
      throw new Exception("No such platform '${platform}'");
  }

  Future<bool> isBuildUpToDate() async {
    if (platform == 'unknown')
      return true;
    else {
      final r = await getBuildApp();
      if (r.isLeft)
        return false;
      else
        return r.right['is_uptodate'];
    }
  }

  Future<APIResponse> signIn(String email, String password) => wsClient.request(null, 'POST', '/v1/auth/login', {}, {
    'email': email,
    'password': password
  });

  Future<APIResponse> signUp(String email, String password,
    String phone, String firstName, String lastName) => wsClient.request(null, 'POST', '/v1/auth/register', {}, {
      'email': email,
      'password': password,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone
    });

  Future<APIResponse> sendResetMail(String email) => wsClient.request(null, 'POST', '/v1//auth/sendResetMail', {}, {
    'email': email
  });

  Future<APIResponse> getUser(String token) => wsClient.request(token, 'GET', '/v1/user/get', {}, {});
}

class UserSession {
  final String token;
  final User user;

  UserSession(this.token, this.user);

  Future<APIResponse> resendVerifInstr() => wsClient.request(token, 'POST', '/v1/auth/resend-verif-instr', {}, {});

  Future<APIResponse> getUser() async {
    return UserRepository().getUser(token);
  }

  Future<APIResponse> deleteUser(bool includePatients) => wsClient.request(token, 'DELETE', '/v1/user/delete', {
    'include_patients': includePatients.toString()
  }, {});

  Future<APIResponse> pairDevice(String deviceToken) => wsClient.request(token, 'PATCH', '/v1/user/pair', {}, {
    'temp_token': deviceToken
  });

  Future<APIResponse> patchSettingsLang(String value) => wsClient.request(token, 'PATCH', '/v1/user/settings/edit', {}, {
    'lang': value
  });

  Future<APIResponse> patchSettingsBool(String key, bool value) => wsClient.request(token, 'PATCH', '/v1/user/settings/edit', {}, {
    key: value
  });

  Future<APIResponse> patchSettingsDnd(bool value) => patchSettingsBool('dnd', value);

  Future<APIResponse> patchSettingsDarkMode(dynamic value) => wsClient.request(token, 'PATCH', '/v1/user/settings/edit', {
    'dark_mode': value,
  }, {});

  Future<APIResponse> patchSettingsNotifSafeZoneTracking(bool value) => patchSettingsBool('notif_safe_zone_tracking', value);
  Future<APIResponse> patchSettingsNotifOfflinePatient(bool value) => patchSettingsBool('notif_offline_patient', value);
  Future<APIResponse> patchSettingsNotifNewLogin(bool value) => patchSettingsBool('notif_new_login', value);
  Future<APIResponse> patchSettingsNotifSettingModified(bool value) => patchSettingsBool('notif_setting_modified', value);

  Future<APIResponse> getUnreadNotificationCount() => wsClient.request(token, 'GET', '/v1/user/notifs/unread_count', {}, {});

  Future<APIResponse> getNotifications(int page) => wsClient.request(token, 'GET', '/v1/user/notifs', {
    "page": page.toString()
  }, {});

  Future<APIResponse> patchPatient(String patientId, String nickName, String firstName,
    String lastName, String birthDate) => wsClient.request(token, 'PATCH', '/v1/patient/edit', {
      'patientId': patientId,
    }, {
      'nick_name': nickName,
      'first_name': firstName,
      'last_name': lastName,
      'birth_date': birthDate,
    });

  Future<APIResponse> createVirtualPatient() => wsClient.request(token, 'POST', '/v1/patient/virtual', {}, {});
  Future<APIResponse> deleteVirtualPatient() => wsClient.request(token, 'DELETE', '/v1/patient/virtual', {}, {});
}
