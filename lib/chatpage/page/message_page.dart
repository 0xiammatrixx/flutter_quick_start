import 'dart:convert';
import 'package:arbichat/chatpage/model/message_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arbichat/on_chain/widget/encrypt.dart';
import 'package:arbichat/on_chain/widget/message_storage_service.dart';
import 'package:arbichat/on_chain/widget/pinata_ipfs.dart';
import 'package:web3dart/web3dart.dart';

class MessageTestPage extends StatefulWidget {
  @override
  _MessageTestPageState createState() => _MessageTestPageState();
}

class _MessageTestPageState extends State<MessageTestPage> {

  late Web3Client client;
  late DeployedContract contract;
  late EthPrivateKey credentials;
  late MessageStorageService messageStorageService;
  late EthereumAddress ownAddress;

  final _controller = TextEditingController();
  String status = '';

  late IpfsService ipfsService;

  List<ChatMessage> messages = []; 

  final EthereumAddress otherUserAddress =
      EthereumAddress.fromHex("0x96a142a54ac31fac2e8ae2ffc97f0c929c85be66");

  @override
  void initState() {
    super.initState();
    setup();
    
  }

  Future<void> setup() async {
    final prefs = await SharedPreferences.getInstance();
    final privateKey = prefs.getString('privateKey') ?? '0';

    client = Web3Client("https://sepolia-rollup.arbitrum.io/rpc", Client());
    final abi = await rootBundle.loadString('assets/message_storage_abi.json');
    contract = DeployedContract(
      ContractAbi.fromJson(abi, "MessageStorage"),
      EthereumAddress.fromHex("0x3ec85eb1970413642bd229e4e20a9254b030db19"),
    );
    credentials = EthPrivateKey.fromHex(privateKey);
    ownAddress = await credentials.extractAddress();

    messageStorageService = MessageStorageService(
      client: client,
      contract: contract,
      ownAddress: ownAddress,
      credentials: credentials,
    );

    ipfsService = IpfsService(
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySW5mb3JtYXRpb24iOnsiaWQiOiI2MjFhY2UwOS1mMGNiLTQzMjYtYTZkNS0zYjljNmYwZDdmYTAiLCJlbWFpbCI6ImNvZGVkbWF0cml4bG9sQGdtYWlsLmNvbSIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJwaW5fcG9saWN5Ijp7InJlZ2lvbnMiOlt7ImRlc2lyZWRSZXBsaWNhdGlvbkNvdW50IjoxLCJpZCI6IkZSQTEifSx7ImRlc2lyZWRSZXBsaWNhdGlvbkNvdW50IjoxLCJpZCI6Ik5ZQzEifV0sInZlcnNpb24iOjF9LCJtZmFfZW5hYmxlZCI6ZmFsc2UsInN0YXR1cyI6IkFDVElWRSJ9LCJhdXRoZW50aWNhdGlvblR5cGUiOiJzY29wZWRLZXkiLCJzY29wZWRLZXlLZXkiOiI2YzVhMTMwOTZhNTc5YWY0MzJlYyIsInNjb3BlZEtleVNlY3JldCI6ImQ0NTllNTI2NWI1OWQ0NmI3MDEwNjQzYmJlNmM2MjBjODMzNjZiNGU0NWFjMTkyNGE4NDczZmQ1OGNjMTQxODYiLCJleHAiOjE3ODAyODY2NTh9.QiFDw0xZSgr2BCqZgPNYmAAKAMt5RP9nJgJPqvCaoA4');

    setState(() {
      status = 'Setup complete';
    });
  }

  Future<void> sendMessage(String message) async {

    setState(() {
      status = 'Encrypting...';
    });

    final encryptedMessage = SimpleEncryptor.encrypt(message);
    Uint8List bytes = Uint8List.fromList(utf8.encode(encryptedMessage));
    print("Encrypted Message: $encryptedMessage");

    setState(() {
      status = 'Uploading to IPFS...';
    });

    final cid = await ipfsService.uploadToPinata(bytes, 'message.txt');

    if (cid != null) {
      setState(() => status = 'Message sent! CID: $cid');
    } else {
      setState(() => status = 'Upload failed.');
    }
    print('CID: $cid');
    setState(() {
      status = 'Sending to blockchain...';
    });

    

    final toAddress =
        '0xd04d75A49f88319e2fDcCBC5542236194Ec1E942'; // Use the recipient address
    final timestamp = BigInt.from(DateTime.now().millisecondsSinceEpoch);

    // Call the smart contract here
    await messageStorageService.sendMessage(toAddress, cid!);

    setState(() {
      status = 'Message sent with CID: $cid';
    });
  }

  Future<void> testDirectContractCall() async {
    setState(() {
      status = 'Testing direct contract call...';
    });
    
    try {
      print("=== TESTING DIRECT CONTRACT CALL ===");
      print("Your address: $ownAddress");
      print("Target address: $otherUserAddress");
      print("Contract address: ${contract.address}");
      
      // Test calling the contract directly with web3dart
      final result = await client.call(
        contract: contract,
        function: messageStorageService.getMessagesFunction,
        params: [otherUserAddress],
      );
      
      print("Direct call result: $result");
      print("Result type: ${result.runtimeType}");
      print("Result length: ${result.length}");
      
      if (result.isNotEmpty) {
        print("First element: ${result[0]}");
        print("First element type: ${result[0].runtimeType}");
        if (result[0] is List) {
          print("Array length: ${(result[0] as List).length}");
        }
      }
      
      setState(() {
        status = 'Direct call completed. Check console for details.';
      });
      
    } catch (e) {
      print("Direct call error: $e");
      setState(() {
        status = 'Direct call failed: $e';
      });
    }}

  Future<void> fetchMessages() async {
    setState(() {
      status = 'Fetching messages...';
    });

    try {
      final fetchedMessages =
      
          await messageStorageService.getMessages(otherUserAddress);
          print("=== FETCH RESULTS ===");
      print("Number of messages fetched: ${fetchedMessages.length}");
      print("Messages: $fetchedMessages");
          
      final parsedMessages = fetchedMessages.map<ChatMessage>((map) {
        return ChatMessage.fromMap(map);
      }).toList();
      setState(() {
        messages = parsedMessages;
        status = 'Fetched ${messages.length} messages';
      });
    } catch (e) {
      setState(() {
        status = 'Failed to fetch messages: $e';
        print('$e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Test Message Sender")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(labelText: 'Enter message'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final message = _controller.text.trim();
                if (message.isNotEmpty) {
                  sendMessage(message);
                }
              },
              child: Text("Send Message"),
            ),
            SizedBox(height: 20),
            Text(status),
            ElevatedButton(
              onPressed: fetchMessages,
              child: Text("Fetch Messages"),
            ),
            SizedBox(height: 20),
            Text(status),
            Expanded(
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  return ListTile(
                    title: Text(msg.cid), // show CID or decrypted message here
                    subtitle: Text('From: ${msg.sender}\nAt: ${msg.timestamp}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
