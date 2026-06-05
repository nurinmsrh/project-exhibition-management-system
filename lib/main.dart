import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'features/auth/providers/auth_provider.dart';
import 'features/exhibitor/providers/exhibitor_provider.dart';
import 'routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyArWC-a-Duar5WzCyhuPdedV_tpCq2d5PU",
        appId: "1:443376882672:android:e762db6319b5499a53c335",
        messagingSenderId: "443376882672",
        projectId: "exhibition-management-sy-a3cf1",
        storageBucket: "exhibition-management-sy-a3cf1.appspot.com",
      ),
    );

    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (e) {
    // Firebase already initialized
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..loadUser(),
        ),

        ChangeNotifierProvider(
          create: (_) => ExhibitorProvider(),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final router = createRouter(authProvider);

          return MaterialApp.router(
            title: 'Exhibition Management System',
            debugShowCheckedModeBanner: false,
            routerConfig: router,
          );
        },
      ),
    );
  }
}