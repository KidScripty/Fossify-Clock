ARG VARIANT=ubuntu-24.04
FROM mcr.microsoft.com/devcontainers/base:${VARIANT}

# Install Java 17, Android SDK tools and helpers
ARG ANDROID_SDK_ROOT=/opt/android-sdk
ENV ANDROID_SDK_ROOT=${ANDROID_SDK_ROOT}
ENV PATH=${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${PATH}

# Avoid prompts
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    git \
    openjdk-17-jdk \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create SDK dirs
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools ${ANDROID_SDK_ROOT}/platform-tools ${ANDROID_SDK_ROOT}/platforms ${ANDROID_SDK_ROOT}/build-tools

# Install Android command line tools
RUN cd /tmp \
    && wget -q https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip -O cmdline-tools.zip \
    && unzip -q cmdline-tools.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools \
    && mv ${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/latest \
    && rm cmdline-tools.zip

# Install platform-tools, build-tools and platform 36
RUN yes | sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --licenses || true
RUN sdkmanager --sdk_root=${ANDROID_SDK_ROOT} "platform-tools" "platforms;android-36" "build-tools;36.0.0" || true

# Set JAVA_HOME
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# Set up a non-root user (vscode user exists in base images)
USER vscode
WORKDIR /workspace

# Make Gradle wrapper executable
RUN if [ -f ./gradlew ]; then chmod +x ./gradlew; fi
