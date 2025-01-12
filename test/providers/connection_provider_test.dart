import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:awattackerapplier/providers/connection_provider.dart';
import 'package:awattackerapplier/providers/rule_provider.dart';
import 'package:awattackerapplier/services/accessibility_service.dart';
import 'package:awattackerapplier/services/overlay_service.dart';
import 'package:awattackerapplier/models/window_event.dart';
import 'package:awattackerapplier/models/element_result.dart';
import 'package:awattackerapplier/models/overlay_result.dart';
import 'package:awattackerapplier/models/overlay_style.dart';

import 'connection_provider_test_helper.dart';

// Mock classes
class MockAccessibilityService extends Mock implements AccessibilityService {
  final _windowEventController = StreamController<WindowEvent>.broadcast();
  final _listeners = <VoidCallback>[];
  bool _isServiceRunning = false;

  @override
  Stream<WindowEvent> get windowEvents => _windowEventController.stream;

  @override
  bool get isServiceRunning => _isServiceRunning;

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void emitWindowEvent(WindowEvent event) {
    _windowEventController.add(event);
  }

  void setServiceRunning(bool value) {
    _isServiceRunning = value;
    for (final listener in _listeners) {
      listener();
    }
  }

  @override
  Future<void> stop() async {
    debugPrint('🛑 Accessibility service stopped');
    setServiceRunning(false);
    return Future<void>.value();
  }

  @override
  void dispose() {
    _windowEventController.close();
    _listeners.clear();
  }
}

class MockOverlayService extends Mock implements OverlayService {}

class MockRuleProvider extends Mock implements RuleProvider {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ConnectionProvider connectionProvider;
  late MockAccessibilityService mockAccessibilityService;
  late MockOverlayService mockOverlayService;
  late MockRuleProvider mockRuleProvider;

  setUpAll(() {
    // Register fallback values for complex types
    registerFallbackValue(
      OverlayStyle(
        text: 'Test Style',
        fontSize: 14,
        uiAutomatorCode: 'new UiSelector().text("Test Style")',
        backgroundColor: Colors.yellow.withValues(alpha: 0.5),
        textColor: Colors.blue,
        x: 0,
        y: 0,
        width: 0,
        height: 0,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        horizontalAlign: TextAlign.left,
        verticalAlign: TextAlign.center,
      ),
    );
  });

  setUp(() async {
    // Initialize mock objects first
    mockAccessibilityService = MockAccessibilityService();
    mockOverlayService = MockOverlayService();
    mockRuleProvider = MockRuleProvider();

    // Register fallback values
    registerFallbackValue(createTestWindowEvent());

    // Setup basic mock behaviors
    when(() => mockAccessibilityService.initialize()).thenAnswer((_) async {
      mockAccessibilityService.setServiceRunning(true);
    });
    when(() => mockAccessibilityService.startDetection())
        .thenAnswer((_) async => {});
    when(() => mockAccessibilityService.updateRuleMatchStatus(any()))
        .thenAnswer((_) async => {});

    // Setup overlay service mocks
    when(() => mockOverlayService.checkPermission())
        .thenAnswer((_) async => true);
    when(() => mockOverlayService.requestPermission())
        .thenAnswer((_) async => true);
    when(() => mockOverlayService.start()).thenAnswer((_) async => true);
    when(() => mockOverlayService.stop()).thenAnswer((_) async {
      debugPrint('🛑 Overlay service stopped');
      return Future<void>.value();
    });
    when(() => mockOverlayService.removeAllOverlays()).thenAnswer((_) async {
      debugPrint('🧹 All overlays removed');
      return Future<void>.value();
    });
    when(() => mockOverlayService.createOverlay(any(), any()))
        .thenAnswer((_) async => const OverlayResult(success: true));

    when(() => mockRuleProvider.rules).thenReturn([]);

    // Create test object with mocked dependencies
    connectionProvider = ConnectionProvider(
      mockRuleProvider,
      overlayService: mockOverlayService,
      accessibilityService: mockAccessibilityService,
    );
  });

  test('Initial state should be disconnected', () {
    expect(connectionProvider.isServiceRunning, false);
    expect(connectionProvider.status, ConnectionStatus.disconnected);
  });

