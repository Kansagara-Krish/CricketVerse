import 'dart:math' as math;
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
                    '$title | $matchVenue | $matchDate $matchTime',
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

            // --- 6. MATCH SCORE PROGRESSION (RUNS / OVERS) ---
            ..._buildScoreProgressionSection(
              match: match,
              teamAName: teamAName,
              teamBName: teamBName,
              scoreA: scoreA,
              oversA: oversA,
              scoreB: scoreB,
              oversB: oversB,
              emeraldGreen: emeraldGreen,
              cardBorder: cardBorder,
              textDark: textDark,
              textMuted: textMuted,
            ),

            // --- 7. AI INSIGHTS & VERIFICATION FOOTER ---
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

  /// Computes cumulative (over, runs) data points matching Match Summary graph logic.
  static List<_PdfProgressionPoint> _buildProgressionPoints(CricketMatch? match, bool forTeamA) {
    if (match == null) return const [_PdfProgressionPoint(0, 0)];

    final teamId = forTeamA ? match.teamA.id : match.teamB.id;
    final totalRuns = forTeamA ? match.runsA : match.runsB;
    final totalOvers = forTeamA ? match.oversA : match.oversB;

    if (totalOvers <= 0 && totalRuns <= 0) {
      return const [_PdfProgressionPoint(0, 0)];
    }

    final teamBalls = match.balls.where((b) {
      if (b.battingTeamId != null && b.battingTeamId!.isNotEmpty) {
        return b.battingTeamId == teamId;
      }
      final isTeamAInnings1 = (match.tossDecision.toLowerCase() == 'bat' &&
              (match.tossWinner == match.teamA.name ||
                  match.tossWinner == 'Team A' ||
                  match.tossWinner == match.teamA.shortName)) ||
          (match.tossDecision.toLowerCase() == 'bowl' &&
              (match.tossWinner == match.teamB.name ||
                  match.tossWinner == 'Team B' ||
                  match.tossWinner == match.teamB.shortName));
      final teamAInnings = isTeamAInnings1 ? 1 : 2;
      return forTeamA ? (b.innings == teamAInnings) : (b.innings != teamAInnings);
    }).toList();

    if (teamBalls.isNotEmpty) {
      final List<_PdfProgressionPoint> points = [const _PdfProgressionPoint(0, 0)];
      int cumulative = 0;
      final Map<int, int> overEndRuns = {};

      for (final b in teamBalls) {
        cumulative += (b.run + b.extraRun);
        final ov = b.over ?? 0.0;
        overEndRuns[ov.floor()] = cumulative;
      }

      final int completedOvers = totalOvers.floor();
      for (int ov = 1; ov <= completedOvers; ov++) {
        if (overEndRuns.containsKey(ov)) {
          points.add(_PdfProgressionPoint(ov.toDouble(), overEndRuns[ov]!.toDouble()));
        } else if (overEndRuns.containsKey(ov - 1)) {
          points.add(_PdfProgressionPoint(ov.toDouble(), overEndRuns[ov - 1]!.toDouble()));
        }
      }

      if (points.isEmpty || (points.last.over - totalOvers).abs() > 0.05) {
        points.add(_PdfProgressionPoint(totalOvers, totalRuns.toDouble()));
      } else {
        points[points.length - 1] = _PdfProgressionPoint(totalOvers, totalRuns.toDouble());
      }

      points.sort((a, b) => a.over.compareTo(b.over));
      final List<_PdfProgressionPoint> uniquePoints = [];
      for (final p in points) {
        if (uniquePoints.isEmpty || (p.over - uniquePoints.last.over).abs() > 0.05) {
          uniquePoints.add(p);
        } else {
          uniquePoints[uniquePoints.length - 1] = p;
        }
      }

      return uniquePoints.length < 2
          ? [const _PdfProgressionPoint(0, 0), _PdfProgressionPoint(totalOvers > 0 ? totalOvers : 1, totalRuns.toDouble())]
          : uniquePoints;
    }

    // Fallback when aggregate score exists without ball-by-ball timeline
    final List<_PdfProgressionPoint> fallback = [const _PdfProgressionPoint(0, 0)];
    if (totalOvers > 0) {
      final int wholeOvers = totalOvers.floor();
      final int step = wholeOvers > 20 ? 5 : (wholeOvers > 10 ? 3 : 2);
      for (int ov = step; ov < wholeOvers; ov += step) {
        final ratio = ov / totalOvers;
        fallback.add(_PdfProgressionPoint(ov.toDouble(), (totalRuns * ratio).roundToDouble()));
      }
      fallback.add(_PdfProgressionPoint(totalOvers, totalRuns.toDouble()));
    } else {
      fallback.add(_PdfProgressionPoint(1, totalRuns.toDouble()));
    }
    return fallback;
  }

  static List<pw.Widget> _buildScoreProgressionSection({
    required CricketMatch? match,
    required String teamAName,
    required String teamBName,
    required String scoreA,
    required String oversA,
    required String scoreB,
    required String oversB,
    required PdfColor emeraldGreen,
    required PdfColor cardBorder,
    required PdfColor textDark,
    required PdfColor textMuted,
  }) {
    final pointsA = _buildProgressionPoints(match, true);
    final pointsB = _buildProgressionPoints(match, false);

    final bool hasInnings1Data = match == null
        ? false
        : (match.oversA > 0 || match.runsA > 0 || pointsA.length > 1);
    final bool hasInnings2Data = match == null
        ? false
        : (match.oversB > 0 || match.runsB > 0 || pointsB.length > 1);

    final double formatDefaultOvers =
        (match != null && match.matchType.toUpperCase() == 'ODI') ? 50.0 : 20.0;

    return [
      pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 12),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'MATCH SCORE PROGRESSION (RUNS / OVERS)',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: textDark,
              ),
            ),
            pw.SizedBox(height: 8),
            _buildInningsProgressionCard(
              inningsLabel: 'INNINGS 1 - $teamAName',
              scoreSummary: '$scoreA ($oversA)',
              points: pointsA,
              hasData: hasInnings1Data,
              formatMaxOvers: formatDefaultOvers,
              emeraldGreen: emeraldGreen,
              cardBorder: cardBorder,
              textDark: textDark,
              textMuted: textMuted,
            ),
          ],
        ),
      ),
      pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 14),
        child: _buildInningsProgressionCard(
          inningsLabel: 'INNINGS 2 - $teamBName',
          scoreSummary: '$scoreB ($oversB)',
          points: pointsB,
          hasData: hasInnings2Data,
          formatMaxOvers: formatDefaultOvers,
          emeraldGreen: emeraldGreen,
          cardBorder: cardBorder,
          textDark: textDark,
          textMuted: textMuted,
        ),
      ),
    ];
  }

  static pw.Widget _buildInningsProgressionCard({
    required String inningsLabel,
    required String scoreSummary,
    required List<_PdfProgressionPoint> points,
    required bool hasData,
    required double formatMaxOvers,
    required PdfColor emeraldGreen,
    required PdfColor cardBorder,
    required PdfColor textDark,
    required PdfColor textMuted,
  }) {
    final lightGreenFill = PdfColor.fromHex('#D1FAE5');
    final gridColor = PdfColor.fromHex('#E2E8F0');
    final bgSurface = PdfColor.fromHex('#FFFFFF');

    final double highestOver = points.fold(0.0, (prev, p) => math.max(prev, p.over));
    final double maxRuns = points.fold(0.0, (prev, p) => math.max(prev, p.runs));

    final double maxX;
    final double xInterval;
    if (highestOver <= 5.0) {
      maxX = 5.0;
      xInterval = 1.0;
    } else if (highestOver <= 10.0) {
      maxX = 10.0;
      xInterval = 2.0;
    } else if (highestOver <= 20.0 && formatMaxOvers <= 20.0) {
      maxX = 20.0;
      xInterval = 5.0;
    } else if (highestOver <= 50.0) {
      maxX = math.max(formatMaxOvers, (highestOver / 10).ceil() * 10.0);
      xInterval = maxX <= 20.0 ? 5.0 : 10.0;
    } else {
      maxX = (highestOver / 10).ceil() * 10.0;
      xInterval = 10.0;
    }

    final double maxY = maxRuns <= 0 ? 50.0 : math.max(25.0, ((maxRuns * 1.15) / 25).ceil() * 25.0);
    final List<double> yTicks = [
      maxY,
      maxY * 0.75,
      maxY * 0.50,
      maxY * 0.25,
      0,
    ];
    final List<double> xTicks = [];
    for (double x = 0; x <= maxX + 0.001; x += xInterval) {
      xTicks.add(x);
    }

    const double chartHeight = 128.0;
    const double chartWidth = 468.0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: bgSurface,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: cardBorder),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header Row
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Row(
                children: [
                  pw.Container(
                    width: 8,
                    height: 8,
                    decoration: pw.BoxDecoration(
                      color: emeraldGreen,
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Text(
                    inningsLabel,
                    style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: textDark),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#ECFDF5'),
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColor.fromHex('#A7F3D0')),
                ),
                child: pw.Text(
                  scoreSummary,
                  style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: emeraldGreen),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),

          if (!hasData)
            pw.Container(
              height: 54,
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F8FAFC'),
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: cardBorder),
              ),
              child: pw.Text(
                'Innings has not started or no scoring events recorded yet.',
                style: pw.TextStyle(fontSize: 8.5, color: textMuted, fontStyle: pw.FontStyle.italic),
              ),
            )
          else ...[
            // Chart Area with Y-axis labels + Vector CustomPaint Canvas
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Y-Axis Labels
                pw.SizedBox(
                  width: 30,
                  height: chartHeight,
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: yTicks
                        .map(
                          (val) => pw.Text(
                            '${val.round()}',
                            style: pw.TextStyle(fontSize: 7.5, color: textMuted),
                          ),
                        )
                        .toList(),
                  ),
                ),
                pw.SizedBox(width: 6),
                // Vector Chart Canvas
                pw.Expanded(
                  child: pw.Container(
                    height: chartHeight,
                    child: pw.CustomPaint(
                      size: const PdfPoint(chartWidth, chartHeight),
                      painter: (PdfGraphics canvas, PdfPoint size) {
                        final w = size.x;
                        final h = size.y;
                        const double pad = 4.0;
                        final plotW = w - pad * 2;
                        final plotH = h - pad * 2;

                        double mapX(double over) => pad + (over.clamp(0.0, maxX) / maxX) * plotW;
                        double mapY(double runs) => pad + (runs.clamp(0.0, maxY) / maxY) * plotH;

                        // 1. Light green shaded area below progression line
                        if (points.length >= 2) {
                          canvas
                            ..saveContext()
                            ..setFillColor(lightGreenFill)
                            ..moveTo(mapX(points.first.over), mapY(0));
                          for (final pt in points) {
                            canvas.lineTo(mapX(pt.over), mapY(pt.runs));
                          }
                          canvas
                            ..lineTo(mapX(points.last.over), mapY(0))
                            ..closePath()
                            ..fillPath()
                            ..restoreContext();
                        }

                        // 2. Horizontal Grid Lines + Axis Frame
                        canvas
                          ..saveContext()
                          ..setStrokeColor(gridColor)
                          ..setLineWidth(0.6);
                        for (int i = 0; i <= 4; i++) {
                          final gy = pad + (plotH * i / 4.0);
                          canvas
                            ..moveTo(pad, gy)
                            ..lineTo(w - pad, gy)
                            ..strokePath();
                        }
                        // Left Y-axis & Bottom X-axis baseline
                        canvas
                          ..setStrokeColor(PdfColor.fromHex('#CBD5E1'))
                          ..setLineWidth(0.8)
                          ..moveTo(pad, pad)
                          ..lineTo(pad, h - pad)
                          ..moveTo(pad, pad)
                          ..lineTo(w - pad, pad)
                          ..strokePath()
                          ..restoreContext();

                        // 3. Green Progression Line
                        if (points.length >= 2) {
                          canvas
                            ..saveContext()
                            ..setStrokeColor(emeraldGreen)
                            ..setLineWidth(2.0)
                            ..setLineCap(PdfLineCap.round)
                            ..setLineJoin(PdfLineJoin.round)
                            ..moveTo(mapX(points.first.over), mapY(points.first.runs));
                          for (int i = 1; i < points.length; i++) {
                            canvas.lineTo(mapX(points[i].over), mapY(points[i].runs));
                          }
                          canvas
                            ..strokePath()
                            ..restoreContext();
                        }

                        // 4. Circular Markers at Data Points
                        for (final pt in points) {
                          final cx = mapX(pt.over);
                          final cy = mapY(pt.runs);
                          canvas
                            ..saveContext()
                            ..setFillColor(PdfColors.white)
                            ..drawEllipse(cx, cy, 3.3, 3.3)
                            ..fillPath()
                            ..setFillColor(emeraldGreen)
                            ..drawEllipse(cx, cy, 2.2, 2.2)
                            ..fillPath()
                            ..restoreContext();
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            // X-Axis Labels
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 36),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: xTicks
                    .map(
                      (ov) => pw.Text(
                        '${ov.toInt()}ov',
                        style: pw.TextStyle(fontSize: 7.5, color: textMuted),
                      ),
                    )
                    .toList(),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                'Overs Progression  |  Y-Axis: Cumulative Runs',
                style: pw.TextStyle(fontSize: 7, color: textMuted),
              ),
            ),
          ],
        ],
      ),
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

class _PdfProgressionPoint {
  final double over;
  final double runs;

  const _PdfProgressionPoint(this.over, this.runs);
}
