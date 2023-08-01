import 'package:flutter/material.dart';
import 'package:gptbrycen/chat_screen.dart';
import 'package:gptbrycen/summarize.dart';
import 'package:flutter_snake_navigationbar/flutter_snake_navigationbar.dart';

class TabsScreen extends StatefulWidget {
  const TabsScreen({super.key});
  @override
  State<TabsScreen> createState() {
    return _TabsScreenState();
  }
}

class _TabsScreenState extends State<TabsScreen> {
  int _selectedPageIndex = 0;

  void _selectPage(int index) {
    setState(() {
      _selectedPageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget activePage = const ChatScreen();
    bool checkIcon = false;

    if (_selectedPageIndex == 1) {
      activePage = const summarize();
      checkIcon = true;
    }
    return Scaffold(
        body: activePage,
        bottomNavigationBar: SnakeNavigationBar.color(
          snakeShape: SnakeShape.indicator,
          snakeViewColor: Colors.white,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey,
          backgroundColor: const Color(0xFF343541),
          onTap: _selectPage,
          currentIndex: _selectedPageIndex,
          items: [
            BottomNavigationBarItem(
              icon: Icon(checkIcon ? Icons.chat_outlined : Icons.chat),
            ),
            BottomNavigationBarItem(
              icon:
                  Icon(checkIcon ? Icons.summarize : Icons.summarize_outlined),
            ),
          ],
        ));
  }
}
