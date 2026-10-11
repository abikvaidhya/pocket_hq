# pocket_hq

<h1 align="center">
    <br>
    Pockat HQ
</h1>
<h4 align="center">
 Pocket dashboard and personal application
</h4>
<hr>

## Purpose

A simple personal companion app. Log trips, track screen time, take notes, view trip history, and track your habits.


## What it shows:

- Clean Flutter architecture using Riverpod
- Native Android feature in Kotlin + Jetpack Compose
- Communication via MethodChannel and EventChannel
- Clear separation between UI, state, and platform code


## Dependencies
 ### State management
 flutter_riverpod:<br/>
 riverpod_annotation:

 ### Local storage
 hive:<br/>
 hive_flutter:

 ### UI & charts
 fl_chart:<br/>
 flutter_staggered_grid_view:<br/>
 google_fonts:<br/>
 flutter_animate:<br/>
 iconsax:

 ### Native bridges & permissions
 local_auth:<br/>
 permission_handler: ^11.3.1

 ### usage_stats:          
 device_calendar:       <br/>
 geolocator:<br/>
 geocoding:

 ### Notifications & background
 flutter_local_notifications:<br/>
 workmanager: ^0.10.10<br/>
 timezone: ^0.9.4

 ### Utils
 intl:<br/>
 uuid:<br/>
 path_provider:<br/>
 freezed_annotation:<br/>
 json_annotation:<br/>
 collection:

 ### dev_dependencies:<br/>
 flutter_test:<br/>
   sdk: flutter<br/>
 flutter_lints: ^6.0.0<br/>
 build_runner: ^2.4.11<br/>
 riverpod_generator: ^2.4.0<br/>
 hive_generator: ^2.0.1<br/>
 freezed: ^2.5.2<br/>
 json_serializable: ^6.8.0
 

## How to use

To clone and run this application, you'll need [Git](https://git-scm.com/downloads)
and [Flutter](https://flutter.dev/docs/get-started/install) installed on your computer.

### Clone this repo

```
gh repo clone abikvaidhya/pocket_hq
```

### Navigate to the repo

```
cd vehicle_companion
```

### Install dependencies

```
flutter pub get
```

### Clean
```
flutter clean
flutter pub get
```

### Run the app
