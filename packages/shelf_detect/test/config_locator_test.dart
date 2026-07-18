import 'package:shelf_detect/shelf_detect.dart';
import 'package:test/test.dart';

import 'fakes.dart';

InstallEvidence _evidence(String name, {String? publisher}) => InstallEvidence(
      source: EvidenceSource.registryUninstall,
      displayName: name,
      publisher: publisher,
    );

void main() {
  test('exact directory name match scores highest', () {
    final fs = FakeFileSystem([
      r'C:\Users\test\AppData\Roaming\Upscayl\config.json',
      r'C:\Users\test\AppData\Roaming\Other\x',
    ]);
    final candidates = locateConfigCandidates(
      evidence: _evidence('Upscayl 2.15.0'),
      fileSystem: fs,
      knownFolders: FakeKnownFolders(),
    );
    expect(candidates.first.path.stored, r'%APPDATA%\Upscayl');
    expect(candidates.first.score, 1.0);
    expect(candidates.map((c) => c.path.stored),
        isNot(contains(r'%APPDATA%\Other')));
  });

  test('publisher\\app two-level layout is found', () {
    final fs = FakeFileSystem([
      r'C:\Users\test\AppData\Local\Black Tree Gaming Ltd\Vortex\state.json',
    ]);
    final candidates = locateConfigCandidates(
      evidence: _evidence('Vortex', publisher: 'Black Tree Gaming Ltd.'),
      fileSystem: fs,
      knownFolders: FakeKnownFolders(),
    );
    expect(candidates.first.path.stored,
        r'%LOCALAPPDATA%\Black Tree Gaming Ltd\Vortex');
    expect(candidates.first.score, greaterThan(0.9));
  });

  test('containment matches score lower than exact', () {
    final fs = FakeFileSystem([
      r'C:\Users\test\AppData\Roaming\CrystalDiskInfo Portable\x',
    ]);
    final candidates = locateConfigCandidates(
      evidence: _evidence('CrystalDiskInfo 9.9.1'),
      fileSystem: fs,
      knownFolders: FakeKnownFolders(),
    );
    expect(candidates, hasLength(1));
    expect(candidates.single.score, lessThan(1.0));
  });

  test('no name evidence yields nothing', () {
    final candidates = locateConfigCandidates(
      evidence: const InstallEvidence(source: EvidenceSource.registryUninstall),
      fileSystem: FakeFileSystem(const []),
      knownFolders: FakeKnownFolders(),
    );
    expect(candidates, isEmpty);
  });

  test('documents folder is searched', () {
    final fs = FakeFileSystem([
      r'C:\Users\test\Documents\ShareX\ApplicationConfig.json',
    ]);
    final candidates = locateConfigCandidates(
      evidence: _evidence('ShareX'),
      fileSystem: fs,
      knownFolders: FakeKnownFolders(),
    );
    expect(candidates.first.path.stored, r'%DOCUMENTS%\ShareX');
  });
}
