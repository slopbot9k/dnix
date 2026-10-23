// ffi_check <package> <library file> <symbols file>
import 'dart:io';

import 'package:ffi_check/ffi_check.dart';

void main(List<String> args) {
  final [package, path, symbolsFile] = args;
  final symbols = File(symbolsFile)
      .readAsLinesSync()
      .where((line) => line.trim().isNotEmpty)
      .toList();
  try {
    runChecks(package, path, symbols).forEach(stdout.writeln);
  } on CheckFailure catch (failure) {
    report.forEach(stdout.writeln);
    stderr.writeln(failure);
    exit(1);
  }
}
