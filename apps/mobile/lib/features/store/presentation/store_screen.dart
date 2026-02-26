import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/di/di_container.dart';
import '../../../ui/theme/app_theme.dart';
import '../../monetization/iap_product.dart';
import '../application/store_controller.dart';
import '../application/store_view_state.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  static const double _maxContentWidth = 840;

  late final StoreController _controller;
  StoreViewState? _lastState;

  @override
  void initState() {
    super.initState();
    _controller = sl<StoreController>();
    _controller.stateListenable.addListener(_handleStateChange);
    unawaited(_controller.initialize());
  }

  @override
  void dispose() {
    _controller.stateListenable.removeListener(_handleStateChange);
    _controller.dispose();
    super.dispose();
  }

  void _handleStateChange() {
    final StoreViewState current = _controller.state;
    final StoreViewState? previous = _lastState;
    _lastState = current;

    if (!mounted ||
        current.message == null ||
        current.message == previous?.message) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(current.message!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store'),
        actions: <Widget>[
          IconButton(
            onPressed: _controller.restorePurchases,
            icon: const Icon(Icons.restore),
            tooltip: 'Restore purchases',
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    LuminaPalette.midnight,
                    LuminaPalette.deepNavy,
                    Color(0xFF18345A),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.35),
                  radius: 0.92,
                  colors: <Color>[
                    LuminaPalette.cyan.withOpacity(0.12),
                    LuminaPalette.violet.withOpacity(0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          ValueListenableBuilder<StoreViewState>(
            valueListenable: _controller.stateListenable,
            builder:
                (BuildContext context, StoreViewState state, Widget? child) {
              if (state.isLoading && state.products.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              return RefreshIndicator(
                onRefresh: _controller.refresh,
                child: Center(
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: _maxContentWidth),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: <Widget>[
                        _StoreHero(
                          ownedCount: state.ownedProductIds.length,
                          rolloutStrategy: state.rolloutStrategy,
                          offerStrategyVariant: state.offerStrategyVariant,
                          userSegment: state.userSegment,
                        ),
                        const SizedBox(height: 16),
                        ...state.products.map(
                          (IapProduct product) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ProductCard(
                              product: product,
                              isOwned:
                                  state.ownedProductIds.contains(product.id),
                              isRecommended:
                                  state.recommendedProductId == product.id,
                              isBusy: state.isPurchasing,
                              onBuy: () => _controller.purchaseProduct(product),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StoreHero extends StatelessWidget {
  const _StoreHero({
    required this.ownedCount,
    required this.rolloutStrategy,
    required this.offerStrategyVariant,
    required this.userSegment,
  });

  final int ownedCount;
  final String rolloutStrategy;
  final String offerStrategyVariant;
  final String userSegment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF1A3961),
            Color(0xFF285A93),
          ],
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x44111D30),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0x33FFFFFF),
            child: Icon(Icons.auto_awesome, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Ad-Free Premium Store',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Owned items: $ownedCount',
                  style: const TextStyle(
                    color: Color(0xFFDCEEFF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Strategy: ${rolloutStrategy.replaceAll('_', ' ')}',
                  style: const TextStyle(
                    color: Color(0xFFCAE4FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Targeting: ${offerStrategyVariant.replaceAll('_', ' ')} / $userSegment',
                  style: const TextStyle(
                    color: Color(0xFFCAE4FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.isOwned,
    required this.isRecommended,
    required this.isBusy,
    required this.onBuy,
  });

  final IapProduct product;
  final bool isOwned;
  final bool isRecommended;
  final bool isBusy;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final ButtonStyle buyButtonStyle = ButtonStyle(
      elevation: const WidgetStatePropertyAll<double>(0),
      minimumSize: const WidgetStatePropertyAll<Size>(Size(86, 44)),
      padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
        EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      shape: WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(11),
        ),
      ),
      textStyle: const WidgetStatePropertyAll<TextStyle>(
        TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      backgroundColor: WidgetStateProperty.resolveWith<Color>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return const Color(0xFFBAC8DA);
          }
          if (states.contains(WidgetState.pressed)) {
            return const Color(0xFF245082);
          }
          if (states.contains(WidgetState.hovered)) {
            return const Color(0xFF2A5A8D);
          }
          return const Color(0xFF2F5F95);
        },
      ),
      foregroundColor: WidgetStateProperty.resolveWith<Color>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return const Color(0xFF4A5E78);
          }
          return Colors.white;
        },
      ),
      overlayColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.pressed)) {
            return const Color(0x1FFFFFFF);
          }
          if (states.contains(WidgetState.focused)) {
            return const Color(0x14FFFFFF);
          }
          return null;
        },
      ),
    );

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(14),
      color: const Color(0xFFF2F7FF),
      shadowColor: isRecommended ? const Color(0x55274C78) : null,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFE4EEFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.palette_outlined,
                color: Color(0xFF2D5684),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          product.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (product.badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2F5D93),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            product.badge!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      if (isRecommended) ...<Widget>[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E775A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Recommended',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    product.description,
                    style: const TextStyle(
                      color: Color(0xFF4D6373),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: isOwned || isBusy ? null : onBuy,
              style: buyButtonStyle,
              child: Text(isOwned ? 'Owned' : product.priceLabel),
            ),
          ],
        ),
      ),
    );
  }
}
