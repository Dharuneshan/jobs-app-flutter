import 'package:flutter/material.dart';

class PricingPage extends StatelessWidget {
  final void Function(String plan)? onPlanSelected;
  const PricingPage({Key? key, this.onPlanSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Color palette
    const Color primaryBlue = Color(0xFF0044CC);
    const Color lightBlue = Color(0xFFCFDFFE);
    const Color veryLightBlue = Color(0xFFF3F7FF);
    const Color gold = Color(0xFFFFB800);
    const Color green = Color(0xFF33CC33);

    Widget planCard({
      required String title,
      required String price,
      required List<Widget> features,
      required VoidCallback onSelect,
      Color? badgeColor,
      IconData? badgeIcon,
      bool isSelected = false,
    }) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: lightBlue,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryBlue : lightBlue,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const Spacer(),
                      if (badgeIcon != null && badgeColor != null)
                        Container(
                          decoration: BoxDecoration(
                            color: badgeColor,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(6),
                          child: Icon(badgeIcon, color: Colors.white, size: 20),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    price,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      color: primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...features,
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: onSelect,
                      child: const Text('Select Plan',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget customSolutionCard() {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: veryLightBlue,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Need Custom Solutions?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'For customized options and bulk recruitment, contact our team',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.phone, color: primaryBlue),
                SizedBox(width: 8),
                Text(
                  '+91 1234567890',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: primaryBlue),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  // TODO: Implement contact action
                },
                child: const Text('Contact Team',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: veryLightBlue,
      appBar: AppBar(
        title: const Text('Choose Your Plan',
            style: TextStyle(color: Colors.black)),
        backgroundColor: veryLightBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select the perfect plan for your recruitment needs',
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            planCard(
              title: 'Silver Plan',
              price: '₹59',
              features: const [
                _PlanFeature(icon: Icons.check, text: '1 job postings'),
                _PlanFeature(
                    icon: Icons.filter_alt, text: 'Basic candidate filtering'),
                _PlanFeature(
                    icon: Icons.access_time, text: '5 - day listing duration'),
                _PlanFeature(icon: Icons.call, text: 'Call Support'),
                _PlanFeature(
                    icon: Icons.person, text: '5 X Candidate Profile Views'),
              ],
              onSelect: () => Navigator.pop(context, 'silver'),
              badgeColor: gold,
              badgeIcon: Icons.emoji_events,
            ),
            planCard(
              title: 'Gold Plan',
              price: '₹1,499',
              features: const [
                _PlanFeature(icon: Icons.check, text: '5 job postings'),
                _PlanFeature(
                    icon: Icons.filter_alt,
                    text: 'Advanced candidate filtering'),
                _PlanFeature(
                    icon: Icons.access_time, text: '30-day listing duration'),
                _PlanFeature(
                    icon: Icons.email, text: 'Priority email & phone support'),
                _PlanFeature(icon: Icons.star, text: 'Featured listings'),
                _PlanFeature(
                    icon: Icons.person, text: '20 X Candidate Profile Views'),
              ],
              onSelect: () => Navigator.pop(context, 'gold'),
              badgeColor: gold,
              badgeIcon: Icons.star,
            ),
            const SizedBox(height: 8),
            customSolutionCard(),
          ],
        ),
      ),
    );
  }
}

class _PlanFeature extends StatelessWidget {
  final IconData icon;
  final String text;
  const _PlanFeature({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black54),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
