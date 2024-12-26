import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/rule.dart';
import '../models/window_event.dart';
import 'connection_service.dart';
import 'storage_service.dart';

class RuleMatchingService {
  // 单例实现
  static final RuleMatchingService _instance = RuleMatchingService._internal();
  factory RuleMatchingService() => _instance;
  RuleMatchingService._internal() {
    _initializeService();
  }

  late final ConnectionService _connectionService;
  final StorageService _storageService = StorageService();
  StreamSubscription? _windowEventSubscription;
  StreamSubscription? _serviceStatusSubscription;

  // 规则列表
  final List<Rule> _rules = [];
  bool _isInitialized = false;

  // 规则变化通知
  final _rulesController = StreamController<List<Rule>>.broadcast();
  Stream<List<Rule>> get rulesStream => _rulesController.stream;
  List<Rule> get rules => List.unmodifiable(_rules);

  void _initializeService() {
    _connectionService = ConnectionService();
    _setupConnectionListeners();
  }

  void _setupConnectionListeners() {
    _serviceStatusSubscription =
        _connectionService.serviceStatus.listen((running) {
      if (running) {
        if (kDebugMode) {
          print('RuleMatchingService: Connection service is running');
        }
        _startWindowEventListener();
      } else {
        if (kDebugMode) {
          print('RuleMatchingService: Connection service stopped');
        }
        _stopWindowEventListener();
      }
    });
  }

  /// 启动服务
  Future<void> start() async {
    if (_isInitialized) return;
    _isInitialized = true;

    if (kDebugMode) {
      print('RuleMatchingService: Starting service');
    }

    // 加载规则
    await _loadRules();

    // 如果连接服务已经在运行，立即启动监听
    if (_connectionService.isServiceRunning) {
      _startWindowEventListener();
    }
  }

  /// 从存储服务加载规则
  Future<void> _loadRules() async {
    try {
      final loadedRules = await _storageService.loadRules();
      _rules.clear();
      _rules.addAll(loadedRules);
      _rulesController.add(_rules);

      if (kDebugMode) {
        print('RuleMatchingService: Loaded ${_rules.length} rules');
        for (final rule in _rules) {
          print('  - Rule: ${rule.name} (enabled: ${rule.isEnabled})');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('RuleMatchingService: Error loading rules - $e');
      }
    }
  }

  /// 保存规则到存储服务
  Future<void> _saveRules() async {
    try {
      await _storageService.saveRules(_rules);
      if (kDebugMode) {
        print('RuleMatchingService: Saved ${_rules.length} rules');
      }
    } catch (e) {
      if (kDebugMode) {
        print('RuleMatchingService: Error saving rules - $e');
      }
    }
  }

  /// 更新规则列表
  Future<void> updateRules(List<Rule> rules) async {
    _rules.clear();
    _rules.addAll(rules);
    _rulesController.add(_rules);
    await _saveRules();
    if (kDebugMode) {
      print('RuleMatchingService: Updated rules - count: ${rules.length}');
    }
  }

  /// 添加规则
  Future<void> addRule(Rule rule) async {
    _rules.add(rule);
    _rulesController.add(_rules);
    await _saveRules();
    if (kDebugMode) {
      print('RuleMatchingService: Added rule - ${rule.name}');
    }
  }

  /// 删除规则
  Future<void> removeRule(String ruleId) async {
    _rules.removeWhere((rule) => rule.id == ruleId);
    _rulesController.add(_rules);
    await _saveRules();
    if (kDebugMode) {
      print('RuleMatchingService: Removed rule - $ruleId');
    }
  }

  /// 更新规则
  Future<void> updateRule(Rule updatedRule) async {
    final index = _rules.indexWhere((rule) => rule.id == updatedRule.id);
    if (index != -1) {
      _rules[index] = updatedRule;
      _rulesController.add(_rules);
      await _saveRules();
      if (kDebugMode) {
        print('RuleMatchingService: Updated rule - ${updatedRule.name}');
      }
    }
  }

  /// 启动窗口事件监听
  void _startWindowEventListener() {
    _windowEventSubscription?.cancel();
    _windowEventSubscription =
        _connectionService.windowEvents.listen(_handleWindowEvent);
    if (kDebugMode) {
      print('RuleMatchingService: Started window event listener');
    }
  }

  /// 停止窗口事件监听
  void _stopWindowEventListener() {
    _windowEventSubscription?.cancel();
    _windowEventSubscription = null;
    if (kDebugMode) {
      print('RuleMatchingService: Stopped window event listener');
    }
  }

  /// 处理窗口事件
  void _handleWindowEvent(WindowEvent event) {
    if (event.type != 'WINDOW_STATE_CHANGED') return;

    if (kDebugMode) {
      print(
          'RuleMatchingService: Received window event - ${event.packageName}/${event.activityName}');
      print('RuleMatchingService: Current rules count: ${_rules.length}');
    }

    // 查找匹配的规则
    final matchedRules = _rules
        .where((rule) =>
            rule.isEnabled &&
            rule.packageName == event.packageName &&
            rule.activityName == event.activityName)
        .toList();

    if (matchedRules.isEmpty) {
      if (kDebugMode) {
        print(
            'No matching rules found for ${event.packageName}/${event.activityName}');
      }
      return;
    }

    // 输出匹配信息
    for (final rule in matchedRules) {
      if (kDebugMode) {
        print('Found matching rule: ${rule.name}');
        print('Number of overlay styles: ${rule.overlayStyles.length}');
        for (final style in rule.overlayStyles) {
          print('UiAutomator code: ${style.uiAutomatorCode}');
        }
      }
    }
  }

  /// 停止服务
  void stop() {
    _stopWindowEventListener();
    _serviceStatusSubscription?.cancel();
    _serviceStatusSubscription = null;
    _isInitialized = false;
    if (kDebugMode) {
      print('RuleMatchingService: Stopped');
    }
  }

  /// 释放资源
  void dispose() {
    stop();
    _rulesController.close();
    if (kDebugMode) {
      print('RuleMatchingService: Disposed');
    }
  }
}
