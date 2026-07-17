import 'dart:isolate';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf_detect/shelf_detect.dart';
import 'package:shelf_rules/shelf_rules.dart';
import 'package:shelf_win32/shelf_win32.dart';

/// Runs a system scan off the UI thread and exposes the result.
final scanProvider =
    AsyncNotifierProvider<ScanViewModel, ResolutionResult?>(ScanViewModel.new);

class ScanViewModel extends AsyncNotifier<ResolutionResult?> {
  @override
  Future<ResolutionResult?> build() async => null; // No scan until requested.

  Future<void> scan() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final yaml = await rootBundle.loadString('assets/dev_db.yaml');
      final outcome = parseAppEntryListYaml(yaml);
      final entries = outcome.value ?? const [];
      // Registry + filesystem enumeration is blocking FFI work — keep it off
      // the UI thread.
      return Isolate.run(() => scanSystem(
            entries: entries,
            registry: const WindowsRegistryView(),
            fileSystem: const RealFileSystem(),
            knownFolders: WindowsKnownFolderResolver(),
          ));
    });
  }
}
