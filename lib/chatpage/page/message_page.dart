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
  final UserProfile userProfile;
  const MessageTestPage({
    super.key,
    required this.userProfile,
  });

  @override
  State<MessageTestPage> createState() => _MessageTestPageState();
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

  @override
  void initState() {
    super.initState();
    setup();
    print("Chatting with: ${widget.userProfile.name}");
  }

  Future<void> setup() async {
    final prefs = await SharedPreferences.getInstance();
    final privateKey = prefs.getString('privateKey') ?? '0';

    client = Web3Client("https://sepolia-rollup.arbitrum.io/rpc", Client());
    final abi =
        await rootBundle.loadString('assets/new_message_storage_abi.json');
    contract = DeployedContract(
      ContractAbi.fromJson(abi, "MessageStorage"),
      EthereumAddress.fromHex("0x57b56bf9ed5a655074f3233fb6127945bdf743f7"),
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

    final receiver =
        EthereumAddress.fromHex(widget.userProfile.walletAddress.toLowerCase());
    await messageStorageService.sendMessage(receiver.hex, cid!);

    setState(() {
      status = 'Message sent with CID: $cid';
    });
  }

  Future<void> fetchMessages() async {
    setState(() => status = 'Fetching messages...');

    try {
      final otherAddress = EthereumAddress.fromHex(
          widget.userProfile.walletAddress.toLowerCase());
      final fetchedRaw = await messageStorageService.getMessagesFromLogs(
        userA: ownAddress,
        userB: otherAddress,
      );
      final fetchedMessages =
          fetchedRaw.map((msgMap) => ChatMessage.fromMap(msgMap)).toList();

      setState(() {
        messages = fetchedMessages;
        status = 'Fetched ${messages.length} messages';
      });
    } catch (e) {
      print("Fetch error: $e");
      setState(() => status = 'Error: $e');
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
                    title: FutureBuilder(
                      future: ipfsService.fetchFromIPFS(msg.cid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Text("Loading...");
                        }
                        if (snapshot.hasError) {
                          return Text("Error loading message");
                        }
                        final decrypted =
                            SimpleEncryptor.decrypt(snapshot.data!);
                        return Text(decrypted);
                      },
                    ),
// show CID or decrypted message here
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