  test('Should connect successfully when overlay permission is granted',
      () async {
    // Execute connection
    final result = await connectionProvider.checkAndConnect();

    // Verify results
    expect(result, true);
    expect(connectionProvider.isServiceRunning, true);
    expect(connectionProvider.status, ConnectionStatus.connected);

    // Verify method calls
    verify(() => mockAccessibilityService.initialize()).called(1);
    verify(() => mockAccessibilityService.startDetection()).called(1);
    verify(() => mockOverlayService.checkPermission()).called(1);
    verify(() => mockOverlayService.start()).called(1);
    verifyNever(() => mockOverlayService.requestPermission());
  });

  test(
      'Should connect successfully when overlay permission needs to be requested',
      () async {
    // Setup mock behavior for permission request flow
    when(() => mockOverlayService.checkPermission())
        .thenAnswer((_) async => false);
    when(() => mockOverlayService.requestPermission())
        .thenAnswer((_) async => true);

    // Execute connection
    final result = await connectionProvider.checkAndConnect();

    // Verify results
    expect(result, true);
    expect(connectionProvider.isServiceRunning, true);
    expect(connectionProvider.status, ConnectionStatus.connected);

    // Verify method calls
    verify(() => mockOverlayService.checkPermission()).called(1);
    verify(() => mockOverlayService.requestPermission()).called(1);
    verify(() => mockOverlayService.start()).called(1);
  });

  test('Should handle permission denial', () async {
    // Setup mock behavior
    when(() => mockOverlayService.checkPermission())
        .thenAnswer((_) async => false);
    when(() => mockOverlayService.requestPermission())
        .thenAnswer((_) async => false);

    // Execute connection
    final result = await connectionProvider.checkAndConnect();

    // Verify results
    expect(result, false);
    expect(connectionProvider.isServiceRunning, false);
    expect(connectionProvider.status, ConnectionStatus.disconnected);

    // Verify method calls
    verify(() => mockOverlayService.checkPermission()).called(1);
    verify(() => mockOverlayService.requestPermission()).called(1);
    verifyNever(() => mockOverlayService.start());
  });

