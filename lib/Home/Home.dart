import 'package:enveritas_converter/Repository/AreaConversionRepository.dart';
import 'package:enveritas_converter/Repository/CountriesRepository.dart';
import 'package:enveritas_converter/Repository/MassConversionRepository.dart';
import 'package:enveritas_converter/Tabs/AreaTab.dart';
import 'package:enveritas_converter/Tabs/MassTab.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<String>> countries;
  late Future<Map<String, dynamic>> massConversionRules;
  late Future<Map<String, dynamic>> areaConversionRules;
  String? selectedCountry = "Ethiopia";
  final primaryColor = Color(0xFF002060);
  final countriesRepo = CountriesRepository();
  final massConversionRepo = MassConversionRepository();
  final areaConversionRepo = AreaConversionRepository();

  @override
  void initState() {
    super.initState();
    countries = countriesRepo.fetchCountries();
    _fetchConversionRules();

  }

  Widget _buildDropdown() {
    return FutureBuilder<List<String>>(
      future: countries,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Text("Error");
          }
          final items = snapshot.data!.map((String country) {
            return DropdownMenuItem<String>(
              value: country,
              child: Text(
                country,
                style: TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis, // Use ellipsis for overflow
              ),
            );
          }).toList();

          return Theme(
            data: Theme.of(context).copyWith(
              canvasColor: primaryColor,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true, // Expands the dropdown to the maximum width
                value: selectedCountry,
                items: items,
                onChanged: (newValue) {
                  setState(() {
                    selectedCountry = newValue!;
                    _fetchConversionRules();
                  });
                },
                hint: Text(
                  "Select Country",
                  style: TextStyle(color: Colors.white),
                ),
                iconEnabledColor: Colors.white,
              ),
            ),
          );
        } else {
          return CircularProgressIndicator();
        }
      },
    );
  }

  _fetchConversionRules() {
    massConversionRules = massConversionRepo.fetchConversionRules();
    areaConversionRules = areaConversionRepo.fetchConversionRules();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Enveritas Unit Converter"),
          backgroundColor: primaryColor,
          actions: [
            Container(
              width: 100, // Fixed width for the dropdown
              child: _buildDropdown(),
            ),
            SizedBox(width: 16),],
          bottom: TabBar(tabs: [Tab(text: 'Mass'), Tab(text: 'Area')]),
        ),
        body: TabBarView(
            children: [
              MassTab(conversionRules: massConversionRules, selectedCountry : selectedCountry,),
              AreaTab(conversionRules: areaConversionRules, selectedCountry: selectedCountry,)
            ]),
      ),
    );
  }
}