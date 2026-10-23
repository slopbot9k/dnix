import 'package:flutter_libmwc/mwc.dart' as mwc;

List<String> callThroughBindings() {
  final words = mwc.walletMnemonic().trim().split(RegExp(r'\s+'));
  if (words.length != 24) throw StateError('walletMnemonic gave ${words.length} words');
  return ['walletMnemonic via the bindings: 24 words'];
}