  group('Window Event Tests', () {
    setUp(() async {
      // Connect the provider for window event tests
      await connectionProvider.checkAndConnect();
    });

    test('Should handle window state changed event with no matching rules',
        () async {
      // Setup
      when(() => mockRuleProvider.rules).thenReturn([]);
      when(() => mockOverlayService.removeAllOverlays())
          .thenAnswer((_) async => {});
      when(() => mockAccessibilityService.updateRuleMatchStatus(any()))
          .thenAnswer((_) async => {});

      // Emit window event
      mockAccessibilityService.emitWindowEvent(createTestWindowEvent(
        type: 'WINDOW_STATE_CHANGED',
        packageName: 'com.example.nonexistent',
        activityName: '.MainActivity',
      ));

      // Wait for event processing
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Verify
      verify(() => mockOverlayService.removeAllOverlays()).called(1);
      verify(() => mockAccessibilityService.updateRuleMatchStatus(false))
          .called(1);
    });

    test('Should handle window state changed event with matching rules',
        () async {
      // Setup test rules
      final rules = await loadTestRules();
      when(() => mockRuleProvider.rules).thenReturn(rules);

      // Setup element search results
      when(() => mockAccessibilityService.findElements(any()))
          .thenAnswer((_) async => [
                ElementResult(
                  success: true,
                  coordinates: {'x': 100, 'y': 100},
                  size: {'width': 200, 'height': 100},
                ),
              ]);
      when(() => mockAccessibilityService.updateRuleMatchStatus(any()))
          .thenAnswer((_) async => {});

      // Setup overlay creation
      when(() => mockOverlayService.createOverlay(any(), any()))
          .thenAnswer((_) async => const OverlayResult(success: true));

      // Emit window event matching the test rule
      mockAccessibilityService.emitWindowEvent(createTestWindowEvent(
        type: 'WINDOW_STATE_CHANGED',
        packageName: 'com.example.app',
        activityName: '.MainActivity',
      ));

      // Wait for event processing
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Verify
      verify(() => mockAccessibilityService.updateRuleMatchStatus(true))
          .called(1);
      verify(() => mockAccessibilityService.findElements(any())).called(1);
      verify(() => mockOverlayService.createOverlay(any(), any())).called(1);
    });

    test('Should handle content changed event with matching rules', () async {
      // Setup test rules
      final rules = await loadTestRules();
      when(() => mockRuleProvider.rules).thenReturn(rules);

      // Setup element search results
      when(() => mockAccessibilityService.findElements(any()))
          .thenAnswer((_) async => [
                ElementResult(
                  success: true,
                  coordinates: {'x': 100, 'y': 100},
                  size: {'width': 200, 'height': 100},
                ),
              ]);
      when(() => mockAccessibilityService.updateRuleMatchStatus(any()))
          .thenAnswer((_) async => {});

      // Setup overlay creation
      when(() => mockOverlayService.createOverlay(any(), any()))
          .thenAnswer((_) async => const OverlayResult(success: true));

      // Emit content changed event
      mockAccessibilityService.emitWindowEvent(createTestWindowEvent(
        type: 'CONTENT_CHANGED',
        packageName: 'com.example.app',
        activityName: '.MainActivity',
      ));

      // Wait for event processing
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Verify
      verify(() => mockAccessibilityService.updateRuleMatchStatus(true))
          .called(1);
      verify(() => mockAccessibilityService.findElements(any())).called(1);
      verify(() => mockOverlayService.createOverlay(any(), any())).called(1);
    });

    test('Should handle element search failure', () async {
      // Setup test rules
      final rules = await loadTestRules();
      when(() => mockRuleProvider.rules).thenReturn(rules);

      // Setup element search results with failure
      when(() => mockAccessibilityService.findElements(any()))
          .thenAnswer((_) async => [
                ElementResult(
                  success: false,
                ),
              ]);
      when(() => mockAccessibilityService.updateRuleMatchStatus(any()))
          .thenAnswer((_) async => {});

      // Setup overlay removal
      when(() => mockOverlayService.removeOverlay(any()))
          .thenAnswer((_) async => true);

      // Emit window event
      mockAccessibilityService.emitWindowEvent(createTestWindowEvent(
        type: 'WINDOW_STATE_CHANGED',
        packageName: 'com.example.app',
        activityName: '.MainActivity',
      ));

      // Wait for all async operations to complete
      await Future<void>.delayed(const Duration(milliseconds: 500));

      // Verify
      verify(() => mockAccessibilityService.findElements(any())).called(1);
      verify(() => mockAccessibilityService.updateRuleMatchStatus(true))
          .called(1);

      // Note: In the actual implementation, if element search fails,
      // we might not need to remove the overlay if it wasn't created in the first place
      verifyNever(() => mockOverlayService.createOverlay(any(), any()));
    });

    test('Should handle invalid element coordinates', () async {
      // Setup test rules
      final rules = await loadTestRules();
      when(() => mockRuleProvider.rules).thenReturn(rules);

      // Setup element search results with invalid coordinates
      when(() => mockAccessibilityService.findElements(any()))
          .thenAnswer((_) async => [
                ElementResult(
                  success: true,
                  coordinates: {'x': -100, 'y': -100}, // Invalid coordinates
                  size: {'width': 200, 'height': 100},
                ),
              ]);
      when(() => mockAccessibilityService.updateRuleMatchStatus(any()))
          .thenAnswer((_) async => {});

      // Setup overlay removal
      when(() => mockOverlayService.removeOverlay(any()))
          .thenAnswer((_) async => true);

      // Emit window event
      mockAccessibilityService.emitWindowEvent(createTestWindowEvent(
        type: 'WINDOW_STATE_CHANGED',
        packageName: 'com.example.app',
        activityName: '.MainActivity',
      ));

      // Wait for event processing
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Verify
      verify(() => mockAccessibilityService.findElements(any())).called(1);
      verify(() => mockOverlayService.removeOverlay(any())).called(1);
    });

    test('Should handle multiple overlay styles per rule', () async {
      // Setup test rules with multiple styles
      final rules = await loadTestRules();
      when(() => mockRuleProvider.rules).thenReturn(rules);

      // Setup element search results for multiple elements
      when(() => mockAccessibilityService.findElements(any()))
          .thenAnswer((_) async => [
                ElementResult(
                  success: true,
                  coordinates: {'x': 100, 'y': 100},
                  size: {'width': 200, 'height': 100},
                ),
                ElementResult(
                  success: true,
                  coordinates: {'x': 300, 'y': 300},
                  size: {'width': 150, 'height': 50},
                ),
              ]);
      when(() => mockAccessibilityService.updateRuleMatchStatus(any()))
          .thenAnswer((_) async => {});

      // Setup overlay creation
      when(() => mockOverlayService.createOverlay(any(), any()))
          .thenAnswer((_) async => const OverlayResult(success: true));

      // Emit window event
      mockAccessibilityService.emitWindowEvent(createTestWindowEvent(
        type: 'WINDOW_STATE_CHANGED',
        packageName: 'com.example.app',
        activityName: '.MainActivity',
      ));

      await Future<void>.delayed(const Duration(milliseconds: 500));

      // Verify overlays are created for all styles
      verify(() => mockOverlayService.createOverlay(any(), any())).called(2);
      verify(() => mockAccessibilityService.findElements(any())).called(1);
      verify(() => mockAccessibilityService.updateRuleMatchStatus(true))
          .called(1);
    });
  });

