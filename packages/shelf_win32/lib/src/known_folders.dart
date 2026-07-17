import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:shelf_core/shelf_core.dart';

/// [KnownFolderResolver] backed by SHGetKnownFolderPath — the authoritative
/// source for per-user folder locations. Environment variables are never
/// consulted (they can lie under elevation or redirection).
final class WindowsKnownFolderResolver implements KnownFolderResolver {
  WindowsKnownFolderResolver();

  final _cache = <KnownFolder, String>{};

  @override
  String resolve(KnownFolder folder) =>
      _cache.putIfAbsent(folder, () => _shGetKnownFolderPath(_folderId(folder)));

  // KNOWNFOLDERID GUIDs, from KnownFolders.h.
  static _Guid _folderId(KnownFolder folder) => switch (folder) {
        // {3EB685DB-65F9-4CF6-A03A-E3EF65729F3D} RoamingAppData
        KnownFolder.appData => const _Guid(
            0x3EB685DB, 0x65F9, 0x4CF6, [0xA0, 0x3A, 0xE3, 0xEF, 0x65, 0x72, 0x9F, 0x3D]),
        // {F1B32785-6FBA-4FCF-9D55-7B8E7F157091} LocalAppData
        KnownFolder.localAppData => const _Guid(
            0xF1B32785, 0x6FBA, 0x4FCF, [0x9D, 0x55, 0x7B, 0x8E, 0x7F, 0x15, 0x70, 0x91]),
        // {62AB5D82-FDC1-4DC3-A9DD-070D1D495D97} ProgramData
        KnownFolder.programData => const _Guid(
            0x62AB5D82, 0xFDC1, 0x4DC3, [0xA9, 0xDD, 0x07, 0x0D, 0x1D, 0x49, 0x5D, 0x97]),
        // {5E6C858F-0E22-4760-9AFE-EA3317B67173} Profile
        KnownFolder.userProfile => const _Guid(
            0x5E6C858F, 0x0E22, 0x4760, [0x9A, 0xFE, 0xEA, 0x33, 0x17, 0xB6, 0x71, 0x73]),
        // {FDD39AD0-238F-46AF-ADB4-6C85480369C7} Documents
        KnownFolder.documents => const _Guid(
            0xFDD39AD0, 0x238F, 0x46AF, [0xAD, 0xB4, 0x6C, 0x85, 0x48, 0x03, 0x69, 0xC7]),
      };
}

final class _Guid {
  const _Guid(this.data1, this.data2, this.data3, this.data4);

  final int data1;
  final int data2;
  final int data3;
  final List<int> data4;
}

final class _GuidStruct extends Struct {
  @Uint32()
  external int data1;
  @Uint16()
  external int data2;
  @Uint16()
  external int data3;
  @Array(8)
  external Array<Uint8> data4;
}

typedef _SHGetKnownFolderPathNative = Int32 Function(
    Pointer<_GuidStruct> rfid, Uint32 dwFlags, IntPtr hToken, Pointer<Pointer<Utf16>> ppszPath);
typedef _SHGetKnownFolderPathDart = int Function(
    Pointer<_GuidStruct> rfid, int dwFlags, int hToken, Pointer<Pointer<Utf16>> ppszPath);

typedef _CoTaskMemFreeNative = Void Function(Pointer<NativeType> pv);
typedef _CoTaskMemFreeDart = void Function(Pointer<NativeType> pv);

final _shell32 = DynamicLibrary.open('shell32.dll');
final _ole32 = DynamicLibrary.open('ole32.dll');

final _shGetKnownFolderPathFn = _shell32
    .lookupFunction<_SHGetKnownFolderPathNative, _SHGetKnownFolderPathDart>(
        'SHGetKnownFolderPath');
final _coTaskMemFree = _ole32
    .lookupFunction<_CoTaskMemFreeNative, _CoTaskMemFreeDart>('CoTaskMemFree');

String _shGetKnownFolderPath(_Guid guid) {
  final rfid = calloc<_GuidStruct>();
  final ppszPath = calloc<Pointer<Utf16>>();
  try {
    rfid.ref.data1 = guid.data1;
    rfid.ref.data2 = guid.data2;
    rfid.ref.data3 = guid.data3;
    for (var i = 0; i < 8; i++) {
      rfid.ref.data4[i] = guid.data4[i];
    }
    final hr = _shGetKnownFolderPathFn(rfid, 0, 0, ppszPath);
    if (hr != 0) {
      throw StateError(
          'SHGetKnownFolderPath failed with HRESULT 0x${hr.toRadixString(16)}');
    }
    final path = ppszPath.value.toDartString();
    _coTaskMemFree(ppszPath.value.cast());
    return path;
  } finally {
    calloc.free(rfid);
    calloc.free(ppszPath);
  }
}
