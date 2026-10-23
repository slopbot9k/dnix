// Runs inside the package's example app on a device or simulator.
//
// First it calls the library through the package's own Dart API, so the
// call goes through the package's @Native bindings and Flutter's native
// assets. Then it opens the library file Flutter bundled and checks every
// symbol the bindings declare.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'calls.dart';
import 'checks.dart';

const package = String.fromEnvironment('PACKAGE');
const library = String.fromEnvironment('LIBRARY');
const symbols = String.fromEnvironment('SYMBOLS');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('$package answers through its own bindings', () {
    for (final line in callThroughBindings()) {
      stdout.writeln(line);
    }
  });

  test('the bundled $library exports every declared symbol and answers', () {
    final lines = runChecks(package, bundledLibrary(), symbols.split(','));
    lines.forEach(stdout.writeln);
    expect(lines.last, '$package: OK');
  });
}

String bundledLibrary() {
  if (Platform.isAndroid) return 'lib$library.so';
  final executable = File(Platform.resolvedExecutable).parent.path;
  final frameworks =
      Platform.isMacOS ? '$executable/../Frameworks' : '$executable/Frameworks';
  final name = library.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '');
  return '$frameworks/$name.framework/$name';
}
