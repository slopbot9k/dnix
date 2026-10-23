// Runs on an Android device or emulator inside a bare Flutter app whose
// jniLibs hold the libraries a build host produced: opens the library the
// way Dart FFI does on Android, by file name, and runs the same checks as
// the command-line ffi_check. print reaches the host's flutter test output.
import 'package:ffi_check/ffi_check.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const package = String.fromEnvironment('PACKAGE');
const library = String.fromEnvironment('LIBRARY');
const symbols = String.fromEnvironment('SYMBOLS');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  test('lib$library.so loads and answers on Android', () {
    List<String> lines;
    try {
      lines = runChecks(package, 'lib$library.so', symbols.split(','));
    } catch (error) {
      print('FFI-CHECK $package FAILED: $error');
      rethrow;
    }
    for (final line in lines) {
      print('FFI-CHECK $line');
    }
    expect(lines.last, '$package: OK');
  });
}
