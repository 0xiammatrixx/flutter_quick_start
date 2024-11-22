// lib/widgets/reply_notification.dart
import 'package:flutter/material.dart';

class ReplyNotification extends StatefulWidget {
  final String avatarUrl;
  final String personName;
  final String timeAgo;
  final VoidCallback onReplyTap;

  const ReplyNotification({
    super.key,
    required this.avatarUrl,
    required this.personName,
    required this.timeAgo,
    required this.onReplyTap,
  });

  @override
  _ReplyNotificationState createState() => _ReplyNotificationState();
}

class _ReplyNotificationState extends State<ReplyNotification> {
  bool _isVisible = true;

  void _dismissNotification() {
    setState(() {
      _isVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundImage: AssetImage(widget.avatarUrl),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.black),
                          children: [
                            TextSpan(
                              text: '${widget.personName} ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: 'seems to be waiting for a reply to your message since ${widget.timeAgo}',
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      iconSize: 20,
                      onPressed: _dismissNotification,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ElevatedButton(
                  onPressed: widget.onReplyTap,
                  child: const Text('Reply Now'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}