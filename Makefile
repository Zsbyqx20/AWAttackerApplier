.PHONY: build test clean format proto cargo-build flutter-build

PROTOC_VERSION ?= 34.0
PROTOC_PLUGIN_VERSION ?= 25.0.0
NO_PROXY_HOSTS ?= 127.0.0.1,localhost
DART ?= /Users/zachary/flutter/bin/cache/dart-sdk/bin/dart
DART_PROTOC_PLUGIN ?= tool/protoc-gen-dart-local

# Rust/Cargo related targets
cargo-build:
	cargo build --release

cargo-test:
	cargo test

cargo-clean:
	cargo clean
	rm -rf target/

# Flutter related targets
proto:
	@echo "Using protoc $(PROTOC_VERSION) with protoc_plugin $(PROTOC_PLUGIN_VERSION)"
	mkdir -p lib/generated
	mkdir -p android/app/src/main/java/com/mobilellm/awattackerapplier/proto
	protoc --plugin=protoc-gen-dart=$(DART_PROTOC_PLUGIN) --dart_out=grpc:lib/generated -Iproto proto/window_info.proto proto/accessibility.proto
	protoc --java_out=android/app/src/main/java -Iproto proto/window_info.proto proto/accessibility.proto

flutter-build: proto
	env -u http_proxy -u https_proxy -u all_proxy -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY \
		NO_PROXY=$(NO_PROXY_HOSTS) no_proxy=$(NO_PROXY_HOSTS) \
		flutter build apk --release

flutter-test:
	env -u http_proxy -u https_proxy -u all_proxy -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY \
		NO_PROXY=$(NO_PROXY_HOSTS) no_proxy=$(NO_PROXY_HOSTS) \
		flutter test --coverage

flutter-clean:
	env -u http_proxy -u https_proxy -u all_proxy -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY \
		NO_PROXY=$(NO_PROXY_HOSTS) no_proxy=$(NO_PROXY_HOSTS) \
		flutter clean
	env -u http_proxy -u https_proxy -u all_proxy -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY \
		NO_PROXY=$(NO_PROXY_HOSTS) no_proxy=$(NO_PROXY_HOSTS) \
		flutter pub get
	env -u http_proxy -u https_proxy -u all_proxy -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY \
		NO_PROXY=$(NO_PROXY_HOSTS) no_proxy=$(NO_PROXY_HOSTS) \
		flutter gen-l10n
	rm -rf lib/generated/*
	rm -rf android/app/src/main/java/com/mobilellm/awattackerapplier/proto/*

format:
	dart format lib/
	dart fix --apply
	dart analyze --fatal-infos
	dart run import_sorter:main
	cargo fmt

# Combined targets
build: cargo-build flutter-build

test: cargo-test flutter-test

clean: cargo-clean flutter-clean
