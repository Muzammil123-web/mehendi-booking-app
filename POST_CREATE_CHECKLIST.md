# ⚠️ Run this checklist EVERY TIME after `flutter create .`

`flutter create .` regenerates the `android` and `ios` folders from scratch,
wiping out ALL of the manual edits below. If you ever have to run it again
(project deleted, folder corrupted, etc.), do these 4 things immediately
after, in order, before building:

## 1. Fix compileSdk for the geocoding plugin
Open `android\build.gradle.kts`, replace its ENTIRE content with:

```kotlin
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)
subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    afterEvaluate {
        extensions.findByName("android")?.let { ext ->
            if (ext is com.android.build.gradle.BaseExtension) {
                ext.compileSdkVersion(36)
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
```

## 2. Add permissions for notifications + location
Open `android\app\src\main\AndroidManifest.xml`. Find the line that says
`<application` and add these 3 lines directly ABOVE it:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

## 3. (Optional) Change the app's display name
In the same `AndroidManifest.xml`, find:
```xml
android:label="mehendi_booking_app"
```
Change the text between the quotes to whatever you want customers to see
under the icon on their home screen, e.g.:
```xml
android:label="Mehendi Studio"
```

## 4. Reconnect Firebase
```
flutterfire configure
```
Select project **mehendi-studio-934ec**, select **android**. This restores
`google-services.json` and `firebase_options.dart`.

---

## To change the app ICON (not just the name)
This one is NOT wiped by `flutter create .` once set up — it's a one-time job:
1. Get a square PNG (1024x1024 recommended) of your logo
2. In your project, create a folder `assets/icon/` and put the image in there
   as `app_icon.png`
3. Run:
   ```
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```
4. This regenerates all the icon files automatically. Then rebuild the APK
   as normal.
