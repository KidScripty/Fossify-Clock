# Fossify Clock - Development & Testing Guide

## Building the APK

Build the debug APK from the devcontainer:

```bash
./gradlew clean assembleDebug
```

The built APK is located at:
```
build-outputs/gradle/outputs/apk/core/debug/clock-9-core-debug.apk
```

## Setting Up Wireless Debugging on Phone

1. **Enable Developer Options:**
   - Settings → About phone → tap "Build number" 7 times
   - (On some devices: Settings → System → About phone → tap "Build number")

2. **Enable Wireless Debugging:**
   - Settings → Developer options → toggle on **USB debugging**
   - Settings → Developer options → toggle on **Wireless debugging** (or "ADB over network")

3. **Note the pairing details:**
   - Open "Wireless debugging" section
   - You'll see an IP address and port (e.g., `192.168.1.166:39995`)
   - Click "Pair device with pairing code" to get a fresh pairing code

## Pairing and Connecting from Container

In the devcontainer terminal, use the IP:PORT and pairing code shown on the phone:

### 1. Pair the device:
```bash
printf "PAIRING_CODE\n" | adb pair IP_ADDRESS:PORT
```

**Example:**
```bash
printf "587537\n" | adb pair 192.168.1.166:37455
```

You should see:
```
Successfully paired to 192.168.1.166:37455 [guid=adb-...]
```

### 2. Connect to the device:
After pairing, try connecting to the pairing port first, then fall back to 5555:

```bash
adb connect IP_ADDRESS:PORT
# or default ADB port if above fails:
adb connect IP_ADDRESS:5555
```

**Example:**
```bash
adb connect 192.168.1.166:37455
# or
adb connect 192.168.1.166:5555
```

### 3. Verify the device is connected:
```bash
adb devices -l
```

You should see:
```
List of devices attached
192.168.1.166:33687    device product:e2sxeea model:SM_S926B device:e2s transport_id:1
```

## Installing the APK

Once the device is connected (shows as `device` in `adb devices -l`):

```bash
adb install -r build-outputs/gradle/outputs/apk/core/debug/clock-9-core-debug.apk
```

You should see:
```
Success
```

## Launching the App

Launch the app using the monkey event injector (most reliable):

```bash
adb shell monkey -p org.fossify.clock.debug -c android.intent.category.LAUNCHER 1
```

Or start the MainActivity explicitly:

```bash
adb shell am start -n org.fossify.clock.debug/.activities.MainActivity
```

## Monitoring Logs

### Option 1: Stream all logcat logs
```bash
adb logcat -c
adb logcat -v time
```

### Option 2: Stream only your app's logs (recommended)
Get the app's process ID and filter by it:

```bash
PID=$(adb shell pidof org.fossify.clock.debug)
adb logcat --pid=$PID -v time
```

If `--pid` is not supported, filter by package name:

```bash
adb logcat -v time | grep org.fossify.clock.debug
```

### Option 3: Save logs to a file
Start logging in the background and run the app:

```bash
adb logcat -v time > /tmp/clock-debug.log &
# Run your app and interact with it
# Kill the background process when done:
pkill -f "adb logcat"
```

### Option 4: Filter by tag
If you want logs from a specific tag (e.g., "MyTag"):

```bash
adb logcat -s MyTag:V *:S
```

## Troubleshooting

### Device disconnects or won't connect
- On the phone: disable and re-enable Wireless debugging
- Restart adb server in the container:
  ```bash
  adb kill-server
  adb start-server
  ```
- Re-pair with the new code/port shown on the phone

### "protocol fault" error during pairing
- Update platform-tools to the latest version:
  ```bash
  cd /tmp
  curl -LO https://dl.google.com/android/repository/platform-tools-latest-linux.zip
  unzip -o platform-tools-latest-linux.zip
  export PATH=/tmp/platform-tools:$PATH
  adb devices
  ```

### App won't launch or crashes immediately
- Check `adb logcat` output for stack traces
- Verify the APK was installed successfully: `adb shell pm list packages | grep org.fossify.clock.debug`
- Reinstall: `adb uninstall org.fossify.clock.debug && adb install -r build-outputs/gradle/outputs/apk/core/debug/clock-9-core-debug.apk`

### Can't see device in `adb devices -l`
- Ensure phone and container host are on the same Wi-Fi network
- Verify IP address matches between phone and connection command
- Check that Wireless debugging is **enabled** on the phone

## Quick Workflow Summary

```bash
# 1. Build APK
./gradlew clean assembleDebug

# 2. Pair (use code/port from phone)
printf "PAIRING_CODE\n" | adb pair IP:PORT

# 3. Connect
adb connect IP:PORT

# 4. Install
adb install -r build-outputs/gradle/outputs/apk/core/debug/clock-9-core-debug.apk

# 5. Launch app
adb shell monkey -p org.fossify.clock.debug -c android.intent.category.LAUNCHER 1

# 6. Monitor logs
PID=$(adb shell pidof org.fossify.clock.debug)
adb logcat --pid=$PID -v time
```

---

**App Package Name:** `org.fossify.clock.debug`  
**App Main Activity:** `.activities.MainActivity`  
**APK Location:** `build-outputs/gradle/outputs/apk/core/debug/clock-9-core-debug.apk`
