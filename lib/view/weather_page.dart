import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_weather/models/weather.dart';
import 'package:flutter_weather/view/settings_page.dart';
import 'package:flutter_weather/view/search_page.dart';
import 'package:flutter_weather/view/weather_widget.dart';
import 'package:weather_repository/weather_repository.dart';

import '../theme/theme_cubit.dart';
import '../weather/weather_cubit.dart';

class WeatherPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => WeatherCubit(context.read<WeatherRepository>()),
      child: WeatherView(),
    );
  }
}

class WeatherView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Weather'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context)
                  .push(SettingsPage.route(context.read<WeatherCubit>()));
            },
          )
        ],
      ),
      body: Center(
        child: BlocConsumer<WeatherCubit, WeatherState>(
          listener: (context, state) {
            if (state.status.isSuccess) {
              context.read<ThemeCubit>().updateTheme(state.weather);
            }
          },
          builder: (context, state) {
            switch (state.status) {
              case (WeatherStatus.initial):
                return WeatherEmpty();
              case (WeatherStatus.loading):
                return WeatherLoading();
              case (WeatherStatus.success):
                return WeatherPopulated(
                    weather: state.weather,
                    units: state.temperatureUnits,
                    onRefresh: (){
                      return context.read<WeatherCubit>().refreshWeather();
                    });
              case (WeatherStatus.failure):
                return WeatherError();
              default:
                return WeatherError();
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.search),
        onPressed: () async {
          final city = await Navigator.of(context).push(SearchPage.route());
          await context.read<WeatherCubit>().fetchWeather(city);
        },
      ),
    );
  }
}
