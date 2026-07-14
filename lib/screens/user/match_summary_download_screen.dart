import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MatchSummaryDownloadScreen extends StatelessWidget {
  final Map<String, dynamic> matchDetails;

  const MatchSummaryDownloadScreen({Key? key, required this.matchDetails}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Summary & Download'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Downloading detailed PDF report...')),
              );
            },
            tooltip: 'Download Report',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMatchResultCard(context),
            const SizedBox(height: 16),
            _buildTopPerformersCard(context),
            const SizedBox(height: 16),
            _buildInningsSummaryCard(context, "India Innings", "245/8", "20.0 Overs"),
            const SizedBox(height: 16),
            _buildInningsSummaryCard(context, "Australia Innings", "230/9", "20.0 Overs"),
             const SizedBox(height: 16),
             _buildRunRateGraphCard(context),
             const SizedBox(height: 24),
             ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Downloading detailed PDF report...')),
                  );
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Download Full Match Report'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
             )
          ],
        ),
      ),
    );
  }

  Widget _buildMatchResultCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
             Text(
              "Match Result",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              "${matchDetails['title']} won by 15 runs", // Mock result
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
             Text(
              "Player of the Match: Virat Kohli",
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPerformersCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Top Performers",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildPerformerRow("Virat Kohli", "Batting", "82* (53)"),
            _buildPerformerRow("Jasprit Bumrah", "Bowling", "3/24 (4.0)"),
            _buildPerformerRow("Glenn Maxwell", "Batting", "65 (32)"),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformerRow(String name, String role, String stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(role, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Text(stats, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInningsSummaryCard(BuildContext context, String teamName, String score, String overs) {
     return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text(
                    teamName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "$score ($overs)",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
               ],
             ),
             const Divider(),
             const Text("Top Batsmen", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
             Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Player A"), const Text("45 (30)")]),
             Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Player B"), const Text("30 (20)")]),
             const SizedBox(height: 8),
             const Text("Top Bowlers", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
             Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Player X"), const Text("2/20")]),
          ],
        ),
      ),
    );
  }

  Widget _buildRunRateGraphCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Run Rate Comparison",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: 5,
                        getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 10)),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.withOpacity(0.2))),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 0),
                        FlSpot(5, 30),
                        FlSpot(10, 75),
                        FlSpot(15, 120),
                        FlSpot(20, 200), // Target/Score
                      ],
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.1)),
                    ),
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 0),
                        FlSpot(5, 45),
                        FlSpot(10, 80),
                        FlSpot(15, 130),
                        FlSpot(20, 185), // Score
                      ],
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: Colors.red.withOpacity(0.1)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
