// lib/screens/admin/tournament_management_screen.dart
// Tournament List Screen — Pixel-perfect recreation with Local Storage persistence

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/storage_service.dart';
import '../../models/models.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/custom_notification.dart';

class TournamentManagementScreen extends StatefulWidget {
  const TournamentManagementScreen({super.key});

  @override
  State<TournamentManagementScreen> createState() => _TournamentManagementScreenState();
}

class _TournamentManagementScreenState extends State<TournamentManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatusFilter = 'All'; // 'All', 'Live', 'Upcoming', 'Completed'
  String _selectedFormatFilter = 'All'; // 'All', 'T20', 'ODI', 'Test'
  String _sortBy = 'default'; // 'default', 'name', 'teams', 'matches'

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- Filtering & Sorting Logic from Local Storage ---
  List<Tournament> _getFilteredTournaments(List<Tournament> allTournaments) {
    return allTournaments.where((t) {
      // 1. Search Query
      if (_searchQuery.isNotEmpty) {
        final matchName = t.name.toLowerCase().contains(_searchQuery);
        final matchFormat = t.format.toLowerCase().contains(_searchQuery);
        if (!matchName && !matchFormat) return false;
      }

      // 2. Status Filter Tab
      if (_selectedStatusFilter != 'All') {
        if (t.status.toLowerCase() != _selectedStatusFilter.toLowerCase()) {
          return false;
        }
      }

      // 3. Format Filter
      if (_selectedFormatFilter != 'All') {
        if (t.format.toLowerCase() != _selectedFormatFilter.toLowerCase()) {
          return false;
        }
      }

      return true;
    }).toList()
      ..sort((a, b) {
        if (_sortBy == 'name') return a.name.compareTo(b.name);
        if (_sortBy == 'teams') return b.teamsCount.compareTo(a.teamsCount);
        if (_sortBy == 'matches') return b.matchesCount.compareTo(a.matchesCount);
        return 0;
      });
  }

  // Visual Theme Config for Cards
  _CardTheme _getVisualTheme(int index, Tournament t) {
    final lowerName = t.name.toLowerCase();
    if (lowerName.contains('world cup') || index % 4 == 0) {
      return _CardTheme(
        trophyBg: const Color(0xFFFEF3C7),
        trophyColor: const Color(0xFFD97706),
        watermarkColor: const Color(0xFF10B981),
        watermarkIcon: Icons.sports_baseball_outlined,
      );
    } else if (lowerName.contains('ipl') || index % 4 == 1) {
      return _CardTheme(
        trophyBg: const Color(0xFFE0F2FE),
        trophyColor: const Color(0xFF0284C7),
        watermarkColor: const Color(0xFF0EA5E9),
        watermarkIcon: Icons.sports_cricket_rounded,
      );
    } else if (lowerName.contains('premier') || lowerName.contains('cpl') || index % 4 == 2) {
      return _CardTheme(
        trophyBg: const Color(0xFFF3E8FF),
        trophyColor: const Color(0xFF9333EA),
        watermarkColor: const Color(0xFFA855F7),
        watermarkIcon: Icons.stadium_outlined,
      );
    } else {
      return _CardTheme(
        trophyBg: const Color(0xFFF1F5F9),
        trophyColor: const Color(0xFF64748B),
        watermarkColor: const Color(0xFF94A3B8),
        watermarkIcon: Icons.emoji_events_outlined,
      );
    }
  }

  // --- Inline / Modal Edit Sheet (Persists to StorageService) ---
  void _showEditSheet(Tournament tournament, StorageService storage) {
    final nameCtrl = TextEditingController(text: tournament.name);
    final teamsCtrl = TextEditingController(text: tournament.teamsCount.toString());
    final matchesCtrl = TextEditingController(text: tournament.matchesCount.toString());
    final startCtrl = TextEditingController(text: tournament.startDate);
    final endCtrl = TextEditingController(text: tournament.endDate);
    String format = tournament.format;
    String status = tournament.status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Tournament',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  labelText: 'Tournament Name',
                  labelStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B)),
                  prefixIcon: const Icon(Icons.emoji_events_outlined, color: Color(0xFF028A6B)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF028A6B), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: ['T20', 'ODI', 'Test'].contains(format) ? format : 'T20',
                      dropdownColor: Colors.white,
                      decoration: InputDecoration(
                        labelText: 'Format',
                        labelStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ['T20', 'ODI', 'Test']
                          .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setModalState(() => format = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: ['Live', 'Upcoming', 'Completed'].contains(status) ? status : 'Upcoming',
                      dropdownColor: Colors.white,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        labelStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ['Live', 'Upcoming', 'Completed']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setModalState(() => status = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: teamsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Teams Count',
                        labelStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B)),
                        prefixIcon: const Icon(Icons.people_alt_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: matchesCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Matches Count',
                        labelStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B)),
                        prefixIcon: const Icon(Icons.sports_cricket_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: startCtrl,
                      decoration: InputDecoration(
                        labelText: 'Start Date (DD-MM-YYYY)',
                        labelStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B)),
                        prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: endCtrl,
                      decoration: InputDecoration(
                        labelText: 'End Date (DD-MM-YYYY)',
                        labelStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B)),
                        prefixIcon: const Icon(Icons.event_outlined, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final updated = Tournament(
                      id: tournament.id,
                      name: nameCtrl.text.trim().isEmpty ? tournament.name : nameCtrl.text.trim(),
                      format: format,
                      status: status,
                      teamsCount: int.tryParse(teamsCtrl.text.trim()) ?? tournament.teamsCount,
                      matchesCount: int.tryParse(matchesCtrl.text.trim()) ?? tournament.matchesCount,
                      startDate: startCtrl.text.trim().isEmpty ? tournament.startDate : startCtrl.text.trim(),
                      endDate: endCtrl.text.trim().isEmpty ? tournament.endDate : endCtrl.text.trim(),
                      participatingTeamIds: tournament.participatingTeamIds,
                    );

                    storage.updateTournament(updated);
                    Navigator.pop(ctx);
                    CustomNotification.show(
                      context,
                      'Tournament "${updated.name}" updated successfully!',
                      type: NotificationType.success,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF028A6B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Save Changes',
                    style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Delete Confirmation Dialog ---
  void _showDeleteConfirmDialog(Tournament tournament, StorageService storage) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE11D48), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete Tournament?',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${tournament.name}"? This action cannot be undone and will remove it from local storage.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF64748B),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              storage.deleteTournament(tournament.id);
              CustomNotification.show(
                context,
                'Tournament deleted from local records.',
                type: NotificationType.info,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // --- Filter Options Bottom Sheet ---
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Filter & Sort Tournaments',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'MATCH FORMAT',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['All', 'T20', 'ODI', 'Test'].map((format) {
                  final isSelected = _selectedFormatFilter == format;
                  return ChoiceChip(
                    label: Text(format),
                    selected: isSelected,
                    selectedColor: const Color(0xFFD1FAE5),
                    backgroundColor: Colors.white,
                    labelStyle: GoogleFonts.plusJakartaSans(
                      color: isSelected ? const Color(0xFF065F46) : const Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
                    ),
                    onSelected: (val) {
                      setSheetState(() => _selectedFormatFilter = format);
                      setState(() => _selectedFormatFilter = format);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text(
                'SORT BY',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  {'key': 'default', 'label': 'Default'},
                  {'key': 'name', 'label': 'Name (A-Z)'},
                  {'key': 'teams', 'label': 'Most Teams'},
                  {'key': 'matches', 'label': 'Most Matches'},
                ].map((s) {
                  final isSelected = _sortBy == s['key'];
                  return ChoiceChip(
                    label: Text(s['label']!),
                    selected: isSelected,
                    selectedColor: const Color(0xFFD1FAE5),
                    backgroundColor: Colors.white,
                    labelStyle: GoogleFonts.plusJakartaSans(
                      color: isSelected ? const Color(0xFF065F46) : const Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
                    ),
                    onSelected: (val) {
                      setSheetState(() => _sortBy = s['key']!);
                      setState(() => _sortBy = s['key']!);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selectedFormatFilter = 'All';
                          _sortBy = 'default';
                        });
                        Navigator.pop(ctx);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Reset Filters',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF028A6B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: Text(
                        'Apply',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_searchQuery.isNotEmpty) {
          setState(() {
            _searchController.clear();
          });
          return;
        }
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
        child: Consumer<StorageService>(
          builder: (context, storage, child) {
            final allTournaments = storage.tournaments;
            final filteredTournaments = _getFilteredTournaments(allTournaments);

            // Compute dynamic counts from locally stored data
            final totalCount = allTournaments.length;
            final liveCount = allTournaments.where((t) => t.status.toLowerCase() == 'live').length;
            final upcomingCount = allTournaments.where((t) => t.status.toLowerCase() == 'upcoming').length;
            final completedCount = allTournaments.where((t) => t.status.toLowerCase() == 'completed').length;

            return Stack(
              children: [
                Column(
                  children: [
                    // 1. Header (Matching Screenshot)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 16, 6),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: Color(0xFF0F172A),
                            ),
                            onPressed: () => Navigator.pop(context),
                            tooltip: 'Back',
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tournament List',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Manage and organize your tournaments',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Circular top right action button
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, AppRoutes.createTournament),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF028A6B), width: 1.5),
                                color: Colors.transparent,
                              ),
                              child: const Icon(
                                Icons.add_circle_outline_rounded,
                                color: Color(0xFF028A6B),
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 2. Search & Filter Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  color: const Color(0xFF0F172A),
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                  border: InputBorder.none,
                                  hintText: 'Search tournaments...',
                                  hintStyle: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF94A3B8),
                                    fontSize: 13,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search_rounded,
                                    color: Color(0xFF94A3B8),
                                    size: 20,
                                  ),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
                                          onPressed: () => _searchController.clear(),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _showFilterSheet,
                            child: Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: _selectedFormatFilter != 'All' || _sortBy != 'default'
                                    ? const Color(0xFFD1FAE5)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _selectedFormatFilter != 'All' || _sortBy != 'default'
                                      ? const Color(0xFFA7F3D0)
                                      : const Color(0xFFE2E8F0),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.tune_rounded,
                                color: _selectedFormatFilter != 'All' || _sortBy != 'default'
                                    ? const Color(0xFF028A6B)
                                    : const Color(0xFF334155),
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 3. Status Filter Chips (All, Live, Upcoming, Completed)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 12),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            _buildFilterChip('All', totalCount),
                            const SizedBox(width: 8),
                            _buildFilterChip('Live', liveCount),
                            const SizedBox(width: 8),
                            _buildFilterChip('Upcoming', upcomingCount),
                            const SizedBox(width: 8),
                            _buildFilterChip('Completed', completedCount),
                          ],
                        ),
                      ),
                    ),

                    // 4. Tournaments List View
                    Expanded(
                      child: filteredTournaments.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                              itemCount: filteredTournaments.length,
                              itemBuilder: (context, index) {
                                final tournament = filteredTournaments[index];
                                final theme = _getVisualTheme(index, tournament);
                                return _buildTournamentCard(
                                  context: context,
                                  tournament: tournament,
                                  theme: theme,
                                  storage: storage,
                                );
                              },
                            ),
                    ),
                  ],
                ),

                // 5. Persistent Bottom Bar: "{N} Tournaments" + "+ New Tournament" FAB
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC).withValues(alpha: 0.95),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${filteredTournaments.length} Tournaments',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, AppRoutes.createTournament),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF028A6B),
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF028A6B).withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  'New Tournament',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

  // --- Status Filter Chip Widget ---
  Widget _buildFilterChip(String title, int count) {
    final isSelected = _selectedStatusFilter.toLowerCase() == title.toLowerCase();

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatusFilter = title;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD1FAE5) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF028A6B).withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? const Color(0xFF065F46) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFA7F3D0) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Text(
                count.toString(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? const Color(0xFF065F46) : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Pixel-Perfect Tournament Card with Watermark Artwork ---
  Widget _buildTournamentCard({
    required BuildContext context,
    required Tournament tournament,
    required _CardTheme theme,
    required StorageService storage,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Watermark Wave and Icon in Background (Right side)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 140,
              child: CustomPaint(
                painter: _WatermarkWavePainter(color: theme.watermarkColor),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Opacity(
                      opacity: 0.16,
                      child: Icon(
                        theme.watermarkIcon,
                        size: 72,
                        color: theme.watermarkColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Card Foreground Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Trophy Box, Title, Status & Format, Menu
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Trophy Icon Box
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.trophyBg,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.emoji_events_rounded,
                            color: theme.trophyColor,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Title & Subtitle row
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tournament.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _buildStatusBadge(tournament.status),
                                const SizedBox(width: 8),
                                Text(
                                  tournament.format,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Trailing More Menu
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF94A3B8), size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onSelected: (action) {
                          if (action == 'edit') {
                            _showEditSheet(tournament, storage);
                          } else if (action == 'delete') {
                            _showDeleteConfirmDialog(tournament, storage);
                          } else if (action == 'toggle_status') {
                            final nextStatus = tournament.status == 'Live'
                                ? 'Completed'
                                : (tournament.status == 'Upcoming' ? 'Live' : 'Upcoming');
                            final updated = Tournament(
                              id: tournament.id,
                              name: tournament.name,
                              format: tournament.format,
                              status: nextStatus,
                              teamsCount: tournament.teamsCount,
                              matchesCount: tournament.matchesCount,
                              startDate: tournament.startDate,
                              endDate: tournament.endDate,
                              participatingTeamIds: tournament.participatingTeamIds,
                            );
                            storage.updateTournament(updated);
                            CustomNotification.show(
                              context,
                              'Status updated to "$nextStatus"',
                              type: NotificationType.info,
                            );
                          }
                        },
                        itemBuilder: (ctx) => [
                          PopupMenuItem(
                            value: 'toggle_status',
                            child: Row(
                              children: [
                                const Icon(Icons.swap_horiz_rounded, size: 16, color: Color(0xFF028A6B)),
                                const SizedBox(width: 8),
                                Text('Cycle Status', style: GoogleFonts.plusJakartaSans(fontSize: 13)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF334155)),
                                const SizedBox(width: 8),
                                Text('Edit Details', style: GoogleFonts.plusJakartaSans(fontSize: 13)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFE11D48)),
                                const SizedBox(width: 8),
                                Text('Delete', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFFE11D48))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Metadata Stats Row (Teams, Matches, Date)
                  Row(
                    children: [
                      _buildMetaItem(
                        icon: Icons.people_alt_outlined,
                        label: '${tournament.teamsCount} Teams',
                      ),
                      _buildMetaItem(
                        icon: Icons.public_outlined,
                        label: '${tournament.matchesCount} Matches',
                      ),
                      _buildMetaItem(
                        icon: Icons.calendar_month_outlined,
                        label: tournament.startDate.isNotEmpty ? tournament.startDate : 'TBD',
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // 3 Action Buttons Row: View, Edit, Delete (Matching Screenshot)
                  Row(
                    children: [
                      // View Button
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.tournamentDetail,
                              arguments: {
                                'id': tournament.id,
                                'name': tournament.name,
                                'format': tournament.format,
                                'teams': tournament.teamsCount.toString(),
                                'status': tournament.status,
                                'start': tournament.startDate,
                                'end': tournament.endDate,
                                'matches': tournament.matchesCount.toString(),
                              },
                            );
                          },
                          child: Container(
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.visibility_outlined, size: 15, color: Color(0xFF334155)),
                                const SizedBox(width: 5),
                                Text(
                                  'View',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF334155),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Edit Button (Soft Green)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showEditSheet(tournament, storage),
                          child: Container(
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFBBF7D0)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.edit_outlined, size: 15, color: Color(0xFF15803D)),
                                const SizedBox(width: 5),
                                Text(
                                  'Edit',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF15803D),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Delete Button (Soft Rose)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showDeleteConfirmDialog(tournament, storage),
                          child: Container(
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFECDD3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.delete_outline_rounded, size: 15, color: Color(0xFFE11D48)),
                                const SizedBox(width: 5),
                                Text(
                                  'Delete',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFE11D48),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Status Badge Component ---
  Widget _buildStatusBadge(String status) {
    Color bg;
    Color dotColor;
    Color textColor;
    String label = status;

    switch (status.toLowerCase()) {
      case 'live':
        bg = const Color(0xFFD1FAE5);
        dotColor = const Color(0xFF059669);
        textColor = const Color(0xFF047857);
        break;
      case 'completed':
        bg = const Color(0xFFF1F5F9);
        dotColor = const Color(0xFF64748B);
        textColor = const Color(0xFF475569);
        break;
      case 'upcoming':
      default:
        bg = const Color(0xFFDBEAFE);
        dotColor = const Color(0xFF2563EB);
        textColor = const Color(0xFF1D4ED8);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // --- Metadata item with icon and label ---
  Widget _buildMetaItem({required IconData icon, required String label}) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // --- Empty State ---
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Color(0xFFE0F2FE),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emoji_events_outlined, size: 42, color: Color(0xFF0284C7)),
            ),
            const SizedBox(height: 16),
            Text(
              'No Tournaments Found',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No tournament matches "$_searchQuery"'
                  : 'No tournaments match the selected filter.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 18),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _selectedStatusFilter = 'All';
                  _selectedFormatFilter = 'All';
                });
              },
              child: Text(
                'Reset Filters',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF028A6B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Visual Theme Configuration Model ---
class _CardTheme {
  final Color trophyBg;
  final Color trophyColor;
  final Color watermarkColor;
  final IconData watermarkIcon;

  _CardTheme({
    required this.trophyBg,
    required this.trophyColor,
    required this.watermarkColor,
    required this.watermarkIcon,
  });
}

// --- Custom Painter for Card Background Wave Watermark ---
class _WatermarkWavePainter extends CustomPainter {
  final Color color;
  _WatermarkWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Primary curved flowing wave
    final paint1 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withValues(alpha: 0.05),
          color.withValues(alpha: 0.16),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path1 = Path();
    path1.moveTo(size.width * 0.45, 0);
    path1.quadraticBezierTo(
      size.width * 0.05,
      size.height * 0.45,
      size.width * 0.35,
      size.height,
    );
    path1.lineTo(size.width, size.height);
    path1.lineTo(size.width, 0);
    path1.close();
    canvas.drawPath(path1, paint1);

    // Secondary subtle lower wave
    final paint2 = Paint()
      ..color = color.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(size.width * 0.25, size.height);
    path2.quadraticBezierTo(
      size.width * 0.6,
      size.height * 0.65,
      size.width,
      size.height * 0.85,
    );
    path2.lineTo(size.width, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant _WatermarkWavePainter oldDelegate) => oldDelegate.color != color;
}
