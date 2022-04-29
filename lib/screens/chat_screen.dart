
import 'package:flutter/material.dart';
import 'package:flash_chat_flutter/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore = FirebaseFirestore.instance;
User? user;
class ChatScreen extends StatefulWidget {

  static const String id = 'chat_screen';


  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  final messageTextController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  String messageText = '';


  void getCurrentUser() async{
    user = await _auth.currentUser;
    if(user != null){
    print(user?.email);
    }
  }
  
  /*void getMessages()async{
    final messages = await _firestore.collection('messages').get();
    for(var message in messages.docs){
      print(message.data());
    }

  }*/

  void messagesStream() async{
    //con snapshot ascolto le modifiche della mia raccolta appena avviene un cambiamento nel database.
    await for(var snapshot in _firestore.collection('messages').snapshots()){
      for(var message in snapshot.docs){
        print(message.data());
      }
    }
  }

  @override
  void initState() {
    getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                //getMessages(); <- per stampare
                //messagesStream();
                //Implement logout functionality
                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessagesStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        //Do something with the user input.
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      //quando invia il messaggio pulisce la TextField
                      messageTextController.clear();
                      //Implement send functionality.
                      //messageText + user.email
                      _firestore.collection('messages').add({
                        'text': messageText,
                        'sender': user?.email,
                      });
                    },
                    child: Text(
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
    );
  }
}

class MessagesStream extends StatelessWidget {


  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('messages').snapshots(),
      builder: (context, snapshot){
        if(snapshot.hasData){
          final messages = snapshot.data?.docs.reversed;
          List<MessageBubble> messageBubbles = [];
          for(var message in messages!){
            final messageText = message.get('text');
            final messageSender = message.get('sender');

            final currentUser = user?.email;

            final messageBubbler = MessageBubble(sender: messageSender, text: messageText, isMe:  currentUser == messageSender,);

            messageBubbles.add(messageBubbler);
          }
          return Expanded(
            child: ListView(
              reverse: true,
              padding: EdgeInsets.symmetric(horizontal: 10.0,vertical: 20.0),
              children: messageBubbles,
            ),
          );
        }else{
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.lightBlueAccent,
            ),
          );
        }
      },
    );
  }
}


class MessageBubble extends StatelessWidget {
  MessageBubble({required this.sender,required this.text, required this.isMe});

  final String sender;
  final String text;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(sender,style: TextStyle(
            fontSize: 12.0,
            color: Colors.white70,
          ),),
          Material(
            borderRadius: isMe ? BorderRadius.only(
                topLeft: Radius.circular(30.0),
                bottomLeft: Radius.circular(30.0),
                bottomRight: Radius.circular(30.0))
                : BorderRadius.only(
                topRight: Radius.circular(30.0),
                bottomLeft: Radius.circular(30.0),
                bottomRight: Radius.circular(30.0)) ,
            elevation: 5.0,
            color: isMe ? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0,horizontal: 20.0),
              child: Text(text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.red,
                  fontSize: 15.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
