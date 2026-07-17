import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf_detect/shelf_detect.dart';
import 'package:shelf_win32/shelf_win32.dart';

import '../database/db_providers.dart';

/// Runs a system scan off the UI thread and exposes the result.
final scanProvider =
    AsyncNotifierProvider<ScanViewModel, ResolutionResult?>(ScanViewModel.new);

class ScanViewModel extends AsyncNotifier<ResolutionResult?> {
  @override
  Future<ResolutionResult?> build() async => null; // No scan until requested.

  Future<void> scan() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final entries = await ref.read(dbEntriesProvider.future);
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
