import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
        // Header — cartão sobre o sheet branco (mesmo idioma do hub Registros/Históricos)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryBlue.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.18),
                  ),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: AppTheme.primaryBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'menst_calendar_title'.tr,
                      style: AppTheme.titleMedium.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'menst_calendar_sub'.tr,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary.withValues(alpha: 0.95),
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
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryBlue.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
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
                color: AppTheme.primaryBlue,
              ),
              defaultTextStyle: AppTheme.bodyMedium.copyWith(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
              selectedTextStyle: AppTheme.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              todayTextStyle: AppTheme.bodyMedium.copyWith(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w700,
              ),
              markersMaxCount: 3,
              markerDecoration: const BoxDecoration(
                color: Color(0xFFEC4899),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryBlue,
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
                color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                ),
              ),
              formatButtonTextStyle: AppTheme.bodySmall.copyWith(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
              titleTextStyle: AppTheme.titleMedium.copyWith(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w700,
              ),
              leftChevronIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.secondaryBlue.withValues(alpha: 0.25),
                  ),
                ),
                child: Icon(
                  Icons.chevron_left_rounded,
                  color: AppTheme.primaryBlue,
                  size: 16,
                ),
              ),
              rightChevronIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.secondaryBlue.withValues(alpha: 0.25),
                  ),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.primaryBlue,
                  size: 16,
                ),
              ),
              headerPadding: const EdgeInsets.symmetric(vertical: 8),
              headerMargin: const EdgeInsets.only(bottom: 16),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: AppTheme.bodySmall.copyWith(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
              weekendStyle: AppTheme.bodySmall.copyWith(
                color: AppTheme.primaryBlue,
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
                final keys = ['menst_dow_sun', 'menst_dow_mon', 'menst_dow_tue', 'menst_dow_wed', 'menst_dow_thu', 'menst_dow_fri', 'menst_dow_sat'];
                return Center(
                  child: Text(
                    keys[day.weekday % 7].tr,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.primaryBlue,
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
                              : AppTheme.primaryBlue,
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
            color: AppTheme.lightBlue.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: [
              Text(
                'menst_legend'.tr,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLegendItem('menst_flow_light'.tr, const Color(0xFF10B981)),
                  _buildLegendItem('menst_flow_moderate'.tr, const Color(0xFFF59E0B)),
                  _buildLegendItem('menst_flow_heavy'.tr, const Color(0xFFEF4444)),
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
            color: AppTheme.primaryBlue,
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