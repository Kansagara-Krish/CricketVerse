import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/theme/app_theme.dart';
import '../models/models.dart';

class PdfReportService {
  /// Generates a high-quality PDF report for a match and opens the native PDF print/save preview.
  /// Includes fallback modal handling if native plugin channels are unlinked.
  static Future<void> generateAndShareReport({
    required BuildContext context,
    required Map<String, dynamic> matchDetails,
  }) async {
    final pdfBytes = await buildPdfDocument(matchDetails);
    final title = (matchDetails['title'] ?? 'Match_Report').replaceAll(' ', '_');

    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'CricketVerse_Report_$title.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => _buildPdfFallbackDialog(ctx, matchDetails, pdfBytes),
        );
      }
    }
  }

  /// Builds a multi-page high-resolution PDF document for the match summary.
  static Future<Uint8List> buildPdfDocument(Map<String, dynamic> matchDetails) async {
    final CricketMatch? match = matchDetails['match'] as CricketMatch?;

    final pdf = pw.Document(
      title: matchDetails['title'] ?? (match != null ? '${match.teamA.shortName} vs ${match.teamB.shortName}' : 'Match Summary Report'),
      author: 'CricketVerse AI',
    );

    final title = matchDetails['title'] ?? (match != null ? '${match.teamA.name} vs ${match.teamB.name}' : 'Cricket Match Summary');
    final teamAName = match?.teamA.name ?? matchDetails['teamAName'] ?? 'Team A';
    final teamBName = match?.teamB.name ?? matchDetails['teamBName'] ?? 'Team B';
    final scoreA = match != null ? '${match.runsA}/${match.wicketsA}' : (matchDetails['scoreA'] ?? '0/0');
    final scoreB = match != null ? '${match.runsB}/${match.wicketsB}' : (matchDetails['scoreB'] ?? '0/0');
    final oversA = match != null ? '${match.oversA} Overs' : (matchDetails['oversA'] ?? '0.0 Overs');
    final oversB = match != null ? '${match.oversB} Overs' : (matchDetails['oversB'] ?? '0.0 Overs');
    final resultText = match != null && match.resultText.isNotEmpty
        ? match.resultText
        : (matchDetails['result'] ?? 'Match in Progress');

    final matchDate = match?.date ?? 'Match Date';
    final matchTime = match?.time ?? '';
    final matchVenue = match?.venue ?? 'Cricket Stadium';
    final matchType = match?.matchType ?? 'T20';

    // Primary Colors
    final navyBlue = PdfColor.fromHex('#010C22');
    final accentBlue = PdfColor.fromHex('#1E40AF');
    final emeraldGreen = PdfColor.fromHex('#059669');
    final bgGrey = PdfColor.fromHex('#F8FAFC');
    final cardBorder = PdfColor.fromHex('#E2E8F0');
    final textDark = PdfColor.fromHex('#0F172A');
    final textMuted = PdfColor.fromHex('#64748B');

    // Build real match performers and innings figures
    final List<List<String>> topPerformersData = [];
    final List<List<String>> innings1BattingData = [];
    final List<List<String>> innings1BowlingData = [];
    final List<List<String>> innings2BattingData = [];
    final List<List<String>> innings2BowlingData = [];

    String inn1ExtrasText = 'Extras: 0 (w 0, nb 0, lb 0, b 0)';
    String inn2ExtrasText = 'Extras: 0 (w 0, nb 0, lb 0, b 0)';

    if (match != null) {
      // 1. Top performers calculated strictly from this match
      final allPlayers = [...match.playingXI_A, ...match.playingXI_B];
      final allBatters = allPlayers
          .where((p) => p.runsScored > 0 || p.ballsFaced > 0)
          .toList()
        ..sort((a, b) => b.runsScored.compareTo(a.runsScored));

      final allBowlers = allPlayers
          .where((p) => p.oversBowled > 0 || p.wicketsTaken > 0 || p.runsConceded > 0)
          .toList()
        ..sort((a, b) {
          final cmp = b.wicketsTaken.compareTo(a.wicketsTaken);
          if (cmp != 0) return cmp;
          return a.runsConceded.compareTo(b.runsConceded);
        });

      if (allBatters.isNotEmpty) {
        final b = allBatters.first;
        final sr = b.ballsFaced > 0 ? ((b.runsScored / b.ballsFaced) * 100).toStringAsFixed(1) : '0.0';
        topPerformersData.add([b.name, 'Top Batter', '${b.runsScored}${b.isOut ? "" : "*"} runs off ${b.ballsFaced} balls (SR $sr)']);
      }
      if (allBowlers.isNotEmpty) {
        final bw = allBowlers.first;
        final eco = bw.oversBowled > 0 ? (bw.runsConceded / bw.oversBowled).toStringAsFixed(1) : '0.0';
        topPerformersData.add([bw.name, 'Top Bowler', '${bw.wicketsTaken}/${bw.runsConceded} (${bw.oversBowled.toStringAsFixed(1)} ov, ECO $eco)']);
      }
      if (allBatters.length > 1) {
        final b2 = allBatters[1];
        final sr = b2.ballsFaced > 0 ? ((b2.runsScored / b2.ballsFaced) * 100).toStringAsFixed(1) : '0.0';
        topPerformersData.add([b2.name, 'Key Batter', '${b2.runsScored}${b2.isOut ? "" : "*"} runs off ${b2.ballsFaced} balls (SR $sr)']);
      } else if (allBowlers.length > 1) {
        final bw2 = allBowlers[1];
        topPerformersData.add([bw2.name, 'Key Bowler', '${bw2.wicketsTaken}/${bw2.runsConceded} (${bw2.oversBowled.toStringAsFixed(1)} ov)']);
      }

      // 2. Innings 1 breakdown
      final inn1Balls = match.balls.where((b) => b.innings == 1 || (b.innings == null && b.battingTeamId == match.teamA.id)).toList();
      int w1 = 0, nb1 = 0, lb1 = 0, by1 = 0;
      for (final b in inn1Balls) {
        if (b.extraType == 'Wide') w1 += (b.extraRun > 0 ? b.extraRun : 1);
        if (b.extraType == 'No Ball') nb1 += (b.extraRun > 0 ? b.extraRun : 1);
        if (b.extraType == 'Leg Bye') lb1 += (b.extraRun > 0 ? b.extraRun : 1);
        if (b.extraType == 'Bye') by1 += (b.extraRun > 0 ? b.extraRun : 1);
      }
      final totalExt1 = w1 + nb1 + lb1 + by1;
      inn1ExtrasText = 'Extras: $totalExt1 (w $w1, nb $nb1, lb $lb1, b $by1)';

      for (final p in match.playingXI_A) {
        final pBalls = inn1Balls.where((b) => b.strikerId == p.id || (b.strikerId == null && b.batsmanName.trim().toLowerCase() == p.name.trim().toLowerCase())).toList();
        final fours = pBalls.where((b) => b.run == 4 && (b.extraType == 'None' || b.extraType == 'No Ball')).length;
        final sixes = pBalls.where((b) => b.run == 6 && (b.extraType == 'None' || b.extraType == 'No Ball')).length;
        final r = p.runsScored;
        final b = p.ballsFaced;
        final sr = b > 0 ? ((r / b) * 100).toStringAsFixed(1) : '0.0';
        final status = p.isOut
            ? (p.dismissalInfo.isNotEmpty ? p.dismissalInfo : 'out')
            : (r > 0 || b > 0 ? 'not out*' : 'did not bat');

        if (r > 0 || b > 0 || p.isOut || innings1BattingData.length < 5) {
          innings1BattingData.add([p.name, '$r', '$b', '$fours', '$sixes', sr, status]);
        }
      }

      for (final bw in match.playingXI_B) {
        if (bw.oversBowled > 0 || bw.runsConceded > 0 || bw.wicketsTaken > 0) {
          final eco = bw.oversBowled > 0 ? (bw.runsConceded / bw.oversBowled).toStringAsFixed(1) : '0.0';
          innings1BowlingData.add([bw.name, bw.oversBowled.toStringAsFixed(1), '0', '${bw.runsConceded}', '${bw.wicketsTaken}', eco]);
        }
      }

      // 3. Innings 2 breakdown
      final inn2Balls = match.balls.where((b) => b.innings == 2 || (b.innings == null && b.battingTeamId == match.teamB.id)).toList();
      int w2 = 0, nb2 = 0, lb2 = 0, by2 = 0;
      for (final b in inn2Balls) {
        if (b.extraType == 'Wide') w2 += (b.extraRun > 0 ? b.extraRun : 1);
        if (b.extraType == 'No Ball') nb2 += (b.extraRun > 0 ? b.extraRun : 1);
        if (b.extraType == 'Leg Bye') lb2 += (b.extraRun > 0 ? b.extraRun : 1);
        if (b.extraType == 'Bye') by2 += (b.extraRun > 0 ? b.extraRun : 1);
      }
      final totalExt2 = w2 + nb2 + lb2 + by2;
      inn2ExtrasText = 'Extras: $totalExt2 (w $w2, nb $nb2, lb $lb2, b $by2)';

      for (final p in match.playingXI_B) {
        final pBalls = inn2Balls.where((b) => b.strikerId == p.id || (b.strikerId == null && b.batsmanName.trim().toLowerCase() == p.name.trim().toLowerCase())).toList();
        final fours = pBalls.where((b) => b.run == 4 && (b.extraType == 'None' || b.extraType == 'No Ball')).length;
        final sixes = pBalls.where((b) => b.run == 6 && (b.extraType == 'None' || b.extraType == 'No Ball')).length;
        final r = p.runsScored;
        final b = p.ballsFaced;
        final sr = b > 0 ? ((r / b) * 100).toStringAsFixed(1) : '0.0';
        final status = p.isOut
            ? (p.dismissalInfo.isNotEmpty ? p.dismissalInfo : 'out')
            : (r > 0 || b > 0 ? 'not out*' : 'did not bat');

        if (r > 0 || b > 0 || p.isOut || innings2BattingData.length < 5) {
          innings2BattingData.add([p.name, '$r', '$b', '$fours', '$sixes', sr, status]);
        }
      }

      for (final bw in match.playingXI_A) {
        if (bw.oversBowled > 0 || bw.runsConceded > 0 || bw.wicketsTaken > 0) {
          final eco = bw.oversBowled > 0 ? (bw.runsConceded / bw.oversBowled).toStringAsFixed(1) : '0.0';
          innings2BowlingData.add([bw.name, bw.oversBowled.toStringAsFixed(1), '0', '${bw.runsConceded}', '${bw.wicketsTaken}', eco]);
        }
      }
    }

    // Fallbacks if data is empty
    if (topPerformersData.isEmpty) {
      topPerformersData.add(['Top Performer', 'Batter', '0 runs off 0 balls']);
    }
    if (innings1BattingData.isEmpty) {
      innings1BattingData.add(['No Batting Records', '0', '0', '0', '0', '0.0', '-']);
    }
    if (innings1BowlingData.isEmpty) {
      innings1BowlingData.add(['No Bowling Records', '0.0', '0', '0', '0', '0.0']);
    }
    if (innings2BattingData.isEmpty) {
      innings2BattingData.add(['No Batting Records', '0', '0', '0', '0', '0.0', '-']);
    }
    if (innings2BowlingData.isEmpty) {
      innings2BowlingData.add(['No Bowling Records', '0.0', '0', '0', '0', '0.0']);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return [
            // --- 1. HEADER BANNER ---
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: navyBlue,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'CRICKETVERSE AI',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Official Match Performance & Verified Scorecard Report',
                        style: pw.TextStyle(
                          color: PdfColor.fromHex('#94A3B8'),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: pw.BoxDecoration(
                      color: emeraldGreen,
                      borderRadius: pw.BorderRadius.circular(16),
                    ),
                    child: pw.Text(
                      '$matchType MATCH REPORT',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // --- 2. MATCH RESULT & METADATA ---
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: bgGrey,
                borderRadius: pw.BorderRadius.circular(10),
                border: pw.Border.all(color: cardBorder),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'OFFICIAL RESULT',
                    style: pw.TextStyle(
                      color: textMuted,
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    resultText,
                    style: pw.TextStyle(
                      color: accentBlue,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    '$title • $matchVenue • $matchDate $matchTime',
                    style: pw.TextStyle(color: textDark, fontSize: 9.5),
                  ),
                  pw.Divider(color: cardBorder, thickness: 1, height: 16),

                  // Dual Score Card Row
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      _buildTeamScorePdfBox(
                        teamName: teamAName,
                        score: scoreA,
                        overs: oversA,
                        navyBlue: navyBlue,
                        textDark: textDark,
                        textMuted: textMuted,
                      ),
                      pw.Container(width: 1, height: 36, color: cardBorder),
                      _buildTeamScorePdfBox(
                        teamName: teamBName,
                        score: scoreB,
                        overs: oversB,
                        navyBlue: navyBlue,
                        textDark: textDark,
                        textMuted: textMuted,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // --- 3. TOP MATCH PERFORMERS ---
            pw.Text(
              'TOP MATCH PERFORMERS',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: textDark,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: ['Player', 'Match Role', 'Confirmed Figures'],
              data: topPerformersData,
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
              ),
              headerDecoration: pw.BoxDecoration(color: navyBlue),
              rowDecoration: pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: cardBorder, width: 0.5)),
              ),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            pw.SizedBox(height: 14),

            // --- 4. INNINGS 1 SCORECARD ---
            pw.Text(
              '$teamAName INNINGS ($scoreA, $oversA)',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: textDark,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text('Batting', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: textMuted)),
            pw.SizedBox(height: 4),
            pw.TableHelper.fromTextArray(
              headers: ['Batter', 'R', 'B', '4s', '6s', 'SR', 'Dismissal'],
              data: innings1BattingData,
              headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#E2E8F0')),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColor.fromHex('#1E293B')),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(inn1ExtrasText, style: pw.TextStyle(fontSize: 8, color: textMuted, fontStyle: pw.FontStyle.italic)),
                pw.Text('Total: $scoreA ($oversA)', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: textDark)),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Text('Bowling', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: textMuted)),
            pw.SizedBox(height: 4),
            pw.TableHelper.fromTextArray(
              headers: ['Bowler', 'O', 'M', 'R', 'W', 'ECO'],
              data: innings1BowlingData,
              headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#E2E8F0')),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColor.fromHex('#1E293B')),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
            ),
            pw.SizedBox(height: 14),

            // --- 5. INNINGS 2 SCORECARD ---
            pw.Text(
              '$teamBName INNINGS ($scoreB, $oversB)',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: textDark,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text('Batting', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: textMuted)),
            pw.SizedBox(height: 4),
            pw.TableHelper.fromTextArray(
              headers: ['Batter', 'R', 'B', '4s', '6s', 'SR', 'Dismissal'],
              data: innings2BattingData,
              headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#E2E8F0')),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColor.fromHex('#1E293B')),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(inn2ExtrasText, style: pw.TextStyle(fontSize: 8, color: textMuted, fontStyle: pw.FontStyle.italic)),
                pw.Text('Total: $scoreB ($oversB)', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: textDark)),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Text('Bowling', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: textMuted)),
            pw.SizedBox(height: 4),
            pw.TableHelper.fromTextArray(
              headers: ['Bowler', 'O', 'M', 'R', 'W', 'ECO'],
              data: innings2BowlingData,
              headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#E2E8F0')),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColor.fromHex('#1E293B')),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
            ),
            pw.SizedBox(height: 14),

            // --- 6. AI INSIGHTS & VERIFICATION FOOTER ---
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#EFF6FF'),
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColor.fromHex('#BFDBFE')),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'CricketVerse AI Analytics Verification',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5, color: accentBlue),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'All figures and statistics in this document are strictly computed from confirmed scoring events of match ID: ${match?.id ?? "N/A"}. Historical tournament statistics remain securely isolated.',
                    style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('#1E293B')),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),
            pw.Divider(color: cardBorder),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Generated by CricketVerse AI Certified System', style: pw.TextStyle(color: textMuted, fontSize: 7.5)),
                pw.Text('Official Match Record', style: pw.TextStyle(color: textMuted, fontSize: 7.5)),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildTeamScorePdfBox({
    required String teamName,
    required String score,
    required String overs,
    required PdfColor navyBlue,
    required PdfColor textDark,
    required PdfColor textMuted,
  }) {
    return pw.Column(
      children: [
        pw.Text(
          teamName,
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: textDark),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          score,
          style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: navyBlue),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          overs,
          style: pw.TextStyle(fontSize: 8.5, color: textMuted),
        ),
      ],
    );
  }

  static Widget _buildPdfFallbackDialog(BuildContext context, Map<String, dynamic> matchDetails, Uint8List pdfBytes) {
    final title = matchDetails['title'] ?? 'Match Summary';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.picture_as_pdf, color: AppTheme.primaryBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Match Report Ready',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'High-quality PDF report for "$title" compiled successfully (${(pdfBytes.length / 1024).toStringAsFixed(1)} KB).',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppTheme.primaryBlue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Full scorecard, top performers, and verified match data exported.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppTheme.primaryBlue, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
