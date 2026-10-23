import 'package:frostdart/frostdart.dart';

const _keys =
    '09000000736563703235366b31020003000100'
    '08f89ffe80ac94dcb920c26f3f46140bfc7f95b493f8310f5fc1ea2b01f4254c'
    '026baee4bf7d4b9c4567dfff6f3c2c76df5c082e9320cd8187d6ab5965bc5a119a'
    '03dacc9463e5186f3c81ae1b314f7b09001a22b28bb56ad0abd3f376818f9604ab'
    '031404710e938032db0d4f6a4cd20ae37384be98ba9fe05b42d139361202b391e6';

List<String> callThroughBindings() {
  final again = serializeKeys(keys: deserializeKeys(keys: _keys));
  final threshold = getThresholdFromKeys(serializedKeys: _keys);
  final participants = getParticipantsCountFromKeys(serializedKeys: _keys);
  if (again != _keys || threshold != 2 || participants != 3) {
    throw StateError('keys round trip ${again == _keys}, $threshold of $participants');
  }
  return ['deserializeKeys/serializeKeys via the bindings: 2 of 3, round trip ok'];
}
