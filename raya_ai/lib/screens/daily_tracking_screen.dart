import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:raya_ai/screens/profilepage_screen.dart';
import 'package:raya_ai/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'analysis_history_screen.dart';

class DailyTrackingScreen extends StatefulWidget {
  const DailyTrackingScreen({Key? key}) : super(key: key);

  @override
  State<DailyTrackingScreen> createState() => _DailyTrackingScreenState();
}

class _DailyTrackingScreenState extends State<DailyTrackingScreen> {
  late final ValueNotifier<List<LocalAnalysisEntry>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<LocalAnalysisEntry>> _events = {};
  bool _isLoading = true;

  // Chart data
  List<FlSpot> _chartSpots = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    _loadData();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  List<LocalAnalysisEntry> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  Future<void> _loadData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final storageKey = 'analyses_${user.id}';
    final List<String> encodedList = prefs.getStringList(storageKey) ?? [];

    final Map<DateTime, List<LocalAnalysisEntry>> newEvents = {};
    final List<FlSpot> spots = [];

    // Sort by date for the chart
    final List<LocalAnalysisEntry> allEntries = [];

    for (var encoded in encodedList) {
      try {
        final Map<String, dynamic> map = jsonDecode(encoded);
        final entry = LocalAnalysisEntry.fromJson(map);

        // Sadece günlük analizleri göster (type == 'daily' veya null/legacy)
        if (entry.type != null && entry.type != 'daily') {
          continue;
        }

        final date = DateTime.parse(entry.timestamp);
        final dayKey = DateTime(date.year, date.month, date.day);

        if (newEvents[dayKey] == null) {
          newEvents[dayKey] = [];
        }
        newEvents[dayKey]!.add(entry);
        allEntries.add(entry);
      } catch (e) {
        print('Error parsing entry: $e');
      }
    }

    // Sort entries by date for the chart
    allEntries.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Create chart spots
    // Note: Since we don't have a real "score" in the analysis yet,
    // we will simulate a score for demonstration purposes or use a placeholder.
    // In a real app, this should come from the analysis result.
    for (int i = 0; i < allEntries.length; i++) {
      // Simulating a score between 60 and 95 based on the hash of the timestamp to be consistent
      final score = 60 + (allEntries[i].timestamp.hashCode % 36);
      spots.add(FlSpot(i.toDouble(), score.toDouble()));
    }

    setState(() {
      _events = newEvents;
      _chartSpots = spots;
      _selectedEvents.value = _getEventsForDay(_selectedDay!);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final LinearGradient backgroundGradient =
        isDark
            ? AppGradients.darkBackground
            : const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFDFBFF), Color(0xFFEFE8F4)],
            );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: SafeArea(
          child:
              _isLoading
                  ? Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  )
                  : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(theme),
                          const SizedBox(height: 24),
                          _buildChartSection(theme, isDark),
                          const SizedBox(height: 24),
                          _buildCalendarSection(theme, isDark),
                          const SizedBox(height: 24),
                          _buildEventList(theme),
                          const SizedBox(height: 200),
                        ],
                      ),
                    ),
                  ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            size: 22,
          ),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          },
        ),
        const SizedBox(width: 8),
        Text(
          'Günlük Takip',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection(ThemeData theme, bool isDark) {
    if (_chartSpots.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color:
              isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cilt Sağlığı Skoru',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Son analizlerinize göre değişim',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 1.70,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: theme.colorScheme.onSurface.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: _chartSpots.length.toDouble() - 1,
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: _chartSpots,
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [Colors.pinkAccent, Colors.purpleAccent],
                    ),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.pinkAccent.withOpacity(0.3),
                          Colors.purpleAccent.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarSection(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color:
              isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: TableCalendar(
        firstDay: DateTime.utc(2023, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          if (!isSameDay(_selectedDay, selectedDay)) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
            _selectedEvents.value = _getEventsForDay(selectedDay);
          }
        },
        onFormatChanged: (format) {
          if (_calendarFormat != format) {
            setState(() {
              _calendarFormat = format;
            });
          }
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        eventLoader: _getEventsForDay,
        calendarStyle: CalendarStyle(
          markerDecoration: BoxDecoration(
            color: Colors.pinkAccent,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
          ),
          defaultTextStyle: TextStyle(color: theme.colorScheme.onSurface),
          weekendTextStyle: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          selectedTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: theme.colorScheme.primary,
          ),
        ),

        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isEmpty) return null;
            final entry = events.first as LocalAnalysisEntry;

            // Resim varsa göster
            if (entry.imagePath != null &&
                File(entry.imagePath!).existsSync()) {
              return Positioned(
                bottom: 1,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.file(
                      File(entry.imagePath!),
                      width: 35, // Hücre boyutuna göre ayarlandı
                      height: 35,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            }

            // Resim yoksa varsayılan nokta göster
            return Positioned(
              bottom: 1,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.pinkAccent,
                ),
                width: 7.0,
                height: 7.0,
              ),
            );
          },
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: theme.textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.bold,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: theme.colorScheme.onSurface,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildEventList(ThemeData theme) {
    return ValueListenableBuilder<List<LocalAnalysisEntry>>(
      valueListenable: _selectedEvents,
      builder: (context, value, _) {
        if (value.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Bu tarihte analiz bulunamadı.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: value.length,
          itemBuilder: (context, index) {
            final entry = value[index];
            final date = DateTime.parse(entry.timestamp);
            final formatted = DateFormat('dd.MM.yyyy HH:mm').format(date);

            Widget? leadingImage;
            if (entry.imagePath != null &&
                entry.imagePath!.isNotEmpty &&
                File(entry.imagePath!).existsSync()) {
              leadingImage = ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(entry.imagePath!),
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              );
            }

            final bool isDark = theme.brightness == Brightness.dark;
            final Color cardColor =
                isDark
                    ? Colors.white.withOpacity(0.05)
                    : theme.colorScheme.surface;
            final Color borderColor =
                isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05);
            final Color textColor =
                theme.textTheme.bodyLarge?.color ?? Colors.black87;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AnalysisDetailPage(entry: entry),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        leadingImage ??
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.analytics_outlined,
                                color: theme.colorScheme.primary,
                                size: 28,
                              ),
                            ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formatted,
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${entry.sectionCount} bölüm',
                                style: TextStyle(
                                  color: textColor.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
