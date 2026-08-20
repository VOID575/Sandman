import 'package:flutter/material.dart';
import 'package:flutter_side_menu/flutter_side_menu.dart';

// TODO : faire un fichier par composant
void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = true;

  void _toggleTheme(bool value) {
    setState(() {
      _isDarkMode = value;
    });
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sandman',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: .fromSeed(
            seedColor: Colors.blue,
            brightness: _isDarkMode ? Brightness.dark : Brightness.light,
        ),
      ),
      home: HomePage(
          title: 'Sandman',
          isDarkMode: _isDarkMode,
          onThemeChanged: _toggleTheme
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final String title;
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const HomePage({
    super.key,
    required this.title,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".


  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _counter = 0;
  bool _isMenuOpen = false;

  void _toggleSettingsMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  // "_" when argument is private
  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    const double settingsMenuWidth = 250;

    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(onPressed: _toggleSettingsMenu, icon: Icon(Icons.settings))
        ],
      ),
      body: Stack(
        children: [
          Center(
            // Center is a layout widget. It takes a single child and positions it
            // in the middle of the parent.
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,

              children: [Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                // Column is also a layout widget. It takes a list of children and
                // arranges them vertically. By default, it sizes itself to fit its
                // children horizontally, and tries to be as tall as its parent.
                //
                // Column has various properties to control how it sizes itself and
                // how it positions its children. Here we use mainAxisAlignment to
                // center the children vertically; the main axis here is the vertical
                // axis because Columns are vertical (the cross axis would be
                // horizontal).
                //
                // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
                // action in the IDE, or press "p" in the console), to see the
                // wireframe for each widget.

                children: [
                  const Text('You have pushed the button this many times:'),
                  Text(
                    '$_counter',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    '$_counter',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 30),

                  const MonBoutonPersonnalise(),
                ],
              ),
              ],
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            right: _isMenuOpen ? 0 : -settingsMenuWidth,
            top: 0,
            bottom: 0,
            width: settingsMenuWidth,
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                  children: [
                    Row(
                      children: [
                        const Align(
                            alignment: Alignment.topLeft,
                            child: Text('Settings'),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Align(
                            alignment: Alignment.topLeft,
                            child: Text('Dark mode')
                        ),
                        Switch(
                          value: widget.isDarkMode,
                          onChanged: widget.onThemeChanged,
                        )
                      ],
                    )
                ,]
              ),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(
            Icons.add,
            color: Theme.of(context).colorScheme.onSurface,
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
    );
  }
}

class MonBoutonPersonnalise extends StatelessWidget {
  const MonBoutonPersonnalise({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print('MyButton was tapped!');
      },
      child: Container(
        height: 50,
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Colors.lightGreen[500],
        ),
        child: const Center(child: Text('Engage')),
      ),
    );
  }
}