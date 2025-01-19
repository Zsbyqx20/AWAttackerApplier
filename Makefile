.PHONY: build test clean format proto cargo-build flutter-build

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
	mkdir -p lib/generated
	mkdir -p android/app/src/main/java/com/mobilellm/awattackerapplier/proto
	protoc --dart_out=grpc:lib/generated -Iproto proto/window_info.proto proto/accessibility.proto
	protoc --java_out=android/app/src/main/java -Iproto proto/window_info.proto proto/accessibility.proto

flutter-build: proto
	flutter build apk --release

flutter-test:
	flutter test --coverage

flutter-clean:
	flutter clean
	flutter pub get
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