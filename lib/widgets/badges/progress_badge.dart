import 'package:flutter/material.dart';
import '../../theme/spacing.dart';

/// Progress Badge Widget
///
/// Displays progress indicators in various styles:
/// - CircularProgressBadge: Circular progress indicator
/// - LinearProgressBadge: Linear progress bar
/// - SegmentedProgressBadge: Multi-step progress indicator
///
/// Example:
/// ```dart
/// CircularProgressBadge(progress: 0.65, label: '65%')
/// LinearProgressBadge(progress: 0.75, steps: 10)
/// SegmentedProgressBadge(currentStep: 2, totalSteps: 4)
/// ```
class CircularProgressBadge extends StatefulWidget {
  /// Progress value (0.0 to 1.0)
  final double progress;

  /// Display label (optional)
  final String? label;

  /// Progress color
  final Color progressColor;

  /// Background color
  final Color backgroundColor;

  /// Badge size
  final double size;

  /// Animation duration
  final Duration animationDuration;

  /// Show animation
  final bool animate;

  const CircularProgressBadge({
    Key? key,
    required this.progress,
    this.label,
    this.progressColor = Colors.deepPurple,
    this.backgroundColor = const Color(0xFFE8E8E8),
    this.size = 120,
    this.animationDuration = const Duration(milliseconds: 800),
    this.animate = true,
  }) : super(key: key);

  @override
  State<CircularProgressBadge> createState() => _CircularProgressBadgeState();
}

class _CircularProgressBadgeState extends State<CircularProgressBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0,
      end: widget.progress.clamp(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.animate) {
      _animationController.forward();
    } else {
      _progressAnimation = AlwaysStoppedAnimation(widget.progress);
    }
  }

  @override
  void didUpdateWidget(CircularProgressBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnimation = Tween<double>(
        begin: oldWidget.progress.clamp(0.0, 1.0),
        end: widget.progress.clamp(0.0, 1.0),
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.backgroundColor.withValues(alpha: 0.2),
                ),
              ),

              // Progress circle
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: CircularProgressIndicator(
                  value: _progressAnimation.value,
                  valueColor: AlwaysStoppedAnimation(widget.progressColor),
                  backgroundColor: widget.backgroundColor,
                  strokeWidth: 6,
                ),
              ),

              // Center label
              if (widget.label != null)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.label!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: widget.progressColor,
                          ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Linear Progress Badge
class LinearProgressBadge extends StatefulWidget {
  /// Progress value (0.0 to 1.0)
  final double progress;

  /// Total steps (for step display)
  final int? steps;

  /// Label (optional)
  final String? label;

  /// Progress color
  final Color progressColor;

  /// Background color
  final Color backgroundColor;

  /// Height of progress bar
  final double height;

  /// Show milestone markers
  final bool showMilestones;

  /// Animation duration
  final Duration animationDuration;

  const LinearProgressBadge({
    Key? key,
    required this.progress,
    this.steps,
    this.label,
    this.progressColor = Colors.deepPurple,
    this.backgroundColor = const Color(0xFFE8E8E8),
    this.height = 8,
    this.showMilestones = false,
    this.animationDuration = const Duration(milliseconds: 800),
  }) : super(key: key);

  @override
  State<LinearProgressBadge> createState() => _LinearProgressBadgeState();
}

class _LinearProgressBadgeState extends State<LinearProgressBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0,
      end: widget.progress.clamp(0.0, 1.0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward();
  }

  @override
  void didUpdateWidget(LinearProgressBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: widget.progress.clamp(0.0, 1.0),
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          SizedBox(height: BJBankSpacing.xs),
        ],
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return Stack(
              children: [
                // Background bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    height: widget.height,
                    color: widget.backgroundColor,
                  ),
                ),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    height: widget.height,
                    width: double.infinity,
                    color: Colors.transparent,
                    child: FractionallySizedBox(
                      widthFactor: _progressAnimation.value,
                      child: Container(
                        color: widget.progressColor,
                      ),
                    ),
                  ),
                ),

                // Percentage text
                Positioned(
                  right: BJBankSpacing.sm,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Text(
                      '${(_progressAnimation.value * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        if (widget.showMilestones && widget.steps != null) ...[
          SizedBox(height: BJBankSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              widget.steps! + 1,
              (index) => _MilestoneMarker(
                isActive: index <= (widget.progress * widget.steps!).toInt(),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Segmented Progress Badge (Multi-step)
class SegmentedProgressBadge extends StatelessWidget {
  /// Current step (1-indexed)
  final int currentStep;

  /// Total steps
  final int totalSteps;

  /// Step labels (optional)
  final List<String>? labels;

  /// Active color
  final Color activeColor;

  /// Inactive color
  final Color inactiveColor;

  /// Segment size
  final double segmentSize;

  /// Show labels
  final bool showLabels;

  const SegmentedProgressBadge({
    Key? key,
    required this.currentStep,
    required this.totalSteps,
    this.labels,
    this.activeColor = Colors.deepPurple,
    this.inactiveColor = const Color(0xFFE8E8E8),
    this.segmentSize = 40,
    this.showLabels = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    assert(
      labels == null || labels!.length == totalSteps,
      'labels must have length equal to totalSteps',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Segment progress indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            totalSteps,
            (index) {
              final stepNumber = index + 1;
              final isActive = stepNumber <= currentStep;
              final isCompleted = stepNumber < currentStep;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: BJBankSpacing.xs / 2,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: segmentSize,
                        height: segmentSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive ? activeColor : inactiveColor,
                          border: isActive
                              ? Border.all(
                                  color: activeColor,
                                  width: 2,
                                )
                              : null,
                        ),
                        child: Center(
                          child: isCompleted
                              ? Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: segmentSize * 0.5,
                                )
                              : Text(
                                  stepNumber.toString(),
                                  style: TextStyle(
                                    color: isActive
                                        ? Colors.white
                                        : Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                    fontSize: segmentSize * 0.4,
                                  ),
                                ),
                        ),
                      ),
                      if (showLabels && labels != null) ...[
                        SizedBox(height: BJBankSpacing.xs),
                        Flexible(
                          child: Text(
                            labels![index],
                            textAlign: TextAlign.center,
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      fontWeight: isActive
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Connecting line
        SizedBox(height: BJBankSpacing.sm),
        Row(
          children: List.generate(
            totalSteps - 1,
            (index) {
              final isActive = index + 1 < currentStep;
              return Expanded(
                child: Container(
                  height: 2,
                  color: isActive ? activeColor : inactiveColor,
                  margin: EdgeInsets.symmetric(horizontal: BJBankSpacing.xs),
                ),
              );
            },
          ),
        ),

        // Progress text
        SizedBox(height: BJBankSpacing.sm),
        Text(
          'Passo $currentStep de $totalSteps',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}

/// Milestone marker widget
class _MilestoneMarker extends StatelessWidget {
  final bool isActive;

  const _MilestoneMarker({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? Colors.deepPurple : Colors.grey[300],
      ),
    );
  }
}
