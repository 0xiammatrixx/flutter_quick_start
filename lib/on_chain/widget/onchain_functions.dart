import 'package:arbichat/chatpage/model/message_model.dart';
import 'package:arbichat/on_chain/widget/message_storage_service.dart';
import 'package:web3dart/web3dart.dart';

class OnchainFunctions {
  late Web3Client client;
  late DeployedContract contract;
  late EthPrivateKey credentials;
  late EthereumAddress ownAddress;

  final MessageStorageService messageStorageService;
  OnchainFunctions({required this.messageStorageService});

  Future<List<ChatMessage>> fetchMessages(EthereumAddress otherUserAddress) async {
    try {
      final fetchedMaps = await messageStorageService.getMessages(otherUserAddress);
      
      print("=== FETCH RESULTS ===");
      print("Number of messages fetched: ${fetchedMaps.length}");

      final parsedMessages = fetchedMaps.map<ChatMessage>((map) {
        return ChatMessage.fromMap(map);
      }).toList();

      print("Parsed messages: $parsedMessages");

      return parsedMessages;
    } catch (e) {
      print("Error fetching messages: $e");
      return [];
    }
  }
}
