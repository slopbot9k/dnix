import 'package:flutter_libepiccash/epic_cash.dart' as epic;

List<String> callThroughBindings() {
  final words = epic.walletMnemonic().trim().split(RegExp(r'\s+'));
  if (words.length != 24) throw StateError('walletMnemonic gave ${words.length} words');
  return ['walletMnemonic via the bindings: 24 words'];
}
