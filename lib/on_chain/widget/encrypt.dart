import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';

class SimpleEncryptor {
  static final _key =
      Key.fromUtf8('my32lengthsupersecretnooneknows!'); // Must be 32 chars

  static String encrypt(String plainText) {
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(_key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    final combined = iv.bytes + encrypted.bytes;
    return base64Encode(combined);
  }

  static String decrypt(String base64Text) {
    final combined = base64Decode(base64Text);
    final iv = IV(Uint8List.fromList(combined.sublist(0, 16)));
    final cipherText = combined.sublist(16);

    final encrypter = Encrypter(AES(_key, mode: AESMode.cbc));
    return encrypter.decrypt(Encrypted(Uint8List.fromList(cipherText)), iv: iv);
  }
}
