import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tela de seleção de horário e dias para lembrete de devocional
class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  TimeOfDay _selectedTime = const TimeOfDay(hour: 7, minute: 0);
  final List<bool> _selectedDays = List.generate(7, (index) => false);
  final List<String> _days = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];

  Future<void> _savePreferencesAndContinue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reminder_time', _selectedTime.format(context));
    await prefs.setStringList(
      'reminder_days',
      _selectedDays.map((d) => d ? '1' : '0').toList(),
    );
    await prefs.setBool('reminder_configured', true);
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _skipAndContinue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_skipped', true);
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              const Text(
                'Qual o melhor horário pra te lembrar de buscar a Presença?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Você pode escolher qualquer horário, mas recomendamos bem cedo pela manhã.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                    );
                    if (picked != null) {
                      setState(() => _selectedTime = picked);
                    }
                  },
                  child: Text(
                    'Selecionar horário: ${_selectedTime.format(context)}',
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Quando você gostaria de receber um lembrete?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Todo dia é ideal, mas recomendamos escolher pelo menos cinco. A constância é essencial para aprofundar sua intimidade com Deus!',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(7, (index) {
                  return ChoiceChip(
                    label: Text(_days[index]),
                    selected: _selectedDays[index],
                    onSelected: (selected) {
                      setState(() => _selectedDays[index] = selected);
                    },
                  );
                }),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _savePreferencesAndContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005954),
                    shape: const StadiumBorder(),
                    minimumSize: const Size(0, 56),
                  ),
                  child: const Text('SALVAR', style: TextStyle(fontSize: 18)),
                ),
              ),
              TextButton(
                onPressed: _skipAndContinue,
                child: const Text('NÃO OBRIGADO'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
