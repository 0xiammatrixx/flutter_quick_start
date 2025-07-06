import 'package:arbichat/chatpage/model/minimal_message.dart';
import 'package:arbichat/on_chain/widget/encrypt.dart';
import 'package:arbichat/on_chain/widget/message_storage_service.dart';
import 'package:arbichat/on_chain/widget/pinata_ipfs.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:arbichat/chatpage/model/chat_model.dart';
import 'package:arbichat/chatpage/model/message_model.dart';
import 'package:arbichat/chatpage/widgets/chat_widget.dart';
import 'package:arbichat/chatpage/widgets/search_bar.dart';
import 'package:arbichat/profilepage/page/profile_page.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'message_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart' as web3dart;

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  final FocusNode _searchFocusNode = FocusNode();
  List<ChatTiles> chats = []; // Initialize an empty list of chats
  bool loading = true;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? userWalletAddress;
  var ipfsService = IpfsService(
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySW5mb3JtYXRpb24iOnsiaWQiOiI2MjFhY2UwOS1mMGNiLTQzMjYtYTZkNS0zYjljNmYwZDdmYTAiLCJlbWFpbCI6ImNvZGVkbWF0cml4bG9sQGdtYWlsLmNvbSIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJwaW5fcG9saWN5Ijp7InJlZ2lvbnMiOlt7ImRlc2lyZWRSZXBsaWNhdGlvbkNvdW50IjoxLCJpZCI6IkZSQTEifSx7ImRlc2lyZWRSZXBsaWNhdGlvbkNvdW50IjoxLCJpZCI6Ik5ZQzEifV0sInZlcnNpb24iOjF9LCJtZmFfZW5hYmxlZCI6ZmFsc2UsInN0YXR1cyI6IkFDVElWRSJ9LCJhdXRoZW50aWNhdGlvblR5cGUiOiJzY29wZWRLZXkiLCJzY29wZWRLZXlLZXkiOiI2YzVhMTMwOTZhNTc5YWY0MzJlYyIsInNjb3BlZEtleVNlY3JldCI6ImQ0NTllNTI2NWI1OWQ0NmI3MDEwNjQzYmJlNmM2MjBjODMzNjZiNGU0NWFjMTkyNGE4NDczZmQ1OGNjMTQxODYiLCJleHAiOjE3ODAyODY2NTh9.QiFDw0xZSgr2BCqZgPNYmAAKAMt5RP9nJgJPqvCaoA4');

  @override
  void initState() {
    super.initState();
    print("initState called");
    _setupAndLoadChats();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _setupAndLoadChats() async {
    print("Loading on-chain chats...");
    final prefs = await SharedPreferences.getInstance();
    final privateKey = prefs.getString('privateKey');

    if (privateKey == null) {
      print("Private key not found.");
      return;
    }

    final credentials = web3dart.EthPrivateKey.fromHex(privateKey);
    final ownAddress = await credentials.extractAddress();
    userWalletAddress = ownAddress.hex.toLowerCase();
    print("Current wallet address: $userWalletAddress");

    // Initialize client
    final client = web3dart.Web3Client(
      'https://sepolia-rollup.arbitrum.io/rpc',
      Client(),
    );

    // Load contract ABI and address
    final abi =
        await rootBundle.loadString('assets/new_message_storage_abi.json');
    final contract = web3dart.DeployedContract(
      web3dart.ContractAbi.fromJson(abi, 'MessageContract'),
      web3dart.EthereumAddress.fromHex(
          '0x57b56bf9ed5a655074f3233fb6127945bdf743f7'),
    );

    final messageStorageService = MessageStorageService(
      client: client,
      contract: contract,
      ownAddress: ownAddress,
      credentials: credentials,
    );

    List<ChatTiles> tempChats = [];

    final firebaseUsers = await _firestore.collection('users').get();
    print("Fetched ${firebaseUsers.docs.length} Firebase users");

    for (var doc in firebaseUsers.docs) {
      String otherWalletAddress = doc.id.toLowerCase();

      if (otherWalletAddress == userWalletAddress) continue;

      // Fetch on-chain messages
      final otherAddress =
          web3dart.EthereumAddress.fromHex(otherWalletAddress.toLowerCase());

      List<ChatMessage> messages = [];

      try {
        final fetchedRaw = await messageStorageService.getMessagesFromLogs(
        userA: ownAddress,
        userB: otherAddress,
      );

      final fetchedMessages = fetchedRaw.map((msgMap) => ChatMessage.fromMap(msgMap)).toList();
        messages = fetchedMessages;
      } catch (e) {
        print("Failed to fetch messages from logs for $otherWalletAddress: $e");
        continue;
      }

      if (messages.isEmpty) continue;

      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final lastMessage = messages.first;

      // Decrypt message from IPFS
      final encryptedContent = await ipfsService.fetchFromIPFS(lastMessage.cid);
      final decryptedMessage = SimpleEncryptor.decrypt(encryptedContent);

      // Get profile info (avatar etc.)
      final userProfileSnapshot =
          await _firestore.collection('users').doc(otherWalletAddress).get();
      String avatarUrl = 'assets/profileplaceholder.png';
      UserProfile userProfile;

      if (userProfileSnapshot.exists) {
        final userData = userProfileSnapshot.data()!;
        avatarUrl = userData['avatarUrl'] ?? avatarUrl;
        userProfile = UserProfile.fromMap(userData);
      } else {
        userProfile = UserProfile(
            walletAddress: otherWalletAddress,
            name: otherWalletAddress,
            interactionScore: 0,
            walletBalance: 0.0);
      }

      final previewMessage = Message(
        senderAddress: lastMessage.sender.hexEip55,
        messageContent: decryptedMessage,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
            lastMessage.timestamp.toInt() * 1000),
        isSentByUser: lastMessage.sender.hex.toLowerCase() == userWalletAddress,
      );

      tempChats.add(ChatTiles(
        userProfile: userProfile,
        message: previewMessage,
        avatarUrl: avatarUrl,
        timestamp: previewMessage.timestamp,
        isSentByUser: previewMessage.isSentByUser,
      ));
    }

    setState(() {
      chats = tempChats;
      loading = false;
    });
  }

  void addNewChat(UserProfile userProfile, ChatMessage message) async {
    // Check if a chat with the given userProfile already exists
    bool chatExists = chats.any(
        (chat) => chat.userProfile.walletAddress == userProfile.walletAddress);

    if (chatExists) {
      // If the chat exists, open it instead of creating a new one
      // Find the index of the existing chat
      int chatIndex = chats.indexWhere((chat) =>
          chat.userProfile.walletAddress == userProfile.walletAddress);

      // Open the existing chat (navigate to MessagingPage)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MessageTestPage(
            userProfile: chats[chatIndex].userProfile,
          ),
        ),
      );
    } else {
      // Try to fetch avatar from Firestore as fallback
      String avatarUrl = 'assets/profileplaceholder.png'; // default
      final userProfileSnapshot = await _firestore
          .collection('users')
          .doc(userProfile.walletAddress)
          .get();

      if (userProfileSnapshot.exists) {
        final data = userProfileSnapshot.data();
        avatarUrl = data?['avatarUrl'] ?? avatarUrl;
      }

      final decrypted = message.plaintext ?? 'Start chatting';
      final msgTimestamp =
          DateTime.fromMillisecondsSinceEpoch(message.timestamp.toInt() * 1000);

      final previewMessage = Message(
        senderAddress: message.sender.hexEip55,
        messageContent: decrypted,
        timestamp: msgTimestamp,
        isSentByUser: message.sender.hexEip55 == userWalletAddress,
      );

      // Create a ChatTiles (or Chat, depending)
      final chatTile = ChatTiles(
        message: previewMessage,
        userProfile: userProfile,
        avatarUrl: avatarUrl,
        timestamp: msgTimestamp,
        isSentByUser: message.sender.hexEip55 == userWalletAddress,
      );

      setState(() {
        chats.add(chatTile);
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MessageTestPage(
            userProfile: userProfile,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
        ),
        actions: <Widget>[
          IconButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfilePage()));
              },
              icon: const Icon(Icons.person))
        ],
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Column(
            children: [
              SearchBarWidget(
                onAddressVerified: addNewChat,
              ),
              SizedBox(height: screenHeight * 0.01),
              const Divider(),
              Expanded(
                child: loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.black,
                        ),
                      )
                    : chats.isEmpty
                        ? const Center(
                            child: Text(
                              "No messages yet",
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: chats.length,
                            itemBuilder: (context, index) {
                              return ChatTile(
                                chat: chats[index],
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => MessageTestPage(
                                                userProfile:
                                                    chats[index].userProfile,
                                              )));
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
