import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class IpfsService {
  final String jwtToken;

  IpfsService(this.jwtToken);

  Future<String?> uploadToPinata(Uint8List data, String filename) async {
    final uri = Uri.parse('https://api.pinata.cloud/pinning/pinFileToIPFS');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $jwtToken';

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        data,
        filename: filename,
        contentType: MediaType('application', 'octet-stream'),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['IpfsHash']; // This is your CID
    } else {
      print('Upload failed: ${response.statusCode} ${response.body}');
      return null;
    }
  }

  Future<String> fetchFromIPFS(String cid) async {
  final url = Uri.parse('https://blue-able-caribou-228.mypinata.cloud/ipfs/$cid');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    return response.body;
  } else {
    throw Exception('Failed to fetch from Pinata IPFS: ${response.statusCode}');
  }
}

}
