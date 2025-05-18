import 'package:flutter/material.dart';
import 'package:lea_connect/Components/square_button.dart';
import 'package:lea_connect/Constants/url.dart';
import 'package:lea_connect/l10n/localizations.dart';
import 'package:open_store/open_store.dart';

class OutdatedScreen extends StatelessWidget {
  OutdatedScreen({Key? key}) :
    super(key: key);

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context);

    String getPlatformMsg() {
      if (platform == 'android')
        return translations.outdated.platform.android;
      else if (platform == 'ios')
        return translations.outdated.platform.ios;
      else
        throw new Exception("No such platform '${platform}'");
    }

    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(translations.outdated.title, textAlign: TextAlign.center, style: TextStyle(fontSize: 32)),
            Text(translations.outdated.msg, textAlign: TextAlign.center, style: TextStyle(fontSize: 20)),
            Container(
              padding: EdgeInsets.only(top: 16),
              child: Text(getPlatformMsg(), textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic))
            ),
            SizedBox(height: 20.0),
            SquareButton(
              text: translations.outdated.update,
              onPress: () => OpenStore.instance.open(
                  //appStoreId: '', // To specify when available
                  androidAppBundleId: 'fr.leassistant.lea_connect',
              )
            )
        ])
      )
    );
  }
}
