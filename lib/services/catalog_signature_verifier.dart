import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Implementasi murni Dart untuk tanda tangan digital asimetris **Ed25519 (RFC 8032)**
/// menggunakan `BigInt` dan `sha512` dari `package:crypto` tanpa tambahan dependensi pihak ketiga.
///
/// Digunakan oleh `ModuleDownloadService` untuk memverifikasi keaslian `module_catalog.json`
/// dengan *public key* tertanam di aplikasi, sementara *private key* disimpan terpisah di luar repo.
class Ed25519Crypto {
  const Ed25519Crypto._();

  static final BigInt _b = BigInt.from(256);
  static final BigInt _q = (BigInt.one << 255) - BigInt.from(19);
  static final BigInt _l =
      (BigInt.one << 252) +
      BigInt.parse('27742317777372353535851937790883648493');

  static final BigInt _d =
      (_q - BigInt.from(121665)) * _inv(BigInt.from(121666)) % _q;
  static final BigInt _i = BigInt.two.modPow(
    (_q - BigInt.one) ~/ BigInt.from(4),
    _q,
  );

  static final List<BigInt> _by = () {
    final y = BigInt.from(4) * _inv(BigInt.from(5)) % _q;
    final x = _xRecover(y);
    return <BigInt>[x % _q, y % _q, BigInt.one, (x * y) % _q];
  }();

  static BigInt _inv(BigInt x) => x.modPow(_q - BigInt.two, _q);

  static BigInt _xRecover(BigInt y) {
    final y2 = (y * y) % _q;
    final xx = ((y2 - BigInt.one) * _inv((_d * y2 + BigInt.one) % _q)) % _q;
    var x = xx.modPow((_q + BigInt.from(3)) ~/ BigInt.from(8), _q);
    if (((x * x - xx) % _q) != BigInt.zero) {
      x = (x * _i) % _q;
    }
    if (x.isOdd) {
      x = _q - x;
    }
    return x;
  }

  static List<BigInt> _edwardsAdd(List<BigInt> p, List<BigInt> qPt) {
    final a = ((p[1] - p[0]) * (qPt[1] - qPt[0])) % _q;
    final b = ((p[1] + p[0]) * (qPt[1] + qPt[0])) % _q;
    final c = (BigInt.two * p[3] * qPt[3] * _d) % _q;
    final d = (BigInt.two * p[2] * qPt[2]) % _q;
    final e = (b - a) % _q;
    final f = (d - c) % _q;
    final g = (d + c) % _q;
    final h = (b + a) % _q;
    return <BigInt>[(e * f) % _q, (g * h) % _q, (f * g) % _q, (e * h) % _q];
  }

  static List<BigInt> _edwardsDouble(List<BigInt> p) {
    final a = (p[0] * p[0]) % _q;
    final b = (p[1] * p[1]) % _q;
    final c = (BigInt.two * p[2] * p[2]) % _q;
    final h = (a + b) % _q;
    final sumXY = (p[0] + p[1]) % _q;
    final e = (h - (sumXY * sumXY) % _q) % _q;
    final g = (a - b) % _q;
    final f = (c + g) % _q;
    return <BigInt>[(e * f) % _q, (g * h) % _q, (f * g) % _q, (e * h) % _q];
  }

  static List<BigInt> _scalarMult(List<BigInt> p, BigInt e) {
    var result = <BigInt>[BigInt.zero, BigInt.one, BigInt.one, BigInt.zero];
    var addend = p;
    var scalar = e;
    while (scalar > BigInt.zero) {
      if (scalar.isOdd) {
        result = _edwardsAdd(result, addend);
      }
      addend = _edwardsDouble(addend);
      scalar >>= 1;
    }
    return result;
  }

  static Uint8List _encodePoint(List<BigInt> pt) {
    final zInv = _inv(pt[2]);
    final x = (pt[0] * zInv) % _q;
    final y = (pt[1] * zInv) % _q;
    final out = _encodeInt(y, 32);
    if (x.isOdd) {
      out[31] |= 0x80;
    }
    return out;
  }