  group('Overlay Cache Tests', () {
    setUp(() async {
      // Connect the provider for cache tests
      await connectionProvider.checkAndConnect();
    });

    test('Should not recreate overlay when position unchanged', () async {
      // Setup test rules
      final rules = await loadTestRules();
      when(() => mockRuleProvider.rules).thenReturn(rules);

      // Setup element search results with same position
      final searchResult = ElementResult(
        success: true,
        coordinates: {'x': 100, 'y': 100},
        size: {'width': 200, 'height': 100},
      );
      when(() => mockAccessibilityService.findElements(any()))
          .thenAnswer((_) async => [searchResult]);
      when(() => mockAccessibilityService.updateRuleMatchStatus(any()))
          .thenAnswer((_) async => {});

      // Setup overlay creation
      when(() => mockOverlayService.createOverlay(any(), any()))
          .thenAnswer((_) async => const OverlayResult(success: true));

      // First window event
      mockAccessibilityService.emitWindowEvent(createTestWindowEvent(
        type: 'WINDOW_STATE_CHANGED',
        packageName: 'com.example.app',
        activityName: '.MainActivity',
      ));

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Second window event with same position
      mockAccessibilityService.emitWindowEvent(createTestWindowEvent(
        type: 'WINDOW_STATE_CHANGED',
        packageName: 'com.example.app',
        activityName: '.MainActivity',
      ));

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Verify overlay is created only once
      verify(() => mockOverlayService.createOverlay(any(), any())).called(1);
    });

    test('Should update overlay when position changed', () async {
      // Setup test rules
      final rules = await loadTestRules();
      when(() => mockRuleProvider.rules).thenReturn(rules);

      // Setup element search results with different positions
      var searchCount = 0;
      when(() => mockAccessibilityService.findElements(any()))
          .thenAnswer((_) async {
        searchCount++;
        return [
          ElementResult(
            success: true,
            coordinates: {
              'x': searchCount == 1 ? 100 : 200,
              'y': searchCount == 1 ? 100 : 200
            },
            size: {'width': 200, 'height': 100},
          )
        ];
      });
      when(() => mockAccessibilityService.updateRuleMatchStatus(any()))
          .thenAnswer((_) async => {});

      // Setup overlay creation
      when(() => mockOverlayService.createOverlay(any(), any()))
          .thenAnswer((_) async => const OverlayResult(success: true));

      // First window event
      mockAccessibilityService.emitWindowEvent(createTestWindowEvent(
        type: 'WINDOW_STATE_CHANGED',
        packageName: 'com.example.app',
        activityName: '.MainActivity',
      ));

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Second window event with different position
      mockAccessibilityService.emitWindowEvent(createTestWindowEvent(
        type: 'WINDOW_STATE_CHANGED',
        packageName: 'com.example.app',
        activityName: '.MainActivity',
      ));

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Verify overlay is created twice
      verify(() => mockOverlayService.createOverlay(any(), any())).called(2);
    });

    test('Should clear cache when no matching rules', () async {
      // Setup test rules
      final rules = await loadTestRules();
      when(() => mockRuleProvider.rules).thenReturn(rules);

      // Setup element search results
      when(() => mockAccessibilityService.findElements(any()))
          .thenAnswer((_) async => [
                ElementResult(
                  success: true,
                  coordinates: {'x': 100, 'y': 100},
                  size: {'width': 200, 'height': 100},
                )
              ]);
      when(() => mockAccessibilityService.updateRuleMatchStatus(any()))
          .thenAnswer((_) async => {});

      // Setup overlay creation and removal
      when(() => mockOverlayService.createOverlay(any(), any()))
          .thenAnswer((_) async => const OverlayResult(success: true));
      when(() => mockOverlayService.removeAllOverlays())
          .thenAnswer((_) async => {});

      // First window event with matching rule
      mockAccessibilityService.emitWindowEvent(createTestWindowEvent(
        type: 'WINDOW_STATE_CHANGED',
        packageName: 'com.example.app',
        activityName: '.MainActivity',
      ));

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Second window event with no matching rules
      when(() => mockRuleProvider.rules).thenReturn([]);
      mockAccessibilityService.emitWindowEvent(createTestWindowEvent(
        type: 'WINDOW_STATE_CHANGED',
        packageName: 'com.example.nonexistent',
        activityName: '.MainActivity',
      ));

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Third window event with matching rule again
      when(() => mockRuleProvider.rules).thenReturn(rules);
      mockAccessibilityService.emitWindowEvent(createTestWindowEvent(
        type: 'WINDOW_STATE_CHANGED',
        packageName: 'com.example.app',
        activityName: '.MainActivity',
      ));

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Verify
      verify(() => mockOverlayService.createOverlay(any(), any())).called(2);
      verify(() => mockOverlayService.removeAllOverlays()).called(1);
    });
  });

