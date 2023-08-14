# BrycenChatApp


<div style="display: flex;">
  <div style="flex: 1;">
    <a href="https://github.co/Shu-Keit">
      <img src="https://github.com/Shu-Kei/gptbrycen/assets/125178921/bf31083d-52a7-453b-b764-877a30c9b9f8"
 width="150"/>
    </a>
  </div>
  
  <div style="flex: 2;">
    <p>Meet BrycenChat - the Dart-powered chatbot app that revolutionizes how you communicate. Enjoy natural conversations and personalized responses, all while accessing quick information and concise summaries. Download now and experience the future of interactive chatbots!</p>
  </div>
</div>

## Features

* Chat with AI: Enjoy dynamic conversations with our AI chatbot, with Speech-to-Text and Text-to-Speech features.
* Summarize Content: Extract key information from audio, text, and PDF files effortlessly.

## Screens

| Home                                         | Chat                                         | Tab                                          | Summarize                                    |
|----------------------------------------------|----------------------------------------------|----------------------------------------------|----------------------------------------------|
|![Home UI](https://github.com/Shu-Kei/gptbrycen/assets/125178921/12d839bd-1763-45cd-9ac5-c53d146b7bd4)|![Chat UI](https://github.com/Shu-Kei/gptbrycen/assets/125178921/74df9314-e714-467c-b006-06664914043d)|![Tab UI](https://github.com/Shu-Kei/gptbrycen/assets/125178921/a25d9df1-5320-41a5-a733-2dd47410cbc3)|![Summarize UI](https://github.com/Shu-Kei/gptbrycen/assets/125178921/69724eee-b4af-4291-99e2-1a308ca1fbaa)|









# HOW TO RUN THIS APP 

## If you want to use the APK to install on your phone, please run the following command:

You can download the APK file from the releases section of this repository or build the app from source using the
instructions below:

```bash
git clone https://github.com/Shu-Kei/gptbrycen.git
cd gptbrycen
flutter build apk
````
## If you want to run the project, please follow the steps below:

### 1. Firebase setup
- 1.Access [Firebase](https://firebase.google.com/) and log in to your Google account.
  
- 2.Click on 'Get Started' and begin creating the project.

![create project](https://github.com/Shu-Kei/gptbrycen/assets/125178921/40cf2b56-a0f7-479e-99f6-470a5825edad)
  
- 3.Initialize Cloud Firestore in Firebase.

![video (1)](https://github.com/Shu-Kei/gptbrycen/assets/125178921/27796124-861e-4fdb-bd76-56f137733fa5)

  
- 4.Create the following value variables in Cloud Firestore for use in the app.
  
![image](https://github.com/Shu-Kei/gptbrycen/assets/125178921/ba5f031e-b44a-42e2-ac17-01520f418d7f)




### 2. Clone this github repository app

- Open a folder in your computer that you want to add this app.
- Open git (in step 2), then type:

```bash
git clone https://github.com/Shu-Kei/gptbrycen.git
```
- Open your project terminal, then type:

```bash
flutter pub get
```

### 3. Setup flutterfire 🔥
#### Step 1: Install the required command line tools

1. If you haven't already, you can follow the steps below:

- 1.Download [Node.js](https://nodejs.org/en/download) and install it on your computer.
- 2.Open the terminal and type the following command to install the Firebase CLI:

```bash
npm install -g firebase-tools
```

2. Log into Firebase using your Google account by running the following command:

```bash
firebase login
```

3. Install the FlutterFire CLI by running the following command from any directory:

```bash
dart pub global activate flutterfire_cli
```

#### Step 2: Configure your apps to use Firebase

Use the FlutterFire CLI to configure your Flutter apps to connect to Firebase.
From your Flutter project directory, run the following command to start the app configuration workflow:

```bash
flutterfire configure
```

#### Step 3: Initialize Firebase in your app

1.From your Flutter project directory, run the following command to install the core plugin:
   
```bash
flutter pub add firebase_core
```

```bash
flutter pub add cloud_firestore
```

2.From your Flutter project directory, run the following command to ensure that your Flutter app's Firebase configuration is up-to-date:

```bash
flutterfire configure
```

# Usage

Enter your ChatGPT API key to log in to the Chat Screen.
Access the chatbot for interactive conversations.
Switch to the "Summarize" screen to summarize content.
Upload audio, text, or PDF files for quick summaries.

# Acknowledgements

BrycenChat was built using the following open-source libraries and tools:

* [Flutter](https://flutter.dev/)
* [Dart](https://dart.dev/)
* [OpenAI GPT](https://beta.openai.com/)
* [Google Fonts](https://fonts.google.com/)

# Update
* 24/07/2023: Started developing the Chat app using Flutter Dart. Completed the initial version of the chat feature with AI integration. The app now allows users to chat with the AI-powered chatbot, providing dynamic and interactive conversations.

* 27/07/2023: Implemented essential updates to the app. Added the much-awaited Text-to-Speech and Speech-to-Text functionalities to enhance the chat with AI experience. Users can now use voice commands to communicate with the chatbot, making interactions more convenient and hands-free.Added content summarization with file upload from Android devices.

* 30/07/2023: Latest update brings a refreshed chat interface with added Markdown support for AI messages. Now, the AI can send messages in Markdown format for enhanced formatting options. Additionally, the chat now features a background Markdown code block, capable of detecting and displaying programming language syntax for a better coding experience.

* 01/08/2023: Another exciting update is here! Introducing the new feature that allows users to summarize content within TXT files. Now, users can effortlessly import TXT files from their phones and ask the AI any questions related to the file's content.

* 05/08/2023: Add PDF reading functionality to the 'Summarize'.

* 09/08/2023: Successfully solve the issue of extracting content from audio files.

* 10/08/2023: Successfully summarize an audio file. Integrate a feature to suggest questions related to the content of the file.
  
* 12/08/2023: Detect an issue of content being too long, which exceeds the summarization model's limitations, preventing the summarization of the content in the file.

* 13/08/2023: Successfully resolve the issue of excessively long text by segmenting the text into smaller parts for embedding by the model.

* 14/08/2023: Refine the app, removing any redundant lines of code.
