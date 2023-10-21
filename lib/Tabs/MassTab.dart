
import 'package:flutter/material.dart';

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
