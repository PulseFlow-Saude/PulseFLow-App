import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/menstruacao.dart';
import '../theme/app_theme.dart';

class MenstruacaoCalendar extends StatefulWidget {
  final List<Menstruacao> menstruacoes;
  final Function(DateTime)? onDaySelected;

  const MenstruacaoCalendar({
    Key? key,
    required this.menstruacoes,
    this.onDaySelected,
  }) : super(key: key);

  @override
  State<MenstruacaoCalendar> createState() => _MenstruacaoCalendarState();
}

class _MenstruacaoCalendarState extends State<MenstruacaoCalendar> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header do calendário
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF00324A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calendário Menstrual',
                      style: AppTheme.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Acompanhe seus ciclos no calendário',
                      style: AppTheme.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Calendário
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF64B5F6).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: TableCalendar<Menstruacao>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            eventLoader: _getEventsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: AppTheme.bodyMedium.copyWith(
                color: const Color(0xFF00324A),
              ),
              defaultTextStyle: AppTheme.bodyMedium.copyWith(
                color: const Color(0xFF00324A),
                fontWeight: FontWeight.w600,
              ),
              selectedTextStyle: AppTheme.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              todayTextStyle: AppTheme.bodyMedium.copyWith(
                color: const Color(0xFF00324A),
                fontWeight: FontWeight.w700,
              ),
              markersMaxCount: 3,
              markerDecoration: BoxDecoration(
                color: const Color(0xFFEC4899),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: const Color(0xFF00324A),
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: const Color(0xFF00324A).withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF00324A),
                  width: 2,
                ),
              ),
              defaultDecoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              weekendDecoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              holidayDecoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              outsideDecoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              disabledDecoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              cellMargin: const EdgeInsets.all(4),
              cellPadding: const EdgeInsets.all(6),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonShowsNext: false,
              formatButtonDecoration: BoxDecoration(
                color: const Color(0xFF00324A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              formatButtonTextStyle: AppTheme.bodySmall.copyWith(
                color: const Color(0xFF00324A),
                fontWeight: FontWeight.w600,
              ),
              titleTextStyle: AppTheme.titleMedium.copyWith(
                color: const Color(0xFF00324A),
                fontWeight: FontWeight.w700,
              ),
              leftChevronIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF64B5F6).withOpacity(0.3),
                  ),
                ),
                child: const Icon(
                  Icons.chevron_left_rounded,
                  color: Color(0xFF00324A),
                  size: 16,
                ),
              ),
              rightChevronIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF64B5F6).withOpacity(0.3),
                  ),
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF00324A),
                  size: 16,
                ),
              ),
              headerPadding: const EdgeInsets.symmetric(vertical: 8),
              headerMargin: const EdgeInsets.only(bottom: 16),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: AppTheme.bodySmall.copyWith(
                color: const Color(0xFF00324A),
                fontWeight: FontWeight.w600,
              ),
              weekendStyle: AppTheme.bodySmall.copyWith(
                color: const Color(0xFF00324A),
                fontWeight: FontWeight.w600,
              ),
            ),
            selectedDayPredicate: (day) => false,
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return null;
                
                final menstruacao = events.first;
                return _buildDayMarker(day, menstruacao);
              },
              dowBuilder: (context, day) {
                final weekdays = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
                return Center(
                  child: Text(
                    weekdays[day.weekday % 7],
                    style: AppTheme.bodySmall.copyWith(
                      color: const Color(0xFF00324A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
              defaultBuilder: (context, day, focusedDay) {
                final isMenstruacao = _isMenstruacaoDay(day);
                final menstruacao = _getMenstruacaoForDay(day);
                
                return GestureDetector(
                  onTap: () {
                    if (isMenstruacao) {
                      widget.onDaySelected?.call(day);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isMenstruacao 
                          ? _getFluxoColorForDay(day, menstruacao).withOpacity(0.2)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: isMenstruacao
                          ? Border.all(
                              color: _getFluxoColorForDay(day, menstruacao),
                              width: 2,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: AppTheme.bodyMedium.copyWith(
                          color: isMenstruacao 
                              ? _getFluxoColorForDay(day, menstruacao)
                              : const Color(0xFF00324A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Legenda
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD).withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                'Legenda',
                style: AppTheme.bodyMedium.copyWith(
                  color: const Color(0xFF00324A),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLegendItem('Leve', const Color(0xFF10B981)),
                  _buildLegendItem('Moderado', const Color(0xFFF59E0B)),
                  _buildLegendItem('Intenso', const Color(0xFFEF4444)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDayMarker(DateTime day, Menstruacao menstruacao) {
    return Positioned(
      bottom: 2,
      right: 2,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: _getFluxoColorForDay(day, menstruacao),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: const Color(0xFF00324A),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  List<Menstruacao> _getEventsForDay(DateTime day) {
    return widget.menstruacoes.where((menstruacao) {
      return day.isAfter(menstruacao.dataInicio.subtract(const Duration(days: 1))) &&
             day.isBefore(menstruacao.dataFim.add(const Duration(days: 1)));
    }).toList();
  }

  bool _isMenstruacaoDay(DateTime day) {
    return widget.menstruacoes.any((menstruacao) {
      return day.isAfter(menstruacao.dataInicio.subtract(const Duration(days: 1))) &&
             day.isBefore(menstruacao.dataFim.add(const Duration(days: 1)));
    });
  }

  Menstruacao? _getMenstruacaoForDay(DateTime day) {
    try {
      return widget.menstruacoes.firstWhere(
        (menstruacao) {
          return day.isAfter(menstruacao.dataInicio.subtract(const Duration(days: 1))) &&
                 day.isBefore(menstruacao.dataFim.add(const Duration(days: 1)));
        },
      );
    } catch (e) {
      return null;
    }
  }

  Color _getFluxoColor(Menstruacao? menstruacao) {
    if (menstruacao?.diasPorData == null) {
      return const Color(0xFFEC4899);
    }

    final dayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final dia = menstruacao!.diasPorData![dayKey];
    
    if (dia == null) {
      return const Color(0xFFEC4899);
    }

    switch (dia.fluxo) {
      case 'Leve':
        return const Color(0xFF10B981);
      case 'Moderado':
        return const Color(0xFFF59E0B);
      case 'Intenso':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFEC4899);
    }
  }

  Color _getFluxoColorForDay(DateTime day, Menstruacao? menstruacao) {
    if (menstruacao?.diasPorData == null) {
      return const Color(0xFFEC4899);
    }

    final dayKey = DateFormat('yyyy-MM-dd').format(day);
    final dia = menstruacao!.diasPorData![dayKey];
    
    if (dia == null) {
      return const Color(0xFFEC4899);
    }

    switch (dia.fluxo) {
      case 'Leve':
        return const Color(0xFF10B981);
      case 'Moderado':
        return const Color(0xFFF59E0B);
      case 'Intenso':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFEC4899);
    }
  }
}