import 'dart:convert';
import 'package:arbichat/chatpage/model/message_model.dart';
import 'package:arbichat/chatpage/widgets/ui_updates.dart';
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
  final Map<String, String> _decryptedCache = {};
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

    await fetchMessages();

    setState(() {
      status = 'Setup complete';
    });
  }

  Future<void> sendMessage(String message) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final receiver =
        EthereumAddress.fromHex(widget.userProfile.walletAddress.toLowerCase());

    final encryptedMessage = SimpleEncryptor.encrypt(message);
    Uint8List bytes = Uint8List.fromList(utf8.encode(encryptedMessage));

    // Optimistic UI update
    final tempMsg = ChatMessage(
      sender: ownAddress,
      receiver: receiver,
      cid: '__pending__',
      timestamp: BigInt.from(timestamp),
      deleted: false,
      plaintext: message,
    );

    setState(() => messages.add(tempMsg));

    try {
      final cid = await ipfsService.uploadToPinata(bytes, 'message.txt');
      if (cid == null) return;

      await messageStorageService.sendMessage(receiver.hex, cid);

      setState(() {
        final index = messages.indexWhere((m) => m.cid == '__pending__');
        if (index != -1) {
          messages[index] = messages[index].copyWith(cid: cid);
        }
      });
    } catch (e) {
      print("Send error: $e");
    }
  }

  Future<void> fetchMessages() async {
    try {
      final otherAddress = EthereumAddress.fromHex(
          widget.userProfile.walletAddress.toLowerCase());
      final fetchedRaw = await messageStorageService.getMessagesFromLogs(
        userA: ownAddress,
        userB: otherAddress,
      );
      final fetchedMessages =
          fetchedRaw.map((msgMap) => ChatMessage.fromMap(msgMap)).toList();

      setState(() => messages = fetchedMessages);
    } catch (e) {
      print("Fetch error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    var bgcol = const Color.fromARGB(255, 235, 235, 235).withOpacity(1);
    var textcol = const Color.fromARGB(255, 17, 24, 39);
    return Scaffold(
      backgroundColor: bgcol,
      appBar: buildChatAppBar(
          widget.userProfile.name, widget.userProfile.avatarUrl),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(child: Text("No messages yet"))
                : ListView(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    children: _buildMessageList().reversed.toList(),
                  ),
          ),
          const Divider(height: 1),
          _buildInputArea(), // translucent input
        ],
      ),
    );
  }

  List<Widget> _buildMessageList() {
    List<Widget> widgets = [];
    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
      final isMe = msg.sender == ownAddress;
      final msgDate =
          DateTime.fromMillisecondsSinceEpoch(msg.timestamp.toInt() * 1000);

      final showDate = i == 0 ||
          msgDate.day !=
              DateTime.fromMillisecondsSinceEpoch(
                      messages[i - 1].timestamp.toInt() * 1000)
                  .day;

      if (showDate) {
        widgets.add(DateSeparator(date: msgDate));
      }

      if (msg.cid == '__pending__' && msg.plaintext != null) {
        widgets.add(ChatBubble(isMe: isMe, message: msg.plaintext!));
        continue;
      }

      if (_decryptedCache.containsKey(msg.cid)) {
        widgets.add(ChatBubble(isMe: isMe, message: _decryptedCache[msg.cid]!));
        continue;
      }

      widgets.add(FutureBuilder<String>(
        future: ipfsService.fetchFromIPFS(msg.cid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData &&
              snapshot.data != null) {
            try {
              final decrypted = SimpleEncryptor.decrypt(snapshot.data!);
              _decryptedCache[msg.cid] = decrypted;
              if (msg != null) {
              return ChatBubble(isMe: isMe, message: decrypted);
              }
            } catch (e) {
              return _buildErrorBubble();
            }
          } else if (snapshot.hasError) {
            return _buildErrorBubble();
          }

          // 👇 instead of "Decrypting...", return empty container to reduce flicker
          return const SizedBox.shrink();
        },
      ));
    }
    return widgets.reversed.toList();
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16), topRight: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Type a message",
                fillColor: Colors.white.withOpacity(0.4),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            color: Theme.of(context).primaryColor,
            onPressed: () {
              final message = _controller.text.trim();
              if (message.isNotEmpty) {
                sendMessage(message);
              }
            },
          ),
        ],
      ),
    );
  }
  Widget _buildErrorBubble() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text("[Decryption failed]"),
      );
}
