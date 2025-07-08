import 'dart:convert';
import 'package:arbichat/chatpage/model/message_model.dart';
import 'package:arbichat/chatpage/widgets/ui_updates.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
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
  final ScrollController _scrollController = ScrollController();
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
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _scrollToBottomAnimated());
    print("Chatting with: ${widget.userProfile.name}");
  }

  void _scrollToBottomAnimated() {
  if (_scrollController.hasClients) {
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  } else {
    // Not attached yet, try again next frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottomAnimated());
  }
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

    final messageBox = await Hive.openBox<ChatMessage>('chat_messages_$ownAddress');

    messageStorageService = MessageStorageService(
      client: client,
      contract: contract,
      ownAddress: ownAddress,
      credentials: credentials,
    );

    ipfsService = IpfsService(
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySW5mb3JtYXRpb24iOnsiaWQiOiI2MjFhY2UwOS1mMGNiLTQzMjYtYTZkNS0zYjljNmYwZDdmYTAiLCJlbWFpbCI6ImNvZGVkbWF0cml4bG9sQGdtYWlsLmNvbSIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJwaW5fcG9saWN5Ijp7InJlZ2lvbnMiOlt7ImRlc2lyZWRSZXBsaWNhdGlvbkNvdW50IjoxLCJpZCI6IkZSQTEifSx7ImRlc2lyZWRSZXBsaWNhdGlvbkNvdW50IjoxLCJpZCI6Ik5ZQzEifV0sInZlcnNpb24iOjF9LCJtZmFfZW5hYmxlZCI6ZmFsc2UsInN0YXR1cyI6IkFDVElWRSJ9LCJhdXRoZW50aWNhdGlvblR5cGUiOiJzY29wZWRLZXkiLCJzY29wZWRLZXlLZXkiOiI2YzVhMTMwOTZhNTc5YWY0MzJlYyIsInNjb3BlZEtleVNlY3JldCI6ImQ0NTllNTI2NWI1OWQ0NmI3MDEwNjQzYmJlNmM2MjBjODMzNjZiNGU0NWFjMTkyNGE4NDczZmQ1OGNjMTQxODYiLCJleHAiOjE3ODAyODY2NTh9.QiFDw0xZSgr2BCqZgPNYmAAKAMt5RP9nJgJPqvCaoA4');

    final storedMap = messageBox.toMap().cast<String, ChatMessage>();
    final stored = storedMap.values
        .where((msg) =>
            (msg.senderHex == ownAddress.hex.toLowerCase() &&
                msg.receiverHex ==
                    widget.userProfile.walletAddress.toLowerCase()) ||
            (msg.receiverHex == ownAddress.hex.toLowerCase() &&
                msg.senderHex ==
                    widget.userProfile.walletAddress.toLowerCase()))
        .toList();

    stored.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          messages = stored;
        });
        _scrollToBottomAnimated();
      }
    });

    await prefetchDecryptMessages(stored);

    final refreshed = messageBox.values
        .where((msg) =>
            (msg.senderHex == ownAddress.hex.toLowerCase() &&
                msg.receiverHex ==
                    widget.userProfile.walletAddress.toLowerCase()) ||
            (msg.receiverHex == ownAddress.hex.toLowerCase() &&
                msg.senderHex ==
                    widget.userProfile.walletAddress.toLowerCase()))
        .toList();

    refreshed.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          messages = refreshed;
        });
        _scrollToBottomAnimated();
      }
    });

    await fetchLatestMessages();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          status = 'Setup complete';
        });
      }
    });
  }

  Future<void> prefetchDecryptMessages(List<ChatMessage> msgs) async {
    final messageBox = Hive.box<ChatMessage>('chat_messages_$ownAddress');

    for (int i = 0; i < msgs.length; i++) {
      final msg = msgs[i];

      if (msg.cid == '__pending__') continue;
      if (msg.plaintext != null) {
        _decryptedCache[msg.cid] = msg.plaintext!;
        continue;
      }

      try {
        final encrypted = await ipfsService.fetchFromIPFS(msg.cid);
        final decrypted = SimpleEncryptor.decrypt(encrypted);
        _decryptedCache[msg.cid] = decrypted;

        final updated = msg.copyWith(plaintext: decrypted);
        await messageBox.put(msg.cid, updated); // update in Hive
        msgs[i] = updated;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      } catch (e) {
        _decryptedCache[msg.cid] = "[Decryption failed]";

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      }
    }
  }

  Future<void> sendMessage(String message) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final receiver =
        EthereumAddress.fromHex(widget.userProfile.walletAddress.toLowerCase());

    final encryptedMessage = SimpleEncryptor.encrypt(message);
    Uint8List bytes = Uint8List.fromList(utf8.encode(encryptedMessage));

    // Optimistic UI update
    final tempMsg = ChatMessage.fromTypes(
      sender: ownAddress,
      receiver: receiver,
      cid: '__pending__',
      timestamp: BigInt.from(timestamp),
      deleted: false,
      plaintext: message,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => messages.add(tempMsg));
    });

    _scrollToBottomAnimated();

    try {
      final cid = await ipfsService.uploadToPinata(bytes, 'message.txt');
      if (cid == null) return;

      await messageStorageService.sendMessage(receiver.hex, cid);

      final updatedMsg = tempMsg.copyWith(cid: cid);
      final messageBox = Hive.box<ChatMessage>('chat_messages_$ownAddress');
      await messageBox.put(updatedMsg.cid, updatedMsg);

      if (!mounted) return;
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

  Future<void> fetchLatestMessages() async {
    try {
      final otherAddress = EthereumAddress.fromHex(
          widget.userProfile.walletAddress.toLowerCase());

      final fetchedRaw = await messageStorageService.getMessagesFromLogs(
        userA: ownAddress,
        userB: otherAddress,
      );

      final fetchedMessages =
          fetchedRaw.map((msgMap) => ChatMessage.fromMap(msgMap)).toList();

      final messageBox = Hive.box<ChatMessage>('chat_messages_$ownAddress');

      for (final msg in fetchedMessages) {
        final existing = messageBox.get(msg.cid);

        if (existing == null) {
          await messageBox.put(msg.cid, msg);
        } else {
          // If one has no plaintext and the other does, preserve it
          final merged = msg.plaintext == null && existing.plaintext != null
              ? msg.copyWith(plaintext: existing.plaintext)
              : msg;
          await messageBox.put(msg.cid, merged);
        }
      }

      final storedMap = messageBox.toMap().cast<String, ChatMessage>();
      final convoMessages = storedMap.values
          .where((msg) =>
              (msg.senderHex == ownAddress.hex.toLowerCase() &&
                  msg.receiverHex ==
                      widget.userProfile.walletAddress.toLowerCase()) ||
              (msg.receiverHex == ownAddress.hex.toLowerCase() &&
                  msg.senderHex ==
                      widget.userProfile.walletAddress.toLowerCase()))
          .toList();

      convoMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            messages = convoMessages;
          });
          _scrollToBottomAnimated();
        }
      });

      await prefetchDecryptMessages(messages);
    } catch (e) {
      print("Fetch error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    var bgcol = const Color.fromARGB(255, 235, 235, 235).withOpacity(1);
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
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    children: _buildMessageList(),
                  ),
          ),
          const Divider(height: 1, color: Colors.white,),
          _buildInputArea(),
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

      if (msg.plaintext != null) {
        widgets.add(ChatBubble(
          isMe: isMe,
          message: msg.plaintext!,
          timestamp: msgDate,
        ));
        continue;
      }

      if (msg.cid == '__pending__' && msg.plaintext != null) {
        widgets.add(ChatBubble(
          isMe: isMe,
          message: msg.plaintext ?? '[Pending...]',
          timestamp: msgDate,
        ));
        continue;
      }

      if (_decryptedCache.containsKey(msg.cid)) {
        widgets.add(ChatBubble(
          isMe: isMe,
          message: _decryptedCache[msg.cid]!,
          timestamp: msgDate,
        ));
        continue;
      }
      widgets.add(ChatBubble(
        isMe: isMe,
        message: '[Loading...]',
        timestamp: msgDate,
      ));
    }
    return widgets;
  }

  Widget _buildInputArea() {
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      height: screenHeight * 0.1,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: "Type a message",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.black,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () {
                final message = _controller.text.trim();
                if (message.isNotEmpty) {
                  sendMessage(message);
                  _controller.clear();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