  static List<BigInt>? _decodePoint(Uint8List bytes) {
    if (bytes.length != 32) return null;
    final copy = Uint8List.fromList(bytes);
    final xSign = (copy[31] >> 7) & 1;
    copy[31] &= 0x7F;
    final y = _decodeInt(copy);
    if (y >= _q) return null;
    var x = _xRecover(y);
    if ((x.isOdd ? 1 : 0) != xSign) {
      x = _q - x;
    }
    final y2 = (y * y) % _q;
    final x2 = (x * x) % _q;
    final lhs = (y2 - x2) % _q;
    final rhs = (BigInt.one + _d * x2 * y2) % _q;
    if (lhs != rhs) return null;
    return <BigInt>[x, y, BigInt.one, (x * y) % _q];
  }

  static Uint8List _encodeInt(BigInt n, int length) {
    final out = Uint8List(length);
    var v = n;
    for (var i = 0; i < length; i++) {
      out[i] = (v & BigInt.from(0xFF)).toInt();
      v >>= 8;
    }
    return out;
  }

  static BigInt _decodeInt(Uint8List bytes) {
    var result = BigInt.zero;
    for (var i = bytes.length - 1; i >= 0; i--) {
      result = (result << 8) | BigInt.from(bytes[i]);
    }
    return result;
  }

  static Uint8List publicKeyFromSeed(Uint8List seed32) {
    if (seed32.length != 32) {
      throw ArgumentError('Ed25519 private seed must be 32 bytes.');
    }
    final h = Uint8List.fromList(sha512.convert(seed32).bytes);
    h[0] &= 248;
    h[31] &= 63;
    h[31] |= 64;
    final a = _decodeInt(Uint8List.sublistView(h, 0, 32));
    final pubPt = _scalarMult(_by, a);
    return _encodePoint(pubPt);
  }

  static Uint8List sign(Uint8List message, Uint8List seed32) {
    if (seed32.length != 32) {
      throw ArgumentError('Ed25519 private seed must be 32 bytes.');
    }
    final h = Uint8List.fromList(sha512.convert(seed32).bytes);
    h[0] &= 248;
    h[31] &= 63;
    h[31] |= 64;
    final a = _decodeInt(Uint8List.sublistView(h, 0, 32));
    final prefix = Uint8List.sublistView(h, 32, 64);
    final pubKey = _encodePoint(_scalarMult(_by, a));

    final rDigest = sha512.convert(<int>[...prefix, ...message]).bytes;
    final r = _decodeInt(Uint8List.fromList(rDigest)) % _l;
    final rEncoded = _encodePoint(_scalarMult(_by, r));

    final kDigest = sha512.convert(<int>[
      ...rEncoded,
      ...pubKey,
      ...message,
    ]).bytes;
    final k = _decodeInt(Uint8List.fromList(kDigest)) % _l;
    final s = (r + k * a) % _l;
    final sEncoded = _encodeInt(s, 32);

    return Uint8List.fromList(<int>[...rEncoded, ...sEncoded]);
  }

  static bool verify({
    required Uint8List message,
    required Uint8List signature,
    required Uint8List publicKey,
  }) {
    if (signature.length != 64 || publicKey.length != 32) {
      return false;
    }
    final rBytes = Uint8List.sublistView(signature, 0, 32);
    final sBytes = Uint8List.sublistView(signature, 32, 64);

    final rPt = _decodePoint(rBytes);
    final aPt = _decodePoint(publicKey);
    if (rPt == null || aPt == null) return false;

    final s = _decodeInt(sBytes);
    if (s >= _l || _b.sign == 0) return false;

    final kDigest = sha512.convert(<int>[
      ...rBytes,
      ...publicKey,
      ...message,
    ]).bytes;
    final k = _decodeInt(Uint8List.fromList(kDigest)) % _l;

    final lhs = _scalarMult(_by, s);
    final rhs = _edwardsAdd(rPt, _scalarMult(aPt, k));
    final lhsEnc = _encodePoint(lhs);
    final rhsEnc = _encodePoint(rhs);

    var diff = 0;
    for (var i = 0; i < 32; i++) {
      diff |= lhsEnc[i] ^ rhsEnc[i];
    }
    return diff == 0;
  }

