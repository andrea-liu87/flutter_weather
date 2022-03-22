
// https://www.metaweather.com/api/location/search/?query=london
// {
// "title": "London",
// "location_type":" City",
// "woeid": 44418,
// "latt_long": "51.506321,-0.12714"
// }

import 'package:json_annotation/json_annotation.dart';

part 'location.g.dart';

enum LocationType{
  @JsonValue('City') city,
  @JsonValue('Region') region,
  @JsonValue('State') state,
  @JsonValue('Province') province,
  @JsonValue('Country') country,
  @JsonValue('Continent') continent
}

@JsonSerializable()
class Location {
  const Location({
    required this.title,
    required this.locationType,
    required this.latlong,
    required this.woeid
});

  factory Location.fromJson(Map<String, dynamic> json) =>
      _$LocationFromJson(json);

  final String title;
  final LocationType locationType;
  @JsonKey(name: 'latt_long') @LatLngConverter() final LatLng latlong;
  final int woeid;
}

class LatLng {
  const LatLng({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class LatLngConverter implements JsonConverter<LatLng, String> {
  const LatLngConverter();

  @override
  String toJson(LatLng latLng) {
    return '${latLng.latitude},${latLng.longitude}';
  }

  @override
  LatLng fromJson(String jsonString) {
    final parts = jsonString.split(',');
    return LatLng(
      latitude: double.tryParse(parts[0]) ?? 0,
      longitude: double.tryParse(parts[1]) ?? 0,
    );
  }
}