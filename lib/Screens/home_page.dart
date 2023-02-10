// ignore_for_file: avoid_unnecessary_containers

import 'package:avatar_glow/avatar_glow.dart';
import 'package:chatgpt_flutter/Utils/Widgets/chat_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../Helpers/api_Service.dart';
import '../Utils/Models/chat_model.dart';
import '../Utils/Widgets/input_field.dart';
import '../constants.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
//* Chat SCreen Instances

  //* loading screen
  late bool isLoading;

  var scrollController = ScrollController();

  //* list to hold all tpyes of message
  final List<ChatMessage> messages = [];

  //* text controller to enter messgae
  final TextEditingController _controller = TextEditingController();

  //* initilise loadding to false
  @override
  void initState() {
    super.initState();
    isLoading = false;
  }

  scrollMethod() {
    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

//* Audio Button
  //* var audioText
  var audioText = "  Type or Speak ";

  //* ui action bool value
  var isListening = false;

  //* object of TTS package
  SpeechToText speechToText = SpeechToText();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      //* backgroud Color
      backgroundColor: KScaffoldBackgroundColor,

      //* App bar
      appBar: AppBar(
        backgroundColor: KAppBackgroundColor,
        title: Text(
          "OpenAI  ChatGPT III",
          style: GoogleFonts.poppins(
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 5,
      ),

      //* Body
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(
              height: 10,
            ),
            Stack(
              alignment: AlignmentDirectional.center,
              children: [
                //* chat screen
                Expanded(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.97,
                    height: MediaQuery.of(context).size.height * 0.78,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(10),
                      reverse: true,
                      controller: scrollController,
                      itemCount: messages.length,
                      itemBuilder: (BuildContext context, index) {
                        var chat = messages[index];
                        return ChatBubble(
                            textMessage: chat.text.toString(),
                            messagetype: chat.type);
                      },
                    ),
                  ),
                ),

                //* loading screen
                Center(
                  child: Visibility(
                    visible: isLoading,
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            //* text field & submit method
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.99,
                height: MediaQuery.of(context).size.height * 0.09,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    //* chat field
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.60,
                      height: MediaQuery.of(context).size.height * 0.06,
                      child: MyTextField(
                        controller: _controller,
                        hintText: audioText,
                      ),
                    ),
                    //* send button
                    mySubmitButton(),

                    //* audio button
                    myMicButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //* Submit Button
  Widget mySubmitButton() {
    return Visibility(
      visible: !isLoading,
      child: Container(
          child: IconButton(
        icon: const Icon(
          Icons.send_rounded,
          color: Colors.white,
        ),
        onPressed: () {
          //* display user input
          setState(() {
            messages.insert(
              0,
              ChatMessage(text: _controller.text, type: ChatMessageType.user),
            );
            isLoading = true;
          });
          var input = _controller.text;
          _controller.clear();

          Future.delayed(const Duration(milliseconds: 50))
              .then((value) => scrollMethod());

          //* call chatbot api
          ApiService.sendMessage(input).then((value) {
            setState(() {
              isLoading = false;
              messages.insert(
                  0, ChatMessage(text: value, type: ChatMessageType.bot));
            });
          });

          //* clear controller
          _controller.clear();
          Future.delayed(const Duration(milliseconds: 50))
              .then((value) => scrollMethod());
        },
      )),
    );
  }

  //* Audio Button
  Widget myMicButton() {
    return GestureDetector(
      onTapDown: (details) async {
        HapticFeedback.vibrate();
        if (!isListening) {
          //* check if you can listen to audio -> return bool value
          bool avail = await speechToText.initialize();

          if (avail) {
            setState(() {
              isListening = true;

              //* start listening and append result to var
              speechToText.listen(onResult: (res) {
                setState(() {
                  audioText = res.recognizedWords;
                });
              });
            });
          }
        }
      },
      onTapUp: (details) async {
        HapticFeedback.vibrate();
        setState(() {
          isListening = false;
          isLoading = true;
        });

        //* stop listening once tapped away from screen
        speechToText.stop();

        //* add the recorded message to list
        messages.insert(
            0, ChatMessage(text: audioText, type: ChatMessageType.user));

        //* call api SErvice
        var msg = await ApiService.sendMessage(audioText);

        //* store bot's reply into message list
        setState(() {
          messages.insert(0, ChatMessage(text: msg, type: ChatMessageType.bot));
          isLoading = false;
        });
      },
      child: AvatarGlow(
        endRadius: 22.0,
        animate: isListening ? true : false,
        duration: const Duration(milliseconds: 2000),
        repeat: true,
        glowColor: Colors.white30,
        showTwoGlows: true,
        child: Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            color: Colors.white30,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(
            isListening ? Icons.mic : Icons.mic_off,
            color: Colors.black,
            size: 30,
          ),
        ),
      ),
    );
  }
}