  static String bytesToHex(Uint8List bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  static Uint8List hexToBytes(String hex) {
    final cleaned = hex.trim();
    if (cleaned.length.isOdd) {
      throw const FormatException('Invalid hex length');
    }
    final out = Uint8List(cleaned.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      final byteVal = int.tryParse(
        cleaned.substring(i * 2, i * 2 + 2),
        radix: 16,
      );
      if (byteVal == null) {
        throw const FormatException('Invalid hex character');
      }
      out[i] = byteVal;
    }
    return out;
  }
}

/// Memverifikasi tanda tangan digital Ed25519 pada `module_catalog.json`
/// serta mengekstrak metadata keamanan (`min_app_version`, `revoked_modules`).
class CatalogSignatureVerifier {
  const CatalogSignatureVerifier._();

  /// Public key Ed25519 resmi KATARA (32 byte hex) yang tertanam di aplikasi.
  /// Kunci privat pasangannya disimpan di luar bundel APK (`.keys/`, di-`.gitignore`).
  static const String embeddedPublicKeyHex =
      '57ee50c3b50ecc5775b50a45e6c2d67e3cb03a4a977be93caf156b88cd145466';

  /// Menyusun payload kanonik (UTF-8 JSON deterministik) dari katalog modul
  /// untuk ditandatangani dan diverifikasi dengan Ed25519.
  static Uint8List canonicalCatalogPayload(Map<String, dynamic> catalogJson) {
    final modulesRaw = (catalogJson['modules'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final canonicalModules = modulesRaw.map((m) {
      final rawContentVer = m['content_version'];
      final contentVer = rawContentVer is num
          ? rawContentVer.toInt()
          : int.tryParse(rawContentVer?.toString() ?? '') ?? 1;
      final rawSize = m['size_bytes'];
      final sizeBytes = rawSize is num
          ? rawSize.toInt()
          : int.tryParse(rawSize?.toString() ?? '') ?? 0;
      return <String, dynamic>{
        'course_id': (m['course_id'] ?? '').toString(),
        'version': (m['version'] ?? '1.0.0').toString(),
        'content_version': contentVer,
        'sha256': (m['sha256'] ?? '').toString().toLowerCase(),
        'size_bytes': sizeBytes,
        'download_url': (m['download_url'] ?? '').toString(),
      };
    }).toList();

    final revokedRaw =
        (catalogJson['revoked_modules'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList()
          ..sort();

    final canonicalRoot = <String, dynamic>{
      'catalog_version': (catalogJson['catalog_version'] ?? '1.0.0').toString(),
      'min_app_version': (catalogJson['min_app_version'] ?? '1.0.0').toString(),
      'revoked_modules': revokedRaw,
      'modules': canonicalModules,
    };

    return Uint8List.fromList(utf8.encode(jsonEncode(canonicalRoot)));
  }

  static bool verifyCatalog(
    Map<String, dynamic> catalogJson, {
    String publicKeyHex = embeddedPublicKeyHex,
  }) {
    final sigHex = catalogJson['signature_ed25519'] as String?;
    if (sigHex == null || sigHex.trim().length != 128) {
      return false;
    }
    try {
      final sigBytes = Ed25519Crypto.hexToBytes(sigHex);
      final pubBytes = Ed25519Crypto.hexToBytes(publicKeyHex);
      final message = canonicalCatalogPayload(catalogJson);
      return Ed25519Crypto.verify(
        message: message,
        signature: sigBytes,
        publicKey: pubBytes,
      );
    } catch (_) {
      return false;
    }
  }
}
