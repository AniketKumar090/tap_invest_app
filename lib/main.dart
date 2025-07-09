import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'search_bloc.dart';
import 'repository.dart';
import 'search_screen.dart';
import 'company_details_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tap Invest App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: BlocProvider(
        create: (context) => SearchBloc(TapInvestRepository()),
        child: SearchScreen(),
      ),
      debugShowCheckedModeBanner: false,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/company-details':
            return MaterialPageRoute(
              builder: (context) => BlocProvider.value(
                value: context.read<SearchBloc>(),
                child: CompanyDetailsScreen(),
              ),
            );
          default:
            return MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => SearchBloc(TapInvestRepository()),
                child: SearchScreen(),
              ),
            );
        }
      },
    );
  }
}