.PHONY: build test clean format

build:
	flutter build apk --release

test:
	flutter test --coverage

clean:
	flutter clean
	flutter pub get
	flutter gen-l10n

format:
	dart format lib/
	dart fix --apply
	dart analyze --fatal-infos
	dart run import_sorter:main