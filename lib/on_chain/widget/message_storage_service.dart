import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class MessageStorageService {
  final Web3Client client;
  final DeployedContract contract;
  final EthereumAddress ownAddress;
  final Credentials credentials;
  late ContractFunction sendMessageFunction;

  MessageStorageService({
    required this.client,
    required this.contract,
    required this.ownAddress,
    required this.credentials,
  }) {
    sendMessageFunction = contract.function('sendMessage');
  }

  Future<void> sendMessage(String toAddress, String cid) async {
    final EthereumAddress to = EthereumAddress.fromHex(toAddress);

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

  Future<List<Map<String, dynamic>>> getMessagesFromLogs({
    required EthereumAddress userA,
    required EthereumAddress userB,
  }) async {
    final event = contract.event('MessageSent');
    final topic0 = bytesToHex(event.signature, include0x: true);

    String toTopicAddress(EthereumAddress address) {
      return '0x' + address.hexNo0x.padLeft(64, '0');
    }

    final filter = FilterOptions(
      fromBlock: BlockNum.genesis(),
      toBlock: BlockNum.current(),
      address: contract.address,
      topics: [
        [bytesToHex(event.signature, include0x: true)],
        [
          toTopicAddress(userA),
          toTopicAddress(userB),
        ],
        [
          toTopicAddress(userB),
          toTopicAddress(userA),
        ],
      ],
    );

    final logs = await client.getLogs(filter);
 

    final List<Map<String, dynamic>> parsed = [];

    for (var log in logs) {
      final decoded = event.decodeResults(log.topics!, log.data!);

      final sender = decoded[0] as EthereumAddress;
      final receiver = decoded[1] as EthereumAddress;
      final cid = decoded[2] as String;
      final timestamp = decoded[3] as BigInt;

      // include only messages between userA and userB
      final isBetweenUsers = (sender == userA && receiver == userB) ||
          (sender == userB && receiver == userA);

      if (isBetweenUsers) {
        parsed.add({
          'sender': sender.hex,
          'receiver': receiver.hex,
          'cid': cid,
          'timestamp': timestamp,
          'deleted': false, // can't detect from logs
        });
      }
    }

    return parsed;
  }
}
