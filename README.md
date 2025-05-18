# Lea App

<!-- [![Build](https://github.com/Lea-Voc/Lea-App/actions/workflows/build.yml/badge.svg)](https://github.com/Lea-Voc/Lea-App/actions/workflows/build.yml) -->

Lea phone application for the family and/or medical staff made in Flutter

## Local development

**By default, the app will connect to `staging` server (`dev.api.leassistant.fr`).**  

### Connecting to local server
To connect to a local development server in plain HTTP, you must provide `--dart-define LEA_LOCAL_HOST={local_host_opt_port}` to your `flutter run` command.  
If you are using Microsoft Visual Studio Code®, you can achieve that by adding that option in your `launch.json` as follows:  
```js
{
	// Use IntelliSense to learn about possible attributes.
	// Hover to view descriptions of existing attributes.
	// For more information, visit: https://go.microsoft.com/fwlink/?linkid=830387
	"version": "0.2.0",
	"configurations": [
		{
			"name": "Lea-App",
			"request": "launch",
			"type": "dart",
			// This argument is the one providing the host address
			"toolArgs": [
				"--dart-define",
				"LEA_LOCAL_HOST={local_host_opt_port}"
			]
		},
		{
			"name": "Lea-App (profile mode)",
			"request": "launch",
			"type": "dart",
			"flutterMode": "profile"
		}
	]
}
```

## Running tests, obtaining coverage

Make sure you have GNU `lcov` installed on your system.  
Run the bash script `gencoverage.sh` from the root of the package.  
After success, a new directory named `coverage` should appear at the root. An HTML report `index.html` is present with all the relevant data.
