import 'package:web3dart/web3dart.dart';

class MessageStorageService {
  final Web3Client client;
  final DeployedContract contract;
  final EthereumAddress ownAddress;
  final Credentials credentials;
  late ContractFunction sendMessageFunction;
  late ContractFunction getMessagesFunction;

  MessageStorageService({
    required this.client,
    required this.contract,
    required this.ownAddress,
    required this.credentials,
  }) {
    sendMessageFunction = contract.function('sendMessage');
    getMessagesFunction = contract.function("getMessages");
  }

  Future<void> sendMessage(String toAddress, String cid) async {
    final EthereumAddress to = EthereumAddress.fromHex(toAddress);
    
    print("=== SENDING MESSAGE ===");
    print("From: $ownAddress");
    print("To: $to");
    print("CID: $cid");
    
    await client.sendTransaction(
      credentials,
      Transaction.callContract(
        contract: contract,
        function: sendMessageFunction,
        parameters: [to, cid],
        maxGas: 200000,
      ),
      chainId: 421614,
    );
  }

  Future<List<Map<String, dynamic>>> getMessages(EthereumAddress otherUser) async {
    final userAddress = await credentials.extractAddress();
    
    print("=== FETCHING MESSAGES ===");
    print("Your address: $userAddress");
    print("Other user address: $otherUser");
    print("Contract address: ${contract.address}");
    
    final result = await client.call(
      contract: contract,
      function: getMessagesFunction,
      params: [otherUser],
    );
    
    print("Raw result type: ${result.runtimeType}");
    print("Raw result length: ${result.length}");
    print("Raw getMessages result: $result");
    
    if (result.isEmpty) {
      print("ERROR: No messages returned from smart contract");
      return [];
    }
    
    final List<dynamic> messagesRaw = result[0] as List<dynamic>;
    print("Messages array length: ${messagesRaw.length}");
    
    final List<Map<String, dynamic>> parsedMessages = [];
    
    for (int i = 0; i < messagesRaw.length; i++) {
      final msg = messagesRaw[i];
      print("Processing message $i: $msg");
      
      try {
        final parsedMsg = {
          "sender": msg[0] as EthereumAddress,
          "receiver": msg[1] as EthereumAddress,
          "cid": msg[2] as String,
          "timestamp": msg[3] as BigInt,
          "deleted": msg[4] as bool,
        };
         
          parsedMessages.add(parsedMsg);
        
        
      } catch (e) {
        print("Error parsing message $i: $e");
      }
    }
    
    print("Returning ${parsedMessages.length} parsed messages");
    return parsedMessages;
  }
}