  group('Error Recovery Tests', () {
    setUp(() async {
      // Connect the provider for error recovery tests
      await connectionProvider.checkAndConnect();
    });

    test(
        'Should handle both WINDOW_STATE_CHANGED and CONTENT_CHANGED events similarly',
        () async {
      // Setup test rules
      final rules = await loadTestRules();
      when(() => mockRuleProvider.rules).thenReturn(rules);

      // Setup element search results with different positions for each call
      var searchCount = 0;
      when(() => mockAccessibilityService.findElements(any()))
          .thenAnswer((_) async {
        searchCount++;
        return [
          ElementResult(
            success: true,
            coordinates: {
              'x': searchCount == 1 ? 100 : 200,
              'y': searchCount == 1 ? 100 : 200,
            },
            size: {'width': 200, 'height': 100},
          ),
        ];
      });

      when(() => mockAccessibilityService.updateRuleMatchStatus(any()))
          .thenAnswer((_) async => {});
      when(() => mockOverlayService.createOverlay(any(), any()))
          .thenAnswer((_) async => const OverlayResult(success: true));

      // Test WINDOW_STATE_CHANGED event
      mockAccessibilityService.emitWindowEvent(createTestWindowEvent(
        type: 'WINDOW_STATE_CHANGED',
        packageName: 'com.example.app',
        activityName: '.MainActivity',
      ));

      await Future<void>.delayed(const Duration(milliseconds: 500));

      // Test CONTENT_CHANGED event
      mockAccessibilityService.emitWindowEvent(createTestWindowEvent(
        type: 'CONTENT_CHANGED',
        packageName: 'com.example.app',
        activityName: '.MainActivity',
      ));

      await Future<void>.delayed(const Duration(milliseconds: 500));

      // Verify both events are handled the same way
      verify(() => mockOverlayService.createOverlay(any(), any())).called(2);
      verify(() => mockAccessibilityService.findElements(any())).called(2);
      verify(() => mockAccessibilityService.updateRuleMatchStatus(true))
          .called(2);
    });

    test('Should handle overlay creation failure gracefully', () async {
      // Setup test rules
      final rules = await loadTestRules();
      when(() => mockRuleProvider.rules).thenReturn(rules);
      when(() => mockAccessibilityService.findElements(any()))
          .thenAnswer((_) async => [
                ElementResult(
                  success: true,
                  coordinates: {'x': 100, 'y': 100},
                  size: {'width': 200, 'height': 100},
                ),
              ]);

      // Setup overlay creation to fail
      when(() => mockOverlayService.createOverlay(any(), any())).thenAnswer(
          (_) async => const OverlayResult(
              success: false, error: 'Failed to create overlay'));

      // Emit window event
      mockAccessibilityService.emitWindowEvent(createTestWindowEvent(
        type: 'WINDOW_STATE_CHANGED',
        packageName: 'com.example.app',
        activityName: '.MainActivity',
      ));

      await Future<void>.delayed(const Duration(milliseconds: 500));

      // Verify service continues running despite overlay creation failure
      expect(connectionProvider.status, ConnectionStatus.connected);
      expect(connectionProvider.isServiceRunning, true);
      verify(() => mockOverlayService.createOverlay(any(), any())).called(1);
    });
  });
}
