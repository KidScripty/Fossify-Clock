#!/usr/bin/env bash
# Ensure script is runnable on Unix: git should preserve the executable bit.
# If the executable bit is missing after checkout, run: chmod +x .devcontainer/post-create.sh
set -e

# Ensure sdkmanager is available
export ANDROID_SDK_ROOT=${ANDROID_SDK_ROOT:-/home/vscode/android-sdk}
export PATH=${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${PATH}

# Ensure a local, writable SDK directory exists and install required components there
mkdir -p ${ANDROID_SDK_ROOT}
sudo chown -R vscode:vscode ${ANDROID_SDK_ROOT} || true

# Accept licenses and ensure build-tools and platforms are present in the local SDK
yes | sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --licenses || true
# Install both 35 and 36 build-tools to satisfy potential tool requests
sdkmanager --sdk_root=${ANDROID_SDK_ROOT} "platform-tools" "platforms;android-36" "build-tools;36.0.0" "build-tools;35.0.0" || true

# Print versions
java -version || true
sdkmanager --version || true
./gradlew --version || true

# Ensure the build outputs directory exists inside the workspace, is writable, and empty so Gradle can clean it
# Remove and recreate the directory itself (clears immutable flags, root-owned dirs, etc.)
if [ -d /workspace/build-outputs ]; then
	sudo chattr -i -R /workspace/build-outputs || true
	# Attempt to remove contents but avoid removing the mountpoint itself if it's busy
	sudo rm -rf /workspace/build-outputs/* || true
fi
sudo mkdir -p /workspace/build-outputs
sudo chown -R vscode:vscode /workspace/build-outputs || true
sudo chmod -R 0777 /workspace/build-outputs || true

# Use a subdirectory for Gradle build outputs so Gradle won't try to delete
# the workspace mountpoint itself (which can be "Device or resource busy").
GRADLE_WORKSPACE_BUILD_DIR=/workspace/build-outputs/gradle
sudo mkdir -p "${GRADLE_WORKSPACE_BUILD_DIR}"
sudo chown -R vscode:vscode "${GRADLE_WORKSPACE_BUILD_DIR}" || true
sudo chmod -R 0777 "${GRADLE_WORKSPACE_BUILD_DIR}" || true

# Redirect build directory globally using GRADLE_PROJECT_BUILD_DIR (safe init script)
mkdir -p /home/vscode/.gradle
cat > /home/vscode/.gradle/init.gradle <<'INIT'
// Robust init.gradle: choose buildDir from env, else prefer a subdir under
// /workspace/build-outputs to avoid deleting a mount root. Fallback to
// ~/.gradle/build-outputs when necessary.

def chooseBuildDir() {
	def env = System.getenv('GRADLE_PROJECT_BUILD_DIR')
	if (env) return file(env)

	def candidate = file('/workspace/build-outputs/gradle')
	try {
		if (!candidate.exists()) candidate.mkdirs()
		def testFile = new File(candidate, '.gradle_write_test_' + System.currentTimeMillis())
		testFile.createNewFile()
		testFile.delete()
		return candidate
	} catch (Exception e) {
		def userFallback = new File(System.getProperty('user.home'), '.gradle/build-outputs')
		if (!userFallback.exists()) userFallback.mkdirs()
		return userFallback
	}
}

def bd = chooseBuildDir()

gradle.projectsLoaded {
	rootProject.allprojects.each { proj ->
		proj.buildDir = bd
	}
}
INIT

# Ensure gradlew is executable
chmod +x ./gradlew

# Create local.properties so Gradle uses the local SDK path
echo "sdk.dir=${ANDROID_SDK_ROOT}" > local.properties

echo "Dev container setup complete. You can build with: ./gradlew clean assembleDebug"
