import 'dart:async';

import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puzzle_engine/puzzle_engine.dart';

import '../../app/providers.dart';
import '../../l10n/generated/app_localizations.dart';
import '../home/widgets/banner_slot.dart';
import 'game_controller.dart';
import 'widgets/game_toolbar.dart';
import 'widgets/number_pad.dart';
import 'widgets/sudoku_board.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> with WidgetsBindingObserver {
  GameStatus? _shownDialogFor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = ref.read(gameControllerProvider.notifier);
    switch (state) {
      case AppLifecycleState.resumed:
        c.resumeTimer();
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        c.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(gameControllerProvider);
    final rule = ref.watch(puzzleRuleProvider);
    final controller = ref.read(gameControllerProvider.notifier);

    // Result dialogs, once per status transition.
    ref.listen<GameViewState?>(gameControllerProvider, (prev, next) {
      if (next == null) return;
      if (next.status != GameStatus.playing && _shownDialogFor != next.status) {
        _shownDialogFor = next.status;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (next.status == GameStatus.solved) {
            unawaited(_showSolved(next));
          } else {
            unawaited(_showFailed(next));
          }
        });
      }
      if (next.status == GameStatus.playing) _shownDialogFor = null;
    });

    if (state == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) controller.pause();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_difficultyLabel(l, state.puzzle.difficulty)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${l.mistakes}: ${l.mistakesCount(state.mistakes, state.maxMistakes)}'),
                    if (state.isDaily) const Icon(Icons.calendar_today, size: 18),
                    Text('${l.time}: ${formatDuration(state.elapsed)}'),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SudokuBoard(
                  state: state,
                  rule: rule,
                  onCellTap: controller.select,
                ),
              ),
              if (state.lastHint != null && state.hintHighlight.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Text(
                    _techniqueText(l, state.lastHint!.techniqueId),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const Spacer(),
              GameToolbar(
                canUndo: state.canUndo,
                notesMode: state.notesMode,
                freeHintsLeft: state.freeHintsLeft,
                onUndo: controller.undo,
                onErase: controller.erase,
                onToggleNotes: controller.toggleNotesMode,
                onHint: () => _onHint(controller),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                child: NumberPad(
                  maxValue: rule.maxValue,
                  countOf: (v) => state.board.where((x) => x == v).length,
                  onTap: controller.input,
                  enabled: state.status == GameStatus.playing,
                ),
              ),
              const BannerSlot(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onHint(GameController controller) async {
    final l = AppLocalizations.of(context);
    final outcome = await controller.requestHint();
    if (!mounted) return;
    if (outcome == HintOutcome.adNotReady) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.adNotReady)));
    }
  }

  Future<void> _showSolved(GameViewState s) async {
    final l = AppLocalizations.of(context);
    final controller = ref.read(gameControllerProvider.notifier);
    final again = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l.solvedTitle),
        content: Text(l.solvedBody(
          _difficultyLabel(l, s.puzzle.difficulty),
          formatDuration(s.elapsed),
          s.mistakes,
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.backHome)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.playAgain)),
        ],
      ),
    );
    if (!mounted) return;
    await controller.maybeShowInterstitial();
    if (!mounted) return;
    if (again == true) {
      await controller.startNew(s.puzzle.difficulty);
    } else {
      await controller.abandon();
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _showFailed(GameViewState s) async {
    final l = AppLocalizations.of(context);
    final controller = ref.read(gameControllerProvider.notifier);
    final ads = ref.read(adServiceProvider);
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l.failedTitle),
        content: Text(l.failedBody(s.maxMistakes)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, 'giveup'), child: Text(l.giveUp)),
          RewardButton(
            label: l.watchAdToContinue,
            ready: ads.isRewardedReady,
            onPressed: () => Navigator.pop(context, 'continue'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (choice == 'continue') {
      final ok = await controller.continueWithAd();
      if (!ok && mounted) {
        // Ad skipped or unavailable: let them try again.
        _shownDialogFor = null;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.adNotReady)));
        unawaited(_showFailed(s));
      }
      return;
    }
    await controller.maybeShowInterstitial();
    await controller.abandon();
    if (mounted) Navigator.of(context).pop();
  }

  static String _difficultyLabel(AppLocalizations l, Difficulty d) => switch (d) {
        Difficulty.easy => l.difficultyEasy,
        Difficulty.medium => l.difficultyMedium,
        Difficulty.hard => l.difficultyHard,
        Difficulty.expert => l.difficultyExpert,
      };

  static String _techniqueText(AppLocalizations l, String techniqueId) => switch (techniqueId) {
        'naked_single' => l.techniqueNakedSingle,
        'hidden_single' => l.techniqueHiddenSingle,
        _ => l.techniqueReveal,
      };
}
