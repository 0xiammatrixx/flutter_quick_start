import 'package:encrypt/encrypt.dart';

class SimpleEncryptor {
  static final _key = Key.fromUtf8('my32lengthsupersecretnooneknows!'); // Must be 32 chars
  static final _iv = IV.fromLength(16);

  static String encrypt(String plainText) {
    final encrypter = Encrypter(AES(_key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  static String decrypt(String encryptedText) {
    final encrypter = Encrypter(AES(_key, mode: AESMode.cbc));
    final decrypted = encrypter.decrypt64(encryptedText, iv: _iv);
    return decrypted;
  }
}
