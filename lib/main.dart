import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
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
  late Future<Map<String, dynamic>> conversionRules;

  @override
  void initState() {
    super.initState();
    conversionRules =
        ConversionRepository().fetchMassConversionRules();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Enveritas Unit Converter"),
          backgroundColor: Color(0xFF002060),
          bottom: TabBar(tabs: [Tab(text: 'Mass'), Tab(text: 'Area')]),
        ),
        body: TabBarView(
            children: [MassTab(conversionRules: conversionRules), AreaTab()]),
      ),
    );
  }
}

class MassTab extends StatefulWidget {
  final Future<Map<String, dynamic>> conversionRules;


  MassTab({required this.conversionRules});

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

  _fetchConversionData() async {
    try {
      conversionData = await widget.conversionRules;
      coffeeForms = conversionData["coffee_form_conversion"].keys.toList();
      massUnits = conversionData["mass_unit_conversion"].keys.toList();
      if (coffeeForms.isNotEmpty) {
        selectedCoffeeForms[0] = coffeeForms[0];
        selectedResultCoffeeForm = coffeeForms[0];
      }
      if (massUnits.isNotEmpty){
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
    return LayoutBuilder(
      builder: (context, constraints) {
        // Check if the smallest side of the screen is less than a certain breakpoint
        bool isSmallScreen = constraints.maxWidth < 600;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: isSmallScreen
              ? Column(
            children: [
              _buildDropDown(index),
              SizedBox(height: 16),
              _buildTextField(index),
              SizedBox(height: 16),
              _buildUnitDropDown(index),
            ],
          )
              : Row(
            children: [
              Expanded(child: _buildDropDown(index)),
              SizedBox(width: 16),
              Expanded(child: _buildTextField(index)),
              SizedBox(width: 16),
              Expanded(child: _buildUnitDropDown(index)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDropDown(int index) {
    return DropdownButtonFormField<String>(
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

  Widget _buildUnitDropDown(int index) {
    return DropdownButtonFormField<String>(
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

  void _calculateTotalMass() {
    try {
      print("Calculating total mass...");

      Map<String, double> totalMassesPerCoffeeForm = {};
      Map<String, double> conversionRatios =
      Map<String, double>.from(conversionData['coffee_form_conversion'] as Map);
      Map<String, double> massUnitConversion =
      Map<String, double>.from(conversionData['mass_unit_conversion'] as Map);


      for (int i = 0; i < selectedCoffeeForms.length; i++) {
        String coffeeForm = selectedCoffeeForms[i];
        double rawMass = enteredMasses[i];
        String massUnit = selectedMassUnits[i];

        // Ensure all necessary data is available and not null.
        if (conversionRatios[coffeeForm] == null || massUnitConversion[massUnit] == null) {
          print("Data not available for coffee form: $coffeeForm or mass unit: $massUnit");
          return;
        }

        double convertedMassToBase = rawMass * massUnitConversion[massUnit]!;
        double convertedMassToGreen = convertedMassToBase / conversionRatios[coffeeForm]!;

        totalMassesPerCoffeeForm.update(
            coffeeForm,
                (existing) => existing + convertedMassToGreen,
            ifAbsent: () => convertedMassToGreen
        );
      }

      setState(() {
        totalMassResults = totalMassesPerCoffeeForm;
      });
      print("Total mass results: $totalMassResults");

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
                  : Text("No results available.", style: TextStyle(fontSize: 16.0)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTotalResultText() {
    double totalConvertedResult = totalMassResults!.entries.map((entry) {
      double baseMass = entry.value;
      double conversionRatio = conversionData['coffee_form_conversion'][selectedResultCoffeeForm] ?? 1.0;
      double unitConversion = conversionData['mass_unit_conversion'][selectedResultMassUnit] ?? 1.0;
      return baseMass * conversionRatio / unitConversion;
    }).reduce((value, element) => value + element);

    return Text(
      "Total ${selectedResultCoffeeForm}: ${totalConvertedResult.toStringAsFixed(2)} ${selectedResultMassUnit}",
      style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
    );
  }


  Widget _buildDropdown(String label, String selectedValue, List<String> items, ValueChanged<String?> onChanged) {
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
                        style: ElevatedButton.styleFrom(primary: primaryColor),
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
  @override
  _AreaTabState createState() => _AreaTabState();
}

class _AreaTabState extends State<AreaTab> {
  static const primaryColor = const Color(0xFFFFC000);
  Map<String, double> _areaUnitConversion = {
    "hectar": 1.0,
  };

  List<TextEditingController> _controllers = [];
  List<String> _selectedUnits = ["hectar"];
  String _selectedResultUnit = "hectar";
  double? _convertedTotalArea;

  final ConversionRepository _repository = ConversionRepository();

  @override
  void initState() {
    super.initState();
    _loadAreaConversionData();
    _addNewInputRow();
  }

  Future<void> _loadAreaConversionData() async {
    try {
      _areaUnitConversion = await _repository.fetchAreaConversionRules();
      print("area unit: " + _areaUnitConversion.toString());
      if (_areaUnitConversion.isNotEmpty) {
        setState(() {
          _selectedUnits.add("hectar");
          _selectedResultUnit = "hectar";
        });
      }
    } catch (e) {
      print("Error during fetching conversion data: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to load conversion data")));
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
      print("result: " + totalAreaInSquareMeters.toString());
      setState(() {

        _convertedTotalArea = totalAreaInSquareMeters / _areaUnitConversion[_selectedResultUnit]!;
      });
    } catch (e) {
      // Handle parsing error
      print("Error during calculation: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invalid input")));
    }
  }

  void _addNewInputRow() {
    setState(() {
      _controllers.add(TextEditingController());
      _selectedUnits.add("hectar");
    });
  }


  Widget _buildInputRow(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _controllers[index],
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Area',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
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
    );
  }

  @override
  Widget build(BuildContext context) {
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
                              items: _areaUnitConversion.keys.map((String unit) {
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
                          style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
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

class ConversionRepository {
  final String massApiUrl = "https://raw.githubusercontent.com/aben-enveritas/enveritas_converter/master/mass_conversion.json";
  final String areaApiUrl = "https://raw.githubusercontent.com/aben-enveritas/enveritas_converter/master/area_conversion.json";

  Future<Map<String, dynamic>> fetchMassConversionRules() async {
    try {
      final response = await http.get(Uri.parse(massApiUrl));
      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(jsonDecode(response.body));

        // Save fetched data to local storage
        await _saveToLocal("massConversion", data);

        return data;
      } else {
        throw Exception('Failed to load conversion rules');
      }
    } catch (e) {
      // Fallback: Load from local storage or assets
      return await _loadMassFromLocalOrAssets();
    }
  }

  Future<void> _saveToLocal(String key, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(key, jsonEncode(data)); // Encode map to string and save to local storage
  }

  Future<Map<String, dynamic>> _loadMassFromLocalOrAssets() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString("massConversion"); // Retrieve from local storage

    // If there's data in local storage, return it. Otherwise, load from assets.
    if (savedData != null && savedData.isNotEmpty) {
      return Map<String, dynamic>.from(jsonDecode(savedData));
    } else {
      final data = await rootBundle.loadString('assets/mass_conversion.json');
      return Map<String, dynamic>.from(jsonDecode(data));
    }
  }

  Future<Map<String, dynamic>> _loadMassFromAssets(String type) async {
    final data = await rootBundle.loadString('assets/mass_conversion.json');
    return Map<String, dynamic>.from(jsonDecode(data));
  }


  Future<Map<String, double>> fetchAreaConversionRules() async {
    try {
      final response = await http.get(Uri.parse(areaApiUrl));
      if (response.statusCode == 200) {
        final data = Map<String, double>.from(jsonDecode(response.body));

        // Save fetched data to local storage
        await _saveToLocal("areaConversion", data);

        return data;
      } else {
        throw Exception('Failed to load area conversion rules');
      }
    } catch (e) {
      // Fallback: Load from local storage or assets
      return await _loadAreaFromLocalOrAssets();
    }
  }

  Future<Map<String, double>> _loadAreaFromLocalOrAssets() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString("areaConversion"); // Retrieve from local storage

    // If there's data in local storage, return it. Otherwise, load from assets.
    if (savedData != null && savedData.isNotEmpty) {
      return Map<String, double>.from(jsonDecode(savedData));
    } else {
      final data = await rootBundle.loadString('assets/area_conversion.json');
      return Map<String, double>.from(jsonDecode(data));
    }
  }

  Future<Map<String, double>> _loadAreaConversionFromAssets() async {
    final data = await rootBundle.loadString('assets/area_conversion.json');
    return Map<String, double>.from(jsonDecode(data));
  }
}

