import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_weather/models/models.dart';
import 'package:flutter_weather/weather/weather_cubit.dart';

class SettingsPage extends StatelessWidget {
  static Route route(WeatherCubit weatherCubit) {
    return MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: weatherCubit,
        child: SettingsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings'),),
      body: ListView(
        children: <Widget>[
          BlocBuilder<WeatherCubit, WeatherState>(
            buildWhen: (previous, current) => previous.temperatureUnits != current.temperatureUnits,
              builder: (context, state){
              return ListTile(
                title: Text('Temperature Unit'),
                isThreeLine: true,
                subtitle: Text('Use metric measurements for temperature units.'),
                trailing: Switch(
                  value: state.temperatureUnits.isCelcius,
                  onChanged: (_) => context.read<WeatherCubit>().toggleUnits(),
                ),
              );
              }),
        ],
      ),
    );
  }
}
