import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class SecureHttpClient extends http.BaseClient {
  final http.Client _innerClient;
  static const String _clientSecret = 'mspay_signature_secret_2026_!';

  SecureHttpClient(this._innerClient);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Only intercept requests containing payloads (POST/PUT requests)
    if (request is http.Request && (request.method == 'POST' || request.method == 'PUT')) {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final body = request.body;

      // Calculate HMAC-SHA256 signature: HMAC_SHA256(secret, timestamp + ":" + body)
      final hmac = Hmac(sha256, utf8.encode(_clientSecret));
      final payloadToSign = '$timestamp:$body';
      final signature = hmac.convert(utf8.encode(payloadToSign)).toString();

      // Append request signing and security audit headers
      request.headers['X-Payload-Signature'] = signature;
      request.headers['X-Timestamp'] = timestamp;
      request.headers['X-Device-Fingerprint'] = 'device_audited_secure';
    }

    return _innerClient.send(request);
  }
}
