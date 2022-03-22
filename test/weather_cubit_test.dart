import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_weather/models/weather.dart';
import 'package:flutter_weather/weather/weather_cubit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:weather_repository/weather_repository.dart'
    as weather_repository;

import 'helpers/hydrated_bloc.dart';

const weatherLocation = 'London';
const weatherCondition = weather_repository.WeatherCondition.rainy;
const weatherTemperature = 9.8;

class MockWeatherRepository extends Mock
    implements weather_repository.WeatherRepository {}

class MockWeather extends Mock implements weather_repository.Weather {}

void main() {
  group('WeatherCubit', () {
    late weather_repository.Weather weather;
    late weather_repository.WeatherRepository weatherRepository;

    setUp(() {
      weather = MockWeather();
      weatherRepository = MockWeatherRepository();
      when(() => weather.condition).thenReturn(weatherCondition);
      when(() => weather.location).thenReturn(weatherLocation);
      when(() => weather.temperature).thenReturn(weatherTemperature);
      when(() => weatherRepository.getWeather(any()))
          .thenAnswer((_) async => weather);
    });

    test('initial state is correct', () {
      mockHydratedStorage(() {
        final weatherCubit = WeatherCubit(weatherRepository);
        expect(weatherCubit.state, WeatherState());
      });
    });

    group('toJson/fromJson', () {
      test('working properly', () {
        mockHydratedStorage(() {
          final weatherCubit = WeatherCubit(weatherRepository);
          expect(weatherCubit.fromJson(weatherCubit.toJson(weatherCubit.state)),
              weatherCubit.state);
        });
      });
    });

    group('fetchWeather', () {
      blocTest<WeatherCubit, WeatherState>('emit nothing when city is null',
          build: () =>
              mockHydratedStorage(() => WeatherCubit(weatherRepository)),
          act: (cubit) => cubit.fetchWeather(null),
          expect: () => <WeatherState>[]);

      blocTest<WeatherCubit, WeatherState>('emit nothing when city is empty',
          build: () =>
              mockHydratedStorage(() => WeatherCubit(weatherRepository)),
          act: (cubit) => cubit.fetchWeather(''),
          expect: () => <WeatherState>[]);

      blocTest<WeatherCubit, WeatherState>('calls getWeather with correct city',
          build: () =>
              mockHydratedStorage(() => WeatherCubit(weatherRepository)),
          act: (cubit) => cubit.fetchWeather(weatherLocation),
          verify: (_) {
            verify(() => weatherRepository.getWeather(weatherLocation))
                .called(1);
          });

      blocTest<WeatherCubit, WeatherState>(
          'emits [loading, failure] when getWeather throws',
          setUp: () => when(() => weatherRepository.getWeather(any()))
              .thenThrow(Exception('oops')),
          build: () =>
              mockHydratedStorage(() => WeatherCubit(weatherRepository)),
          act: (cubit) => cubit.fetchWeather(weatherLocation),
          expect: () => <WeatherState>[
                WeatherState(status: WeatherStatus.loading),
                WeatherState(status: WeatherStatus.failure)
              ]);

      blocTest<WeatherCubit, WeatherState>(
          'emits [loading, success] when getWeather returns (celsius)',
          build: () =>
              mockHydratedStorage(() => WeatherCubit(weatherRepository)),
          act: (cubit) => cubit.fetchWeather(weatherLocation),
          expect: () => <dynamic>[
                WeatherState(status: WeatherStatus.loading),
                isA<WeatherState>()
                    .having((w) => w.status, 'status', WeatherStatus.success)
                    .having(
                        (w) => w.weather,
                        'weather',
                        isA<Weather>()
                            .having((w) => w.condition, 'condition',
                                weatherCondition)
                            .having((w) => w.temperature, 'temperature',
                                Temperature(value: weatherTemperature))
                            .having(
                                (w) => w.location, 'location', weatherLocation)
                            .having(
                                (w) => w.lastUpdated, 'lastUpdate', isNotNull))
              ]);

      blocTest<WeatherCubit, WeatherState>(
          'emits [loading, success] when getWeather returns (fahrenheit)',
          build: () =>
              mockHydratedStorage(() => WeatherCubit(weatherRepository)),
          seed: () =>
              WeatherState(temperatureUnits: TemperatureUnits.farenheit),
          act: (cubit) => cubit.fetchWeather(weatherLocation),
          expect: () => <dynamic>[
                WeatherState(
                    status: WeatherStatus.loading,
                    temperatureUnits: TemperatureUnits.farenheit),
                isA<WeatherState>()
                    .having((w) => w.status, 'status', WeatherStatus.success)
                    .having(
                        (w) => w.weather,
                        'weather',
                        isA<Weather>()
                            .having((w) => w.condition, 'condition',
                                weatherCondition)
                            .having(
                                (w) => w.temperature,
                                'temperature',
                                Temperature(
                                    value: weatherTemperature.toFahrenheit()))
                            .having(
                                (w) => w.location, 'location', weatherLocation)
                            .having(
                                (w) => w.lastUpdated, 'lastUpdate', isNotNull))
              ]);
    });

    group('refreshWeather', () {
      blocTest<WeatherCubit, WeatherState>(
          'emits nothing when status is not success',
          build: () =>
              mockHydratedStorage(() => WeatherCubit(weatherRepository)),
          act: (cubit) => cubit.refreshWeather(),
          expect: () => <WeatherState>[],
          verify: (_) {
            verifyNever(() => weatherRepository.getWeather(any()));
          });

      blocTest<WeatherCubit, WeatherState>(
        'emits nothing when location is null',
        build: () => mockHydratedStorage(() => WeatherCubit(weatherRepository)),
        seed: () => WeatherState(status: WeatherStatus.success),
        act: (cubit) => cubit.refreshWeather(),
        expect: () => <WeatherState>[],
        verify: (_) {
          verifyNever(() => weatherRepository.getWeather(any()));
        },
      );

      blocTest<WeatherCubit, WeatherState>(
          'invokes getWeather with correct location',
          build: () =>
              mockHydratedStorage(() => WeatherCubit(weatherRepository)),
          seed: () => WeatherState(
              status: WeatherStatus.success,
              weather: Weather(
                  condition: weatherCondition,
                  lastUpdated: DateTime(2020),
                  location: weatherLocation,
                  temperature: Temperature(value: weatherTemperature))),
          act: (cubit) => cubit.refreshWeather(),
          verify: (_) =>
              verify(() => weatherRepository.getWeather(weatherLocation))
                  .called(1));

      blocTest<WeatherCubit, WeatherState>(
        'emits nothing when exception is thrown',
        build: () => mockHydratedStorage(() => WeatherCubit(weatherRepository)),
        setUp: () {
          when(() => weatherRepository.getWeather(any()))
              .thenThrow(Exception('oops'));
        },
        seed: () => WeatherState(
            status: WeatherStatus.success,
            weather: Weather(
                condition: weatherCondition,
                lastUpdated: DateTime(2020),
                location: weatherLocation,
                temperature: Temperature(value: weatherTemperature))),
        act: (cubit) => cubit.refreshWeather(),
        expect: () => <WeatherState>[],
      );

      blocTest<WeatherCubit, WeatherState>('emits updated weather (celsius)',
          seed: () => WeatherState(
                status: WeatherStatus.success,
                weather: Weather(
                  location: weatherLocation,
                  temperature: Temperature(value: 0.0),
                  lastUpdated: DateTime(2020),
                  condition: weatherCondition,
                ),
              ),
          build: () =>
              mockHydratedStorage(() => WeatherCubit(weatherRepository)),
          act: (cubit) => cubit.refreshWeather(),
          expect: () => <Matcher>[
                isA<WeatherState>()
                    .having((w) => w.status, 'status', WeatherStatus.success)
                    .having(
                        (w) => w.weather,
                        'Weather',
                        isA<Weather>()
                            .having(
                                (w) => w.lastUpdated, 'lastUpdate', isNotNull)
                            .having((w) => w.condition, 'condition',
                                weatherCondition)
                            .having(
                                (w) => w.location, 'location', weatherLocation)
                            .having((w) => w.temperature, 'Temperature',
                                Temperature(value: weatherTemperature)))
              ]);

      blocTest<WeatherCubit, WeatherState>('emits updated weather (fahrenheit)',
          seed: () => WeatherState(
              status: WeatherStatus.success,
              temperatureUnits: TemperatureUnits.farenheit,
              weather: Weather(
                  condition: weatherCondition,
                  lastUpdated: DateTime(2020),
                  location: weatherLocation,
                  temperature: Temperature(value: 0.0))),
          build: () =>
              mockHydratedStorage(() => WeatherCubit(weatherRepository)),
          act: (cubit) => cubit.refreshWeather(),
          expect: () => <Matcher>[
                isA<WeatherState>()
                    .having((ws) => ws.status, 'status', WeatherStatus.success)
                    .having(
                        (ws) => ws.weather,
                        'weather',
                        isA<Weather>()
                            .having((w) => w.condition, 'condition',
                                weatherCondition)
                            .having(
                                (w) => w.lastUpdated, 'lastUpdated', isNotNull)
                            .having(
                                (w) => w.location, 'location', weatherLocation)
                            .having(
                                (w) => w.temperature,
                                'temperature',
                                Temperature(
                                    value: weatherTemperature.toFahrenheit())))
              ]);
    });

    group('toggleUnit', () {
      blocTest<WeatherCubit, WeatherState>(
          'emits updated units when status is not success',
          build: () =>
              mockHydratedStorage(() => WeatherCubit(weatherRepository)),
          act: (cubit) => cubit.toggleUnits(),
          expect: () => <Matcher>[
                isA<WeatherState>().having((w) => w.temperatureUnits, 'units',
                    TemperatureUnits.farenheit)
              ]);

      blocTest<WeatherCubit, WeatherState>(
          'emits updated units and temperature '
          'when status is success (celsius)',
          seed: () => WeatherState(
              status: WeatherStatus.success,
              temperatureUnits: TemperatureUnits.farenheit,
              weather: Weather(
                  condition: weather_repository.WeatherCondition.rainy,
                  lastUpdated: DateTime(2020),
                  location: weatherLocation,
                  temperature: Temperature(value: weatherTemperature))),
          build: () =>
              mockHydratedStorage(() => WeatherCubit(weatherRepository)),
          act: (cubit) => cubit.toggleUnits(),
          expect: () => <WeatherState>[
                WeatherState(
                    status: WeatherStatus.success,
                    temperatureUnits: TemperatureUnits.celcius,
                    weather: Weather(
                        condition: weatherCondition,
                        lastUpdated: DateTime(2020),
                        location: weatherLocation,
                        temperature:
                            Temperature(value: weatherTemperature.toCelsius())))
              ]);

      blocTest<WeatherCubit, WeatherState>(
          'emits updated units and temperature '
          'when status is success (fahrenheit)',
          seed: () => WeatherState(
              status: WeatherStatus.success,
              temperatureUnits: TemperatureUnits.celcius,
              weather: Weather(
                  condition: weather_repository.WeatherCondition.rainy,
                  lastUpdated: DateTime(2020),
                  location: weatherLocation,
                  temperature: Temperature(value: weatherTemperature))),
          build: () =>
              mockHydratedStorage(() => WeatherCubit(weatherRepository)),
          act: (cubit) => cubit.toggleUnits(),
          expect: () => <WeatherState>[
                WeatherState(
                    status: WeatherStatus.success,
                    temperatureUnits: TemperatureUnits.farenheit,
                    weather: Weather(
                        location: weatherLocation,
                        temperature: Temperature(
                          value: weatherTemperature.toFahrenheit(),
                        ),
                        lastUpdated: DateTime(2020),
                        condition: weather_repository.WeatherCondition.rainy))
              ]);
    });
  });
}

extension on double {
  double toFahrenheit() => ((this * 9 / 5) + 32);

  double toCelsius() => ((this - 32) * 5 / 9);
}
