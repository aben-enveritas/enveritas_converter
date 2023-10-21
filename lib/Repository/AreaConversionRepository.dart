import 'package:enveritas_converter/Repository/ConversionRepository.dart';

class AreaConversionRepository extends ConversionRepository {
  AreaConversionRepository()
      : super(
      "https://raw.githubusercontent.com/aben-enveritas/enveritas_conversion_rules/main/area_conversion.json",
      "areaConversion",
      'assets/area_conversion.json');
}