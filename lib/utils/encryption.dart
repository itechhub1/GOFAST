import 'dart:convert' show Utf8Encoder, json;

import 'package:convert/convert.dart' show hex;
import 'package:crypto/crypto.dart' show md5, sha256;
import 'package:meta/meta.dart' show required, visibleForTesting;
import 'package:tripledes/tripledes.dart' show BlockCipher, TripleDESEngine;

class Encryption {
  const Encryption({
    @required this.secretKey,
  }) : assert(secretKey != null);

  static const String ALGORITHM = "3DES-24";
  static const String _TARGET = "FLWSECK-";
  static const int _SUB_STRING_LENGTH = 12;

  final String secretKey;

  String encryptTransactionPin(String pin) {
    return BlockCipher(TripleDESEngine(), generateKey(secretKey))
        .encodeB64(pin);
  }

  String decryptTransactionPin(String encryptedData) {
    print(encryptedData);
    String key = generateKey(secretKey);
    return BlockCipher(TripleDESEngine(), key).decodeB64(encryptedData);
  }

  String encrypt(Map<String, dynamic> data) {
    return BlockCipher(TripleDESEngine(), generateKey(secretKey))
        .encodeB64(json.encode(data));
  }

  Map<String, dynamic> decrypt(String data) {
    final String _data = BlockCipher(
      TripleDESEngine(),
      generateKey(secretKey),
    ).decodeB64(data);
    return json.decode(_data);
  }

  String integrityHash(Map<String, dynamic> data) {
    final _keys = data.keys.toList()..sort();
    final _hash = _keys.fold('', (String acc, String val) {
      // don't include int hash
      if (val == 'integrity_hash') {
        return acc;
      }
      return acc + data[val].toString();
    });
    return hex.encode(
      sha256.convert(const Utf8Encoder().convert(_hash + secretKey)).bytes,
    );
  }

  @visibleForTesting
  String generateKey(String seckey) {
    final String _hash = hex.encode(
      md5.convert(const Utf8Encoder().convert(seckey)).bytes,
    );

    final String _uniqueHash = _hash.substring(
      _hash.length - _SUB_STRING_LENGTH,
      _hash.length,
    );

    return seckey.replaceAll('FLWSECK-', '').substring(0, _SUB_STRING_LENGTH) +
        _uniqueHash;
  }
}
