// Runs on an Android device or emulator inside a bare Flutter app whose
// jniLibs hold the libraries a build host produced: opens the library the
// way Dart FFI does on Android, by file name, and runs the same checks as
// the command-line ffi_check.
import 'dart:io';

import 'package:ffi_check/ffi_check.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const package = String.fromEnvironment('PACKAGE');
const library = String.fromEnvironment('LIBRARY');
const symbols = String.fromEnvironment('SYMBOLS');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  test('lib$library.so loads and answers on Android', () {
    final lines = runChecks(package, 'lib$library.so', symbols.split(','));
    lines.forEach(stdout.writeln);
    expect(lines.last, '$package: OK');
  });
}
