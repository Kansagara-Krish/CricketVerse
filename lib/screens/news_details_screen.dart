import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';

class NewsDetailsScreen extends StatelessWidget {
  const NewsDetailsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240.0,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.bgDeep,
            elevation: 0,
            leading: CircleAvatar(
              backgroundColor: Colors.black38,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                'https://images.unsplash.com/photo-1540747737956-378724044282?q=80&w=600&auto=format&fit=crop',
                fit: BoxFit.cover,
              ),
            ),
          ),    
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'AI RESEARCH & ANALYSIS',
                      style: GoogleFonts.outfit(color: const Color(0xFF0284C7), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'How CricketVerse AI predicted the live win probability swing during final over.',
                    style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A), height: 1.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Published on July 9, 2026 • By AI Engine Core',
                    style: GoogleFonts.outfit(fontSize: 12, color: const Color(0x8A0F172A)),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: const Color(0x1A0F172A)),
                  const SizedBox(height: 20),
                  
                  _buildParagraph(
                    'In the high-stakes final over of the T20 World Cup, predictive algorithms were tested to their limit. Team India needed 16 runs off 6 balls against Australia. Our win probability model, utilizing historical bowler-batsman matchups, ball progression momentum, and stadium metrics, was continuously computing probability margins after each delivery.',
                  ),
                  _buildParagraph(
                    'When Virat Kohli struck a massive six on the second ball, the Win Probability index instantly shifted by 32% in favor of India, increasing from 38% to 70%. The model successfully simulated 10,000 game paths, determining that the batter\'s current control rating (92%) and the bowler\'s high-pressure error rate (14%) heavily favored the batting side.',
                  ),
                  _buildParagraph(
                    'By incorporating real-time feedback loops directly from the Match Scorer\'s console inputs, CricketVerse AI continues to provide fans with the most accurate, instantaneous win probability projections in modern digital sports broadcasting.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          color: const Color(0xFF0F172A).withOpacity(0.8),
          fontSize: 14,
          height: 1.6,
        ),
      ),
    );
  }
}
