import 'dart:io';

import 'package:tor_ffi_plugin/tor_ffi_plugin_bindings_generated.dart' as tor;

List<String> callThroughBindings() {
  tor.tor_hello();
  final limit = Platform.isWindows ? 'n/a' : '${tor.tor_get_nofile_limit()}';
  return ['tor_hello via the bindings; nofile limit $limit'];
}
