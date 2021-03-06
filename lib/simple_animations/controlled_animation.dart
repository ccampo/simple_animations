import 'package:flutter/widgets.dart';

/// Playback tell the controller of the animation what to do.
enum Playback {
  /// Animation stands still.
  PAUSE,

  /// Animation plays forwards and stops at the end.
  PLAY_FORWARD,

  /// Animation plays backwards and stops at the beginning.
  PLAY_REVERSE,

  /// Animation will reset to the beginning and start playing forward.
  START_OVER_FORWARD,

  /// Animation will reset to the end and start play backward.
  START_OVER_REVERSE,

  /// Animation will play forwards and start over at the beginning when it
  /// reaches the end.
  LOOP,

  /// Animation will play forward until the end and will reverse playing until
  /// it reaches the beginning. Then it starts over playing forward. And so on.
  MIRROR
}

/// Widget to create custom animations in a very simple way.
///
/// An internal [AnimationController] will do everything you tell him by
/// dynamically assigning the one [Playback] to [playback] property.
/// By default the animation will start playing forward and stops at the end.
///
/// A minimum set of properties are [duration] (time span of the animation),
/// [tween] (values to interpolate among the animation) and a [builder] function
/// (defines the animated scene).
///
/// (TODO add example here)
///
/// TODO complete documentation
class ControlledAnimation<T> extends StatefulWidget {
  final Playback playback;
  final Animatable<T> tween;
  final Curve curve;
  final Duration duration;
  final Duration delay;
  final Widget Function(BuildContext buildContext, T animatedValue) builder;
  final Widget Function(BuildContext, Widget child, T animatedValue)
      builderWithChild;
  final Widget child;
  final AnimationStatusListener statusListener;

  ControlledAnimation(
      {this.playback = Playback.PLAY_FORWARD,
      this.tween,
      this.curve = Curves.linear,
      this.duration,
      this.delay,
      this.builder,
      this.builderWithChild,
      this.child,
      this.statusListener,
      Key key})
      : assert(duration != null,
            "Please set property duration. Example: Duration(milliseconds: 500)"),
        assert(tween != null,
            "Please set property tween. Example: Tween(from: 0.0, to: 100.0)"),
        assert(
            (builderWithChild != null && child != null && builder == null) ||
                (builder != null && builderWithChild == null && child == null),
            "Either use just builder and keep buildWithChild and child null. "
            "Or keep builder null and set a builderWithChild and a child."),
        super(key: key);

  @override
  _ControlledAnimationState<T> createState() => _ControlledAnimationState<T>();
}

class _ControlledAnimationState<T> extends State<ControlledAnimation>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<T> _animation;
  bool _isDisposed = false;
  bool _waitForDelay = true;

  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addListener(() {
        setState(() {});
      });
    _animation = widget.tween
        .chain(CurveTween(curve: widget.curve))
        .animate(_controller);

    if (widget.statusListener != null) {
      _controller.addStatusListener(widget.statusListener);
    }

    initalize();
    super.initState();
  }

  void initalize() async {
    if (widget.delay != null) {
      await Future.delayed(widget.delay);
    }
    _waitForDelay = false;
    executeInstruction();
  }

  @override
  void didUpdateWidget(ControlledAnimation oldWidget) {
    executeInstruction();
    _controller.duration = widget.duration;
    super.didUpdateWidget(oldWidget);
  }

  void executeInstruction() async {
    if (_isDisposed || _waitForDelay) {
      return;
    }

    if (widget.playback == Playback.PAUSE) {
      _controller.stop();
    }
    if (widget.playback == Playback.PLAY_FORWARD) {
      _controller.forward();
    }
    if (widget.playback == Playback.PLAY_REVERSE) {
      _controller.reverse();
    }
    if (widget.playback == Playback.START_OVER_FORWARD) {
      _controller.forward(from: 0.0);
    }
    if (widget.playback == Playback.START_OVER_REVERSE) {
      _controller.reverse(from: 1.0);
    }
    if (widget.playback == Playback.LOOP) {
      _controller.repeat();
    }
    if (widget.playback == Playback.MIRROR) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.builder != null) {
      return widget.builder(context, _animation.value);
    } else if (widget.builderWithChild != null && widget.child != null) {
      return widget.builderWithChild(context, widget.child, _animation.value);
    }
    _controller.stop(canceled: true);
    throw FlutterError(
        "I don't know how to build the animation. Make sure to either specify "
        "a builder or a builderWithChild (along with a child).");
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.dispose();
    super.dispose();
  }
}
