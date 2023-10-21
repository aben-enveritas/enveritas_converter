import 'package:flutter/material.dart';

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