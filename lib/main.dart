import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}

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

class MassTab extends StatefulWidget {
  final Future<Map<String, dynamic>> conversionRules;
  final String? selectedCountry;

  MassTab({required this.conversionRules, this.selectedCountry});

  @override
  _MassTabState createState() => _MassTabState();
}

class _MassTabState extends State<MassTab> {
  Map<String, double>? totalMassResults;

  static const primaryColor = const Color(0xFF002060);

  late Map<String, dynamic> conversionData;
  bool isLoading = true;
  String? error;
  List<String> coffeeForms = [''];
  List<String> massUnits = [''];

  List<String> selectedCoffeeForms = [''];
  List<String> selectedMassUnits = [''];
  List<double> enteredMasses = [0];

  double totalConvertedMass = 0;

  String selectedResultCoffeeForm = 'green';
  String selectedResultMassUnit = 'kilogram';

  @override
  void initState() {
    super.initState();
    _fetchConversionData();
  }

  @override
  void didUpdateWidget(covariant MassTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCountry != widget.selectedCountry) {
      _fetchConversionData();
    }
  }

  _fetchConversionData() async {
    try {
      final conversionRules = await widget.conversionRules;
      conversionData = widget.selectedCountry != null
          ? conversionRules[widget.selectedCountry] ?? {}
          : {};
      coffeeForms = conversionData["coffee_form_conversion"]?.keys.toList() ?? [];
      massUnits = conversionData["mass_unit_conversion"]?.keys.toList() ?? [];

      if (coffeeForms.isNotEmpty) {
        selectedCoffeeForms[0] = coffeeForms[0];
        selectedResultCoffeeForm = coffeeForms[0];
      }
      if (massUnits.isNotEmpty) {
        selectedMassUnits[0] = massUnits[0];
        selectedResultMassUnit = massUnits[0];
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  _addNewInputRow() {
    setState(() {
      selectedCoffeeForms.add(coffeeForms[0]);
      selectedMassUnits.add(massUnits[0]);
      enteredMasses.add(0);
    });
  }

  Widget _buildInputRow(int index) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Flexible(
                flex: 2,
                child: _buildDropDown(index, true),
              ),
              SizedBox(width: 8),
              Flexible(
                flex: 3,
                child: _buildTextField(index),
              ),
              SizedBox(width: 8),
              Flexible(
                flex: 2,
                child: _buildUnitDropDown(index, true),
              ),
            ],
          ),
        ),
        if (index <
            selectedCoffeeForms.length -
                1) // Only add '+' if it's not the last row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text('+',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  Widget _buildDropDown(int index, bool isExpanded) {
    return DropdownButtonFormField<String>(
      isExpanded: isExpanded,
      value: selectedCoffeeForms[index],
      items: coffeeForms.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (newValue) {
        setState(() {
          selectedCoffeeForms[index] = newValue!;
        });
      },
      decoration: InputDecoration(
        labelText: 'Coffee Form',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildUnitDropDown(int index, bool isExpanded) {
    return DropdownButtonFormField<String>(
      isExpanded: isExpanded,
      value: selectedMassUnits[index],
      items: massUnits.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (newValue) {
        setState(() {
          selectedMassUnits[index] = newValue!;
        });
      },
      decoration: InputDecoration(
        labelText: 'Unit',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildTextField(int index) {
    return TextFormField(
      keyboardType: TextInputType.number,
      onChanged: (value) {
        enteredMasses[index] = double.tryParse(value) ?? 0;
      },
      decoration: InputDecoration(
        labelText: 'Mass',
        border: OutlineInputBorder(),
      ),
    );
  }

  void _calculateTotalMass() {
    try {

      Map<String, double> totalMassesPerCoffeeForm = {};
      Map<String, double> conversionRatios = Map<String, double>.from(
          conversionData['coffee_form_conversion'] as Map);
      Map<String, double> massUnitConversion = Map<String, double>.from(
          conversionData['mass_unit_conversion'] as Map);

      for (int i = 0; i < selectedCoffeeForms.length; i++) {
        String coffeeForm = selectedCoffeeForms[i];
        double rawMass = enteredMasses[i];
        String massUnit = selectedMassUnits[i];

        // Ensure all necessary data is available and not null.
        if (conversionRatios[coffeeForm] == null ||
            massUnitConversion[massUnit] == null) {
          print(
              "Data not available for coffee form: $coffeeForm or mass unit: $massUnit");
          return;
        }

        double convertedMassToBase = rawMass * massUnitConversion[massUnit]!;
        double convertedMassToGreen =
            convertedMassToBase / conversionRatios[coffeeForm]!;

        totalMassesPerCoffeeForm.update(
            coffeeForm, (existing) => existing + convertedMassToGreen,
            ifAbsent: () => convertedMassToGreen);
      }

      setState(() {
        totalMassResults = totalMassesPerCoffeeForm;
      });
    } catch (e) {
      print("Error during mass calculation: $e");
    }
  }

  Widget _buildResultDisplay() {
    return Padding(
      padding: EdgeInsets.all(12.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isSmallScreen = constraints.maxWidth < 600;

          return Column(
            children: [
              // Dropdowns and button
              if (isSmallScreen)
                Column(children: [
                  _buildDropdown(
                    'Coffee Form',
                    selectedResultCoffeeForm,
                    coffeeForms,
                        (newValue) {
                      setState(() {
                        selectedResultCoffeeForm = newValue!;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  _buildDropdown(
                    'Unit',
                    selectedResultMassUnit,
                    massUnits,
                        (newValue) {
                      setState(() {
                        selectedResultMassUnit = newValue!;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _calculateTotalMass,
                    child: Text('Calculate Total Mass'),
                    style: ElevatedButton.styleFrom(primary: primaryColor),
                  ),
                ])
              else
                Row(children: [
                  Expanded(
                    child: _buildDropdown(
                      'Coffee Form',
                      selectedResultCoffeeForm,
                      coffeeForms,
                          (newValue) {
                        setState(() {
                          selectedResultCoffeeForm = newValue!;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdown(
                      'Unit',
                      selectedResultMassUnit,
                      massUnits,
                          (newValue) {
                        setState(() {
                          selectedResultMassUnit = newValue!;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _calculateTotalMass,
                    child: Text('Calculate Total Mass'),
                    style: ElevatedButton.styleFrom(primary: primaryColor),
                  ),
                ]),
              SizedBox(height: 20),
              // Results Display
              (totalMassResults != null && totalMassResults!.isNotEmpty)
                  ? _buildTotalResultText()
                  : Text("No results available.",
                  style: TextStyle(fontSize: 16.0)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTotalResultText() {
    double totalConvertedResult = totalMassResults!.entries.map((entry) {
      double baseMass = entry.value;
      double conversionRatio = conversionData['coffee_form_conversion']
      [selectedResultCoffeeForm] ??
          1.0;
      double unitConversion =
          conversionData['mass_unit_conversion'][selectedResultMassUnit] ?? 1.0;
      return baseMass * conversionRatio / unitConversion;
    }).reduce((value, element) => value + element);

    return Text(
      "Total ${selectedResultCoffeeForm}: ${totalConvertedResult.toStringAsFixed(2)} ${selectedResultMassUnit}",
      style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildDropdown(String label, String selectedValue, List<String> items,
      ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      items: items.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mass Conversion"),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : error != null
            ? Center(child: Text('Error: $error'))
            : SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Card(
                elevation: 5,
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      ...List.generate(
                        selectedCoffeeForms.length,
                            (index) => _buildInputRow(index),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _addNewInputRow,
                        child: Text('+ Add Another Coffee Form'),
                        style: ElevatedButton.styleFrom(
                            primary: primaryColor),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Card(
                elevation: 5,
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: _buildResultDisplay(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AreaTab extends StatefulWidget {
  final Future<Map<String, dynamic>> conversionRules;
  final String? selectedCountry;
  AreaTab({required this.conversionRules, this.selectedCountry});

  @override
  _AreaTabState createState() => _AreaTabState();
}

class _AreaTabState extends State<AreaTab> {
  static const primaryColor = const Color(0xFFFFC000);
  Map<String, double> _areaUnitConversion = {
    "hectar": 1.0,
  };

  late Map<String, dynamic> conversionData;
  List<TextEditingController> _controllers = [];
  List<String> _selectedUnits = ["hectar"];
  String _selectedResultUnit = "hectar";
  double? _convertedTotalArea;
  bool isLoading = true;
  String? error;

  _fetchConversionData() async {
    try {
      final conversionRules = await widget.conversionRules;
      conversionData = widget.selectedCountry != null
          ? conversionRules[widget.selectedCountry] ?? {}
          : {};
      _areaUnitConversion = Map<String, double>.from(conversionData) ?? {
        "hectar": 1.0,
      };

      // Reset state when selected country changes
      // _controllers.clear();
      // _selectedUnits.clear();
      // _convertedTotalArea = null;
      // _selectedResultUnit = _areaUnitConversion.keys.first;
      // _addNewInputRow();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load conversion data")));
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchConversionData();
    _addNewInputRow();
  }

  @override
  void didUpdateWidget(covariant AreaTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCountry != widget.selectedCountry) {
      setState(() {
        isLoading = true;
      });
      _fetchConversionData();
    }
  }

  void _calculateTotalArea() {
    try {
      double totalAreaInSquareMeters = 0.0;
      for (int i = 0; i < _controllers.length; i++) {
        double rawArea = double.tryParse(_controllers[i].text) ?? 0;
        String unit = _selectedUnits[i];
        totalAreaInSquareMeters += rawArea * _areaUnitConversion[unit]!;
      }

      setState(() {
        _convertedTotalArea =
            totalAreaInSquareMeters / _areaUnitConversion[_selectedResultUnit]!;
      });
    } catch (e) {
      // Handle parsing error
      print("Error during calculation: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Invalid input")));
    }
  }

  void _addNewInputRow() {
    setState(() {
      _controllers.add(TextEditingController());
      _selectedUnits.add("hectar");
    });
  }

  Widget _buildInputRow(int index) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Flexible(
              flex: 2,
              child: TextFormField(
                controller: _controllers[index],
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Area',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(width: 8),
            Flexible(
              flex: 3,
              child: DropdownButtonFormField<String>(
                value: _selectedUnits[index],
                items: _areaUnitConversion.keys.map((String unit) {
                  return DropdownMenuItem<String>(
                    value: unit,
                    child: Text(unit),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedUnits[index] = newValue!;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Unit',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
      if (index < _controllers.length - 1)  // Only add '+' if it's not the last row
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text('+', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        body: Center(
          child: Text(error!),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Area Conversion"),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Card(
                elevation: 5,
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      ...List.generate(
                        _controllers.length,
                        (index) => _buildInputRow(index),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _addNewInputRow,
                        child: Text('+ Add Another Plot'),
                        style: ElevatedButton.styleFrom(
                          primary: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Card(
                elevation: 5,
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedResultUnit,
                              items:
                                  _areaUnitConversion.keys.map((String unit) {
                                return DropdownMenuItem<String>(
                                  value: unit,
                                  child: Text(unit),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  _selectedResultUnit = newValue!;
                                });
                              },
                              decoration: InputDecoration(
                                labelText: 'Result Unit',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _calculateTotalArea,
                            child: Text('Calculate Total Area'),
                            style: ElevatedButton.styleFrom(
                              primary: primaryColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      if (_convertedTotalArea != null)
                        Text(
                          "Total Area: ${_convertedTotalArea!.toStringAsFixed(2)} $_selectedResultUnit",
                          style: TextStyle(
                              fontSize: 24.0, fontWeight: FontWeight.bold),
                        )
                      else
                        Text("Total Area will be displayed here.",
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                            )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

abstract class ConversionRepository {
  final String apiUrl;
  final String localStorageKey;
  final String assetPath;

  ConversionRepository(this.apiUrl, this.localStorageKey, this.assetPath);

  Future<Map<String, dynamic>> fetchConversionRules() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(jsonDecode(response.body));
        await _saveToLocal(data);
        return data;
      } else {
        throw Exception('Failed to load conversion rules');
      }
    } catch (e) {
      print("E: "+ e.toString());
      return await _loadFromLocalOrAssets();
    }
  }

  Future<void> _saveToLocal(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(localStorageKey, jsonEncode(data));
  }

  Future<Map<String, dynamic>> _loadFromLocalOrAssets() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString(localStorageKey);
    if (savedData != null && savedData.isNotEmpty) {
      return Map<String, dynamic>.from(jsonDecode(savedData));
    } else {
      final data = await rootBundle.loadString(assetPath);
      return Map<String, dynamic>.from(jsonDecode(data));
    }
  }
}

class CountriesRepository {
  Future<List<String>> fetchCountries() async {
    final countriesApiUrl = "https://raw.githubusercontent.com/aben-enveritas/enveritas_conversion_rules/main/countries.json";
    final response = await http.get(Uri.parse(countriesApiUrl));
    if (response.statusCode == 200) {
      List<dynamic> countriesList = jsonDecode(response.body);
      return countriesList.cast<String>();
    } else {
      throw Exception('Failed to load countries');
    }
  }
}

class MassConversionRepository extends ConversionRepository {
  MassConversionRepository()
      : super(
      "https://raw.githubusercontent.com/aben-enveritas/enveritas_conversion_rules/main/mass_conversion.json",
      "massConversion",
      'assets/mass_conversion.json');
}

class AreaConversionRepository extends ConversionRepository {
  AreaConversionRepository()
      : super(
      "https://raw.githubusercontent.com/aben-enveritas/enveritas_conversion_rules/main/area_conversion.json",
      "areaConversion",
      'assets/area_conversion.json');
}
