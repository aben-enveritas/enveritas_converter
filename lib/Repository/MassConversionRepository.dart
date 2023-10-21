
import 'package:enveritas_converter/Repository/ConversionRepository.dart';

class MassConversionRepository extends ConversionRepository {
  MassConversionRepository()
      : super(
      "https://raw.githubusercontent.com/aben-enveritas/enveritas_conversion_rules/main/mass_conversion.json",
      "massConversion",
      'assets/mass_conversion.json');
}