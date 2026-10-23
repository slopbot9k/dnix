// Opens the library the way Dart FFI does, checks that every symbol the
// package's bindings declare resolves, and calls functions that need no
// wallet, network or files, with the signatures the bindings use.
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

/// Runs every check for [package] against the library at [path] and
/// returns the lines it reports; throws [CheckFailure] on the first failure.
List<String> runChecks(String package, String path, List<String> symbols) {
  report.clear();
  final library = DynamicLibrary.open(path);
  // tor compiles its file-descriptor limit functions only where Unix has
  // the limit; nothing in its Dart code calls them.
  final absentHere = Platform.isWindows && package == 'tor'
      ? {'tor_get_nofile_limit', 'tor_set_nofile_limit'}
      : <String>{};
  final missing = [
    for (final symbol in symbols)
      if (!absentHere.contains(symbol) && !library.providesSymbol(symbol))
        symbol,
  ];
  if (symbols.isEmpty || missing.isNotEmpty) {
    fail('${symbols.length} declared, missing: ${missing.join(', ')}');
  }
  for (final symbol in absentHere) {
    if (library.providesSymbol(symbol)) fail('$symbol is unexpectedly here');
  }
  final unixOnly = absentHere.isEmpty
      ? ''
      : ' (Unix-only, absent: ${absentHere.join(', ')})';
  print(
    '$package: all ${symbols.length - absentHere.length} declared symbols '
    'resolve$unixOnly',
  );
  switch (package) {
    case 'tor':
      library.lookupFunction<Void Function(), void Function()>('tor_hello')();
      final limit = Platform.isWindows
          ? 'n/a'
          : library.lookupFunction<Uint64 Function(), int Function()>(
              'tor_get_nofile_limit',
            )();
      print('tor_hello returned; tor_get_nofile_limit = $limit');
    case 'flutter_libmwc':
      checkMnemonic(library, 'mwc_get_mnemonic', 'mwc_string_free');
      checkOpenWalletError(library, 'mwc_rust_open_wallet', 'mwc_string_free');
    case 'flutter_libepiccash':
      checkMnemonic(library, 'get_mnemonic', 'epic_cash_string_free');
      checkOpenWalletError(
          library, 'rust_open_wallet', 'epic_cash_string_free');
    case 'frostdart':
      checkFrostKeys(library);
    default:
      fail('no calls defined for $package');
  }
  print('$package: OK');
  return List.of(report);
}

final report = <String>[];
void print(Object line) => report.add('$line');

class CheckFailure implements Exception {
  CheckFailure(this.message);
  final String message;
  @override
  String toString() => 'FAIL: $message';
}

Never fail(String message) => throw CheckFailure(message);

typedef StringFn = Pointer<Utf8> Function();
typedef FreeNative = Void Function(Pointer<Utf8>);
typedef FreeDart = void Function(Pointer<Utf8>);
typedef OpenNative = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>);

void checkMnemonic(DynamicLibrary library, String name, String free) {
  final pointer = library.lookupFunction<StringFn, StringFn>(name)();
  if (pointer == nullptr) fail('$name returned null');
  final words = pointer.toDartString().trim().split(RegExp(r'\s+'));
  library.lookupFunction<FreeNative, FreeDart>(free)(pointer);
  if (words.length != 24 ||
      words.any((w) => !RegExp(r'^[a-z]+$').hasMatch(w))) {
    fail('$name gave ${words.length} words');
  }
  print('$name: 24 words, released with $free');
}

void checkOpenWalletError(DynamicLibrary library, String name, String free) {
  final config = '{}'.toNativeUtf8();
  final password = 'unused'.toNativeUtf8();
  final pointer = library.lookupFunction<OpenNative, OpenNative>(name)(
    config,
    password,
  );
  malloc.free(config);
  malloc.free(password);
  if (pointer == nullptr) fail('$name returned null');
  final message = pointer.toDartString();
  library.lookupFunction<FreeNative, FreeDart>(free)(pointer);
  if (!message.startsWith('Error')) {
    fail('$name({}) did not report an error: $message');
  }
  print(
      '$name({}) answered: ${message.length > 80 ? '${message.substring(0, 80)}…' : message}');
}

final class StringView extends Struct {
  external Pointer<Uint8> ptr;
  @UintPtr()
  external int len;
}

final class OwnedString extends Struct {
  external Pointer<Void> strBox;
  external Pointer<Uint8> ptr;
  @UintPtr()
  external int len;
}

final class KeysResult extends Struct {
  external Pointer<Void> value;
  @Uint8()
  external int err;
}

// Participant 1 of the FROST secp256k1 test vector, as frostdart's own
// test uses it: threshold 2 of 3 participants.
const frostKeys = '09000000736563703235366b31020003000100'
    '08f89ffe80ac94dcb920c26f3f46140bfc7f95b493f8310f5fc1ea2b01f4254c'
    '026baee4bf7d4b9c4567dfff6f3c2c76df5c082e9320cd8187d6ab5965bc5a119a'
    '03dacc9463e5186f3c81ae1b314f7b09001a22b28bb56ad0abd3f376818f9604ab'
    '031404710e938032db0d4f6a4cd20ae37384be98ba9fe05b42d139361202b391e6';

void checkFrostKeys(DynamicLibrary library) {
  final deserialize = library.lookupFunction<KeysResult Function(StringView),
      KeysResult Function(StringView)>(
    'deserialize_keys',
  );
  final threshold = library.lookupFunction<Uint16 Function(Pointer<Void>),
      int Function(Pointer<Void>)>(
    'keys_threshold',
  );
  final participants = library.lookupFunction<Uint16 Function(Pointer<Void>),
      int Function(Pointer<Void>)>(
    'keys_participants',
  );
  final serialize = library.lookupFunction<OwnedString Function(Pointer<Void>),
      OwnedString Function(Pointer<Void>)>(
    'serialize_keys',
  );
  final free = library
      .lookupFunction<Void Function(OwnedString), void Function(OwnedString)>(
    'free_owned_string',
  );
  final bytes = frostKeys.codeUnits;
  final buffer = malloc<Uint8>(bytes.length);
  buffer.asTypedList(bytes.length).setAll(0, bytes);
  final view = malloc<StringView>();
  view.ref
    ..ptr = buffer
    ..len = bytes.length;
  final result = deserialize(view.ref);
  malloc.free(view);
  malloc.free(buffer);
  if (result.err != 0 || result.value == nullptr) {
    fail('deserialize_keys failed with error ${result.err}');
  }
  final t = threshold(result.value), n = participants(result.value);
  final owned = serialize(result.value);
  final again = String.fromCharCodes(owned.ptr.asTypedList(owned.len));
  free(owned);
  if (t != 2 || n != 3 || again != frostKeys) {
    fail(
        'keys gave threshold $t, participants $n, round trip ${again == frostKeys}');
  }
  print('deserialize/serialize_keys round-trip the vector; threshold 2 of 3');
}
