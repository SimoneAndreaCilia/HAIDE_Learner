import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class UnrollingScrollDialog extends StatefulWidget {
  final String title;
  final String description;
  final VoidCallback onStart;

  const UnrollingScrollDialog({
    super.key,
    required this.title,
    required this.description,
    required this.onStart,
  });

  @override
  State<UnrollingScrollDialog> createState() => _UnrollingScrollDialogState();
}

class _UnrollingScrollDialogState extends State<UnrollingScrollDialog>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heightAnimation;
  late Animation<double> _contentOpacityAnimation;

  // Scroll Indicator Logic
  final ScrollController _scrollController = ScrollController();
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  bool _showScrollIndicator = false;

  // Track if we are currently reversing to prevent loops
  bool _isReversing = false;

  // Maximum height for the body content
  final double _maxBodyHeight = 450.0;

  // Constant width for all scroll parts
  static const double scrollWidth = 450.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Animate height from 0 to max
    _heightAnimation = Tween<double>(begin: 0.0, end: _maxBodyHeight).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeInOutCubic),
      ),
    );

    _contentOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.6,
          1.0,
          curve: Curves.easeIn,
        ), // Start fading in earlier
      ),
    );

    // Start animation immediately upon showing
    _controller.forward();

    // Scroll Indicator Bounce Animation
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    // check if we need to show scroll indicator after main animation
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _checkScrollIndicator();
      }
    });
  }

  void _checkScrollIndicator() {
    if (_scrollController.hasClients) {
      if (_scrollController.position.maxScrollExtent > 0) {
        setState(() {
          _showScrollIndicator = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _bounceController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handlePop() async {
    if (_isReversing) return;

    setState(() {
      _isReversing = true;
    });

    await _controller.reverse();

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reusable image widgets to ensure consistency across layers
    final topImage = Image.asset(
      'assets/images/scroll_top.png',
      width: scrollWidth,
      fit: BoxFit.fill,
    );
    final bottomImage = Image.asset(
      'assets/images/scroll_bottom.png',
      width: scrollWidth,
      fit: BoxFit.fill,
    );

    return PopScope(
      canPop: false, // Prevent default pop to handle animation manually
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (_isReversing) return;

        setState(() {
          _isReversing = true;
        });

        await _controller.reverse();

        if (mounted) {
          Navigator.of(this.context).pop(result);
        }
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.zero, // Allow full width
        child: Center(
          child: SingleChildScrollView(
            physics:
                const NeverScrollableScrollPhysics(), // Lock scroll completely (static)
            child: SizedBox(
              width: scrollWidth, // Fixed width for the entire scroll structure
              child: GestureDetector(
                onTap:
                    _handlePop, // Dismiss on tap 'outside' (including portions of rolls)
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  children: [
                    // BACK LAYER: Bottom Roll (Painted first, so it's behind Body)
                    // We use a Column to properly position it relative to the expanding body height
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Invisible Spacer for Top
                            Opacity(opacity: 0.0, child: topImage),
                            // Invisible Spacer for Body
                            SizedBox(height: _heightAnimation.value),
                            // Variable overlap for the Bottom Image
                            Transform.translate(
                              offset: const Offset(
                                0,
                                -94,
                              ), // Significant overlap from bottom
                              child: bottomImage,
                            ),
                          ],
                        );
                      },
                    ),

                    // FRONT LAYER: Top Roll + Body (Painted last, so they are on top)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        topImage,
                        // Scroll Body (Animated Height)
                        Transform.translate(
                          offset: const Offset(
                            0,
                            -45,
                          ), // Significant overlap into Top
                          child: AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              return Container(
                                // Preserving user's manual adjustment to 223
                                width: 223,
                                height: _heightAnimation.value,
                                decoration: const BoxDecoration(
                                  image: DecorationImage(
                                    image: AssetImage(
                                      'assets/images/scroll_body.png',
                                    ),
                                    fit: BoxFit.fill,
                                  ),
                                ),
                                clipBehavior: Clip.hardEdge,
                                child: GestureDetector(
                                  onTap:
                                      () {}, // Trap taps on the body content to prevent dismissal
                                  child: Opacity(
                                    opacity: _contentOpacityAnimation.value,
                                    child: Stack(
                                      children: [
                                        NotificationListener<
                                          ScrollNotification
                                        >(
                                          onNotification: (notification) {
                                            if (notification
                                                is ScrollUpdateNotification) {
                                              if (_scrollController
                                                      .position
                                                      .pixels >=
                                                  _scrollController
                                                          .position
                                                          .maxScrollExtent -
                                                      10) {
                                                if (_showScrollIndicator) {
                                                  setState(() {
                                                    _showScrollIndicator =
                                                        false;
                                                  });
                                                }
                                              }
                                            }
                                            return false;
                                          },
                                          child: SingleChildScrollView(
                                            controller: _scrollController,
                                            physics:
                                                const BouncingScrollPhysics(), // Allow scrolling for long text
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 32.0,
                                                    vertical: 10.0,
                                                  ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    widget.title,
                                                    textAlign: TextAlign.center,
                                                    style: GoogleFonts.nunito(
                                                      fontSize: 25,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: const Color(
                                                        0xFF3E2723,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Text(
                                                    widget.description,
                                                    textAlign: TextAlign.center,
                                                    style: GoogleFonts.nunito(
                                                      fontSize: 19,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: const Color(
                                                        0xFF5D4037,
                                                      ),
                                                      height: 1.2,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  GestureDetector(
                                                    onTap: widget.onStart,
                                                    child: Container(
                                                      margin: const EdgeInsets.only(
                                                        bottom: 20,
                                                      ), // Extra margin for balance
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 40,
                                                            vertical: 12,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              30,
                                                            ),
                                                        border: Border.all(
                                                          color: const Color(
                                                            0xFFFFECB3,
                                                          ), // Gold/Paper border
                                                          width: 2.0,
                                                        ),
                                                        gradient:
                                                            const LinearGradient(
                                                              begin: Alignment
                                                                  .topCenter,
                                                              end: Alignment
                                                                  .bottomCenter,
                                                              colors: [
                                                                Color(
                                                                  0xFF8D6E63,
                                                                ), // Lighter Wood/Leather
                                                                Color(
                                                                  0xFF3E2723,
                                                                ), // Darker Wood
                                                              ],
                                                            ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withValues(
                                                                  alpha: 0.3,
                                                                ),
                                                            blurRadius: 4,
                                                            offset:
                                                                const Offset(
                                                                  0,
                                                                  4,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Text(
                                                        Provider.of<LanguageProvider>(
                                                                      context,
                                                                    )
                                                                    .currentLocale
                                                                    .languageCode ==
                                                                'it'
                                                            ? "INIZIA"
                                                            : "START",
                                                        style: GoogleFonts.nunito(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: const Color(
                                                            0xFFFFECB3,
                                                          ), // Matching gold text
                                                          letterSpacing: 1.2,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Scroll Indicator (Fade + Bouncing Arrow)
                                        if (_showScrollIndicator)
                                          Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              height: 60,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    const Color(
                                                      0xFFF5E0B6,
                                                    ).withValues(alpha: 0.0),
                                                    const Color(0xFFF5E0B6),
                                                  ],
                                                ),
                                              ),
                                              child: Center(
                                                child: AnimatedBuilder(
                                                  animation: _bounceAnimation,
                                                  builder: (context, child) {
                                                    return Transform.translate(
                                                      offset: Offset(
                                                        0,
                                                        _bounceAnimation.value,
                                                      ),
                                                      child: const Icon(
                                                        Icons
                                                            .keyboard_arrow_down,
                                                        color: Color(
                                                          0xFF8D6E63,
                                                        ),
                                                        size: 30,
                                                      ),
                                                    );
                                                  },
                                                ),
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
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
