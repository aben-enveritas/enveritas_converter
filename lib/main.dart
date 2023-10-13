import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
        ConversionRepository().fetchConversionRules("coffee_form_conversion");
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
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

  late Map<String, dynamic> conversionData;
  bool isLoading = true;
  String? error;
  List<String> coffeeForms = [];
  List<String> massUnits = ['mass', 'kilogram', 'gram'];

  List<String> selectedCoffeeForms = [''];
  List<String> selectedMassUnits = ['gram'];
  List<double> enteredMasses = [0];

  double totalConvertedMass = 0;

  String selectedResultCoffeeForm = '';
  String selectedResultMassUnit = 'gram';

  @override
  void initState() {
    super.initState();
    _fetchConversionData();
  }

  _fetchConversionData() async {
    try {
      conversionData = await widget.conversionRules;
      coffeeForms = conversionData["coffee_form_conversion"].keys.toList();
      if (coffeeForms.isNotEmpty) {
        selectedCoffeeForms[0] = coffeeForms[0];
        selectedResultCoffeeForm = coffeeForms[0];
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
      selectedMassUnits.add('gram');
      enteredMasses.add(0);
    });
  }


  _buildInputRow(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
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
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              keyboardType: TextInputType.number,
              onChanged: (value) {
                enteredMasses[index] = double.tryParse(value) ?? 0;
              },
              decoration: InputDecoration(
                labelText: 'Mass',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
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
            ),
          ),
        ],
      ),
    );
  }

  void _calculateTotalMass() {
    try {
      print("Calculating total mass...");

      Map<String, double> totalMassesPerCoffeeForm = {};
      Map<String, double> conversionRatios = conversionData['coffee_form_conversion'];
      Map<String, double> massUnitConversion = conversionData['mass_unit_conversion'];

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
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedResultCoffeeForm,
                  items: coffeeForms.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedResultCoffeeForm = newValue!;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Coffee Form',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedResultMassUnit,
                  items: massUnits.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedResultMassUnit = newValue!;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(width: 16),
              ElevatedButton(
                onPressed: _calculateTotalMass,
                child: Text('Calculate Total Mass'),
                style: ElevatedButton.styleFrom(
                  primary: Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          if (totalMassResults != null && totalMassResults!.isNotEmpty)
            ...totalMassResults!.entries.map((entry) {
              double baseMass = entry.value;

              // Conversion logic - consider valid checks and handling for unavailable data
              double conversionRatio = conversionData['coffee_form_conversion'][selectedResultCoffeeForm] ?? 1.0;
              double unitConversion = conversionData['mass_unit_conversion'][selectedResultMassUnit] ?? 1.0;

              double convertedResult = baseMass * conversionRatio / unitConversion;

              return Text(
                "${entry.key}: ${convertedResult.toStringAsFixed(2)} ${selectedResultMassUnit}",
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              );
            }).toList()
          else
            Text("No results available.", style: TextStyle(fontSize: 16.0)),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mass Conversion"),
        backgroundColor: Colors.green,
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
                        child: Text('Add Another Input'),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.green,
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
  Map<String, double> _areaUnitConversion = {
    "square_meter": 1.0,
    "square_kilometer": 1000000.0,
    "hectare": 10000.0,
    "acre": 4046.86,
    "square_mile": 2589988.11,
  };

  List<TextEditingController> _controllers = [];
  List<String> _selectedUnits = [];
  String _selectedResultUnit = "square_meter";
  double? _convertedTotalArea;

  @override
  void initState() {
    super.initState();
    _addNewInputRow();
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
      _selectedUnits.add("square_meter");
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
        backgroundColor: Colors.blue,
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
                        child: Text('Add Another Input'),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.blue,
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
                              primary: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      if (_convertedTotalArea != null)
                        Text(
                          "Total Area: ${_convertedTotalArea!.toStringAsFixed(2)} $_selectedResultUnit",
                          style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
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
  Future<Map<String, dynamic>> fetchConversionRules(String type) async {
    try {
      // In a real-world scenario, use an HTTP client to fetch data from an API.
      throw Exception('API fetch not implemented');
    } catch (e) {
      return _loadFromAssets(type);
    }
  }

  Future<Map<String, dynamic>> _loadFromAssets(String type) async {
    // final data = await rootBundle.loadString('assets/$type.json');
    // return jsonDecode(data);
    final Map<String, dynamic> data = {
      "coffee_form_conversion": {
        "cherry": 6.0,
        "dry_cherry": 2.0,
        "wet_parchment": 2.5,
        "dry_parchment": 1.25,
        "green": 1.0
      },
      "mass_unit_conversion": {"mass": 1.0, "kilogram": 1000.0, "gram": 1.0}
    };
    return data;
  }
}
