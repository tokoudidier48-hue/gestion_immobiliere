import 'package:flutter/material.dart';

// ─── Badge coloré (OCCUPÉ, LIBRE, CHAMBRE…) ──────────────────────────────────

const Color kPrimary      = Color(0xFF2563EB);
const Color kLibreGreen   = Color(0xFF16A34A);
const Color kOccupeOrange = Color(0xFFEA580C);
const Color kBackground   = Color(0xFFF3F4F6);
const Color kTextDark     = Color(0xFF111827);
const Color kTextMid      = Color(0xFF6B7280);
const Color kDivider      = Color(0xFFE5E7EB);
const Color kCardBg       = Colors.white;
const Color kBadgeChambre = Color(0xFF06B6D4);
class TopBadge extends StatelessWidget {
  final String label;
  final Color color;

  const TopBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── Titre de section ─────────────────────────────────────────────────────────

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: kTextMid,
        letterSpacing: 1.0,
      ),
    );
  }
}

// ─── Item statut (icône + label + valeur) ─────────────────────────────────────

class StatutItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;

  const StatutItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 11, color: kTextMid)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

// ─── Ligne label ↔ valeur ─────────────────────────────────────────────────────

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: kTextMid)),
        Text(
          value,
          style: valueStyle ??
              const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kTextDark,
              ),
        ),
      ],
    );
  }
}

// ─── Carte section (fond blanc + padding) ─────────────────────────────────────

class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: kCardBg,
      padding: padding,
      child: child,
    );
  }
}

// ─── Ligne info locataire (label à gauche, valeur à droite) ──────────────────

class LocataireInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const LocataireInfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: kTextMid),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: kTextDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}