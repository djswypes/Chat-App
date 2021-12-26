import 'package:flutter/material.dart';
import 'package:chat_app/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore = FirebaseFirestore.instance;

class ChatScreen extends StatefulWidget {
  static const String id = 'chat_screen';

  const ChatScreen({Key? key}) : super(key: key);
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;
  late User loggedInUser;
  late String messageText;
  final textEditingController = TextEditingController();
  final _focusNode = FocusNode();

@override
  void initState() {
    getCurrentUser();
    super.initState();
  }

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser!;
      loggedInUser = user;
      print(loggedInUser.email);
    } catch (e) {
      print(e);
    }
  }

  void messagesStream() async {
    Stream<QuerySnapshot> collectionStream = _firestore.collection('messages').snapshots();
    await for (var snapshot in collectionStream) {
      for (var message in snapshot.docs) {
        print(message.data());
    }
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: const Icon(Icons.close),
              onPressed: () async{
                messagesStream();
               // await _auth.signOut();
               // Navigator.pop(context);
              }),
        ],
        title: const Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: MaterialButton(
        padding: const EdgeInsets.all(0.0),
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        onPressed: () {
          _focusNode.unfocus();
        },
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
            const MessagesStream(),
              Container(
                decoration: kMessageContainerDecoration,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        focusNode: _focusNode,
                        controller: textEditingController,
                        onChanged: (value) {
                          messageText = value;
                        },
                        decoration: kMessageTextFieldDecoration,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _firestore.collection('messages').add({
                          'text': messageText,
                          'sender': loggedInUser.email,
                        });
                        textEditingController.clear();
                      },
                      child: const Text(
                        'Send',
                        style: kSendButtonTextStyle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  const MessageBubble({Key? key, required this.sender, required this.text}) : super(key: key);
final String sender;
final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(sender, style: const TextStyle(
            fontSize: 12.0,
            color: Colors.black54
          ),),
          Material(
            borderRadius: BorderRadius.circular(30.0),
            elevation: 5.0,
            color: Colors.lightBlueAccent,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Text(
                text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),),
            ),
          ),
        ],
      ),
    );
  }
}


class MessagesStream extends StatelessWidget {
  const MessagesStream({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('messages').snapshots(),
        builder: (context, snapshot) {

          if(!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(
                  backgroundColor: Colors.lightBlueAccent,
                )
            );
          }
          final messages = snapshot.data!.docs;
          List<MessageBubble> messageBubbles = [];
          for (var message in messages) {
            final messageText = message['text'];
            final messageSender = message['sender'];
            final messageBubble =
            MessageBubble(sender: messageSender, text: messageText);
            messageBubbles.add(messageBubble);
          }
          return Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
              children:
              messageBubbles,
            ),
          );
        }
    );
  }
}
