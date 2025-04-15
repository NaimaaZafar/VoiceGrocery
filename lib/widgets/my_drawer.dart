import 'package:flutter/material.dart';
import 'package:fyp/screens/settings.dart';
import 'package:fyp/screens/logout.dart';
import 'package:fyp/widgets/my_drawer_tile.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10.0),
      child: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 100),
              child: Icon(
                Icons.lock_open,
                size: 25,
                color: Colors.black,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Divider(
                color: Colors.grey,
              ),
            ),
            MyDrawerTile(text: 'H O M E', icon: Icons.home, onTap: () => Navigator.pop(context)),
            MyDrawerTile(text: 'S E T T I N G S', icon: Icons.settings, onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen(),));
            }),
            const Spacer(),
            MyDrawerTile(text: 'L O G O U T', icon: Icons.logout, onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const LogoutPage()));
            }),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}