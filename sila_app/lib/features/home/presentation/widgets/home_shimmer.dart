import 'package:flutter/material.dart';
import 'package:sila_app/core/presentation/widgets/sila_shimmer.dart';

class HomeShimmer extends StatelessWidget {
  const HomeShimmer._({
    required this.height,
    this.borderRadius = 28,
    this.margin = const EdgeInsets.only(bottom: 24),
  });

  final double height;
  final double borderRadius;
  final EdgeInsets margin;

  factory HomeShimmer.prayer() => const HomeShimmer._(height: 110, borderRadius: 16);
  factory HomeShimmer.wird() => const HomeShimmer._(height: 280, borderRadius: 28);
  factory HomeShimmer.streak() => const HomeShimmer._(height: 90, borderRadius: 20);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: SilaShimmer(
        width: double.infinity,
        height: height,
        borderRadius: borderRadius,
      ),
    );
  }
}
