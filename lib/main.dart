diff --git a/lib/main.dart b/lib/main.dart
index a9c5011e3e708df88b9ca6cb1172ff8f7e21f637..452bf1e6a59c4099ae89cd99efe9340575883ca1 100644
--- a/lib/main.dart
+++ b/lib/main.dart
@@ -1,24 +1,967 @@
+import 'dart:typed_data';
 
 import 'package:flutter/material.dart';
+import 'package:pdf/widgets.dart' as pw;
+import 'package:printing/printing.dart';
 
 void main() {
   runApp(const CricketApp());
 }
 
 class CricketApp extends StatelessWidget {
   const CricketApp({super.key});
 
   @override
   Widget build(BuildContext context) {
     return MaterialApp(
       debugShowCheckedModeBanner: false,
       title: 'Cricket Scorer',
-      theme: ThemeData(
-        primarySwatch: Colors.green,
+      theme: ThemeData(primarySwatch: Colors.green),
+      home: const MatchSetupPage(),
+    );
+  }
+}
+
+class MatchSetupPage extends StatefulWidget {
+  const MatchSetupPage({super.key});
+
+  @override
+  State<MatchSetupPage> createState() => _MatchSetupPageState();
+}
+
+class _MatchSetupPageState extends State<MatchSetupPage> {
+  final _formKey = GlobalKey<FormState>();
+  final _teamAController = TextEditingController();
+  final _teamBController = TextEditingController();
+  final _teamAPlayers = List.generate(11, (_) => TextEditingController());
+  final _teamBPlayers = List.generate(11, (_) => TextEditingController());
+
+  int _oversPerInnings = 20;
+  String _tossWinnerCode = 'A';
+  TossDecision _tossDecision = TossDecision.batting;
+
+  @override
+  void dispose() {
+    _teamAController.dispose();
+    _teamBController.dispose();
+    for (final c in _teamAPlayers) {
+      c.dispose();
+    }
+    for (final c in _teamBPlayers) {
+      c.dispose();
+    }
+    super.dispose();
+  }
+
+  void _startMatch() {
+    if (!_formKey.currentState!.validate()) {
+      return;
+    }
+
+    final teamA = _teamAController.text.trim();
+    final teamB = _teamBController.text.trim();
+    final playersA = _teamAPlayers
+        .map((controller) => controller.text.trim())
+        .where((name) => name.isNotEmpty)
+        .toList();
+    final playersB = _teamBPlayers
+        .map((controller) => controller.text.trim())
+        .where((name) => name.isNotEmpty)
+        .toList();
+
+    final duplicateA = _findDuplicate(playersA);
+    final duplicateB = _findDuplicate(playersB);
+
+    if (playersA.length < 2 || playersB.length < 2) {
+      _show('Each team needs at least 2 players.');
+      return;
+    }
+
+    if (duplicateA != null || duplicateB != null) {
+      _show('Player names must be unique per team.');
+      return;
+    }
+
+    final tossWinner = _tossWinnerCode == 'A' ? teamA : teamB;
+    final firstBattingTeam = _tossDecision == TossDecision.batting
+        ? tossWinner
+        : (tossWinner == teamA ? teamB : teamA);
+
+    final setup = MatchSetup(
+      teamA: teamA,
+      teamB: teamB,
+      playersA: playersA,
+      playersB: playersB,
+      oversPerInnings: _oversPerInnings,
+      tossWinner: tossWinner,
+      tossDecision: _tossDecision,
+      firstBattingTeam: firstBattingTeam,
+    );
+
+    Navigator.of(context).push(
+      MaterialPageRoute(builder: (_) => LiveScoringPage(setup: setup)),
+    );
+  }
+
+  String? _findDuplicate(List<String> names) {
+    final seen = <String>{};
+    for (final name in names) {
+      final key = name.toLowerCase();
+      if (!seen.add(key)) {
+        return name;
+      }
+    }
+    return null;
+  }
+
+  void _show(String message) {
+    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
+  }
+
+  @override
+  Widget build(BuildContext context) {
+    final teamAName = _teamAController.text.trim().isEmpty
+        ? 'Team A'
+        : _teamAController.text.trim();
+    final teamBName = _teamBController.text.trim().isEmpty
+        ? 'Team B'
+        : _teamBController.text.trim();
+
+    return Scaffold(
+      appBar: AppBar(title: const Text('Cricket Match Setup')),
+      body: Form(
+        key: _formKey,
+        child: ListView(
+          padding: const EdgeInsets.all(16),
+          children: [
+            TextFormField(
+              controller: _teamAController,
+              decoration: const InputDecoration(labelText: 'Team A Name'),
+              validator: _required,
+              onChanged: (_) => setState(() {}),
+            ),
+            TextFormField(
+              controller: _teamBController,
+              decoration: const InputDecoration(labelText: 'Team B Name'),
+              validator: _required,
+              onChanged: (_) => setState(() {}),
+            ),
+            const SizedBox(height: 12),
+            DropdownButtonFormField<int>(
+              value: _oversPerInnings,
+              decoration: const InputDecoration(labelText: 'Overs per innings'),
+              items: List.generate(
+                50,
+                (index) => DropdownMenuItem(
+                  value: index + 1,
+                  child: Text('${index + 1} overs'),
+                ),
+              ),
+              onChanged: (value) => setState(() => _oversPerInnings = value ?? 20),
+            ),
+            const SizedBox(height: 12),
+            Row(
+              children: [
+                Expanded(
+                  child: DropdownButtonFormField<String>(
+                    value: _tossWinnerCode,
+                    decoration: const InputDecoration(labelText: 'Toss Winner'),
+                    items: [
+                      DropdownMenuItem(value: 'A', child: Text(teamAName)),
+                      DropdownMenuItem(value: 'B', child: Text(teamBName)),
+                    ],
+                    onChanged: (value) =>
+                        setState(() => _tossWinnerCode = value ?? _tossWinnerCode),
+                  ),
+                ),
+                const SizedBox(width: 10),
+                Expanded(
+                  child: DropdownButtonFormField<TossDecision>(
+                    value: _tossDecision,
+                    decoration: const InputDecoration(labelText: 'Toss Decision'),
+                    items: TossDecision.values
+                        .map(
+                          (decision) => DropdownMenuItem(
+                            value: decision,
+                            child: Text(decision.label),
+                          ),
+                        )
+                        .toList(),
+                    onChanged: (value) =>
+                        setState(() => _tossDecision = value ?? TossDecision.batting),
+                  ),
+                ),
+              ],
+            ),
+            const SizedBox(height: 16),
+            const Text('Team A Players (up to 11)'),
+            ..._buildPlayers(_teamAPlayers),
+            const SizedBox(height: 12),
+            const Text('Team B Players (up to 11)'),
+            ..._buildPlayers(_teamBPlayers),
+            const SizedBox(height: 20),
+            ElevatedButton(
+              onPressed: _startMatch,
+              child: const Text('Start Match'),
+            ),
+          ],
+        ),
+      ),
+    );
+  }
+
+  List<Widget> _buildPlayers(List<TextEditingController> controllers) {
+    return List.generate(
+      controllers.length,
+      (index) => TextFormField(
+        controller: controllers[index],
+        decoration: InputDecoration(labelText: 'Player ${index + 1}'),
+      ),
+    );
+  }
+
+  String? _required(String? value) {
+    if (value == null || value.trim().isEmpty) {
+      return 'Required';
+    }
+    return null;
+  }
+}
+
+class LiveScoringPage extends StatefulWidget {
+  const LiveScoringPage({super.key, required this.setup});
+
+  final MatchSetup setup;
+
+  @override
+  State<LiveScoringPage> createState() => _LiveScoringPageState();
+}
+
+class _LiveScoringPageState extends State<LiveScoringPage> {
+  late InningsState _currentInnings;
+  final List<InningsState> _completedInnings = [];
+
+  late String _striker;
+  late String _nonStriker;
+  late String _bowler;
+  int _runsOffBat = 0;
+  int _extraRuns = 0;
+  ExtraType _extraType = ExtraType.none;
+  bool _isWicket = false;
+  DismissalType _dismissalType = DismissalType.bowled;
+
+  @override
+  void initState() {
+    super.initState();
+    _currentInnings = _buildInnings(widget.setup.firstBattingTeam);
+    _striker = _currentInnings.battingPlayers.first;
+    _nonStriker = _currentInnings.battingPlayers[1];
+    _bowler = _currentInnings.bowlingPlayers.first;
+  }
+
+  InningsState _buildInnings(String battingTeam) {
+    final bowlingTeam = battingTeam == widget.setup.teamA
+        ? widget.setup.teamB
+        : widget.setup.teamA;
+
+    return InningsState(
+      battingTeam: battingTeam,
+      bowlingTeam: bowlingTeam,
+      oversLimit: widget.setup.oversPerInnings,
+      battingPlayers:
+          battingTeam == widget.setup.teamA ? widget.setup.playersA : widget.setup.playersB,
+      bowlingPlayers:
+          bowlingTeam == widget.setup.teamA ? widget.setup.playersA : widget.setup.playersB,
+    );
+  }
+
+  List<String> get _notOutBatters {
+    return _currentInnings.battingPlayers
+        .where((player) => !_currentInnings.batterStats[player]!.isOut)
+        .toList();
+  }
+
+  void _recordBall() {
+    final target =
+        _completedInnings.isNotEmpty ? _completedInnings.first.totalRuns + 1 : null;
+
+    final activeBatters = _notOutBatters;
+    if (activeBatters.length < 2 && !_isWicket) {
+      _finishMatch();
+      return;
+    }
+
+    if (_striker == _nonStriker) {
+      _show('Striker and non-striker must be different players.');
+      return;
+    }
+
+    final event = _currentInnings.addBall(
+      striker: _striker,
+      bowler: _bowler,
+      runsOffBat: _runsOffBat,
+      extraRuns: _extraRuns,
+      extraType: _extraType,
+      wicket: _isWicket,
+      dismissalType: _isWicket ? _dismissalType : null,
+    );
+
+    setState(() {
+      if (event.totalRuns.isOdd) {
+        _swapBatters();
+      }
+
+      if (_isWicket) {
+        final available = _notOutBatters;
+        if (available.length >= 2) {
+          _striker = available.firstWhere(
+            (player) => player != _nonStriker,
+            orElse: () => available.first,
+          );
+        }
+      }
+
+      if (_currentInnings.legalBalls % 6 == 0 && _currentInnings.legalBalls > 0) {
+        _swapBatters();
+      }
+
+      final stillAvailable = _notOutBatters;
+      if (!stillAvailable.contains(_striker) && stillAvailable.isNotEmpty) {
+        _striker = stillAvailable.first;
+      }
+      if (!stillAvailable.contains(_nonStriker) && stillAvailable.length > 1) {
+        _nonStriker = stillAvailable.firstWhere((p) => p != _striker);
+      }
+
+      _runsOffBat = 0;
+      _extraRuns = 0;
+      _extraType = ExtraType.none;
+      _isWicket = false;
+      _dismissalType = DismissalType.bowled;
+    });
+
+    final chaseFinished = target != null && _currentInnings.totalRuns >= target;
+    if (chaseFinished || _currentInnings.isCompleted) {
+      _handleInningsCompletion();
+    }
+  }
+
+  void _swapBatters() {
+    final tmp = _striker;
+    _striker = _nonStriker;
+    _nonStriker = tmp;
+  }
+
+  void _handleInningsCompletion() {
+    _completedInnings.add(_currentInnings.copy());
+
+    if (_completedInnings.length == 1) {
+      final secondBatting = _currentInnings.bowlingTeam;
+      setState(() {
+        _currentInnings = _buildInnings(secondBatting);
+        _striker = _currentInnings.battingPlayers.first;
+        _nonStriker = _currentInnings.battingPlayers[1];
+        _bowler = _currentInnings.bowlingPlayers.first;
+      });
+      _show('Innings break: ${_currentInnings.battingTeam} to bat.');
+      return;
+    }
+
+    _finishMatch();
+  }
+
+  void _finishMatch() {
+    Navigator.of(context).pushReplacement(
+      MaterialPageRoute(
+        builder: (_) => MatchSummaryPage(setup: widget.setup, innings: _completedInnings),
+      ),
+    );
+  }
+
+  void _show(String message) {
+    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
+  }
+
+  @override
+  Widget build(BuildContext context) {
+    final target =
+        _completedInnings.isNotEmpty ? _completedInnings.first.totalRuns + 1 : null;
+    final remainingRuns =
+        target == null ? null : (target - _currentInnings.totalRuns).clamp(0, 9999);
+    final remainingBalls =
+        (_currentInnings.oversLimit * 6 - _currentInnings.legalBalls).clamp(0, 9999);
+
+    final availableBatters = _notOutBatters;
+
+    return Scaffold(
+      appBar: AppBar(
+        title: const Text('Live Scoring'),
+        actions: [
+          IconButton(
+            onPressed: _handleInningsCompletion,
+            tooltip: 'End innings',
+            icon: const Icon(Icons.flag),
+          ),
+        ],
       ),
-      home: const Scaffold(
-        body: Center(child: Text('Cricket Scorer App - Coming Soon!')),
+      body: Padding(
+        padding: const EdgeInsets.all(12),
+        child: Column(
+          crossAxisAlignment: CrossAxisAlignment.start,
+          children: [
+            Card(
+              child: Padding(
+                padding: const EdgeInsets.all(12),
+                child: Column(
+                  crossAxisAlignment: CrossAxisAlignment.start,
+                  children: [
+                    Text(
+                      '${_currentInnings.battingTeam}: ${_currentInnings.totalRuns}/${_currentInnings.wickets}',
+                      style: Theme.of(context).textTheme.headlineSmall,
+                    ),
+                    Text('Overs: ${_currentInnings.oversText}/${_currentInnings.oversLimit}.0'),
+                    Text('Run Rate: ${_currentInnings.runRate.toStringAsFixed(2)}'),
+                    if (target != null)
+                      Text('Target: $target (Need $remainingRuns in $remainingBalls balls)'),
+                  ],
+                ),
+              ),
+            ),
+            Row(
+              children: [
+                Expanded(
+                  child: DropdownButtonFormField<String>(
+                    value: availableBatters.contains(_striker)
+                        ? _striker
+                        : (availableBatters.isNotEmpty ? availableBatters.first : null),
+                    decoration: const InputDecoration(labelText: 'Striker'),
+                    items: availableBatters
+                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
+                        .toList(),
+                    onChanged: (value) => setState(() {
+                      if (value != null) {
+                        _striker = value;
+                      }
+                    }),
+                  ),
+                ),
+                const SizedBox(width: 8),
+                Expanded(
+                  child: DropdownButtonFormField<String>(
+                    value: availableBatters.contains(_nonStriker)
+                        ? _nonStriker
+                        : (availableBatters.length > 1 ? availableBatters[1] : null),
+                    decoration: const InputDecoration(labelText: 'Non-striker'),
+                    items: availableBatters
+                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
+                        .toList(),
+                    onChanged: (value) => setState(() {
+                      if (value != null) {
+                        _nonStriker = value;
+                      }
+                    }),
+                  ),
+                ),
+              ],
+            ),
+            const SizedBox(height: 8),
+            DropdownButtonFormField<String>(
+              value: _bowler,
+              decoration: const InputDecoration(labelText: 'Bowler'),
+              items: _currentInnings.bowlingPlayers
+                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
+                  .toList(),
+              onChanged: (value) => setState(() => _bowler = value ?? _bowler),
+            ),
+            const SizedBox(height: 8),
+            Wrap(
+              spacing: 8,
+              children: List.generate(
+                7,
+                (run) => ChoiceChip(
+                  label: Text('$run'),
+                  selected: _runsOffBat == run,
+                  onSelected: (_) => setState(() => _runsOffBat = run),
+                ),
+              ),
+            ),
+            const SizedBox(height: 8),
+            Row(
+              children: [
+                Expanded(
+                  child: DropdownButtonFormField<ExtraType>(
+                    value: _extraType,
+                    decoration: const InputDecoration(labelText: 'Extras type'),
+                    items: ExtraType.values
+                        .map(
+                          (type) => DropdownMenuItem(value: type, child: Text(type.label)),
+                        )
+                        .toList(),
+                    onChanged: (value) => setState(() => _extraType = value ?? ExtraType.none),
+                  ),
+                ),
+                const SizedBox(width: 8),
+                Expanded(
+                  child: Row(
+                    children: [
+                      const Text('Extra runs'),
+                      IconButton(
+                        onPressed: _extraRuns > 0 ? () => setState(() => _extraRuns--) : null,
+                        icon: const Icon(Icons.remove_circle_outline),
+                      ),
+                      Text('$_extraRuns'),
+                      IconButton(
+                        onPressed: () => setState(() => _extraRuns++),
+                        icon: const Icon(Icons.add_circle_outline),
+                      ),
+                    ],
+                  ),
+                ),
+              ],
+            ),
+            CheckboxListTile(
+              value: _isWicket,
+              onChanged: (value) => setState(() => _isWicket = value ?? false),
+              title: const Text('Wicket on this ball'),
+              dense: true,
+            ),
+            if (_isWicket)
+              DropdownButtonFormField<DismissalType>(
+                value: _dismissalType,
+                decoration: const InputDecoration(labelText: 'Dismissal type'),
+                items: DismissalType.values
+                    .map(
+                      (type) => DropdownMenuItem(
+                        value: type,
+                        child: Text(type.label),
+                      ),
+                    )
+                    .toList(),
+                onChanged: (value) =>
+                    setState(() => _dismissalType = value ?? DismissalType.bowled),
+              ),
+            const SizedBox(height: 8),
+            FilledButton(
+              onPressed: _recordBall,
+              child: const Text('Add Ball Event'),
+            ),
+            const SizedBox(height: 8),
+            Text('Live Feed', style: Theme.of(context).textTheme.titleMedium),
+            Expanded(
+              child: ListView.builder(
+                reverse: true,
+                itemCount: _currentInnings.ballHistory.length,
+                itemBuilder: (context, index) {
+                  final event = _currentInnings.ballHistory[index];
+                  return ListTile(
+                    dense: true,
+                    title: Text(event.summary),
+                    subtitle: Text(
+                      '${event.overText} | Batter: ${event.striker} | Bowler: ${event.bowler}',
+                    ),
+                  );
+                },
+              ),
+            ),
+          ],
+        ),
+      ),
+    );
+  }
+}
+
+class MatchSummaryPage extends StatelessWidget {
+  const MatchSummaryPage({super.key, required this.setup, required this.innings});
+
+  final MatchSetup setup;
+  final List<InningsState> innings;
+
+  @override
+  Widget build(BuildContext context) {
+    return Scaffold(
+      appBar: AppBar(title: const Text('Match Summary')),
+      body: ListView(
+        padding: const EdgeInsets.all(16),
+        children: [
+          Text(_resultText(), style: Theme.of(context).textTheme.titleLarge),
+          const SizedBox(height: 8),
+          Text('Toss: ${setup.tossWinner} won and chose ${setup.tossDecision.label}'),
+          const SizedBox(height: 16),
+          ...innings.map(
+            (inn) => Card(
+              child: Padding(
+                padding: const EdgeInsets.all(12),
+                child: Column(
+                  crossAxisAlignment: CrossAxisAlignment.start,
+                  children: [
+                    Text(
+                      '${inn.battingTeam} - ${inn.totalRuns}/${inn.wickets} (${inn.oversText})',
+                      style: Theme.of(context).textTheme.titleMedium,
+                    ),
+                    Text('Run Rate: ${inn.runRate.toStringAsFixed(2)}'),
+                    const SizedBox(height: 8),
+                    const Text('Batting Card:'),
+                    ...inn.batterStats.entries.map(
+                      (entry) => Text('${entry.key}: ${entry.value.runs} (${entry.value.balls})'),
+                    ),
+                    const SizedBox(height: 8),
+                    const Text('Bowling Card:'),
+                    ...inn.bowlerStats.entries.map(
+                      (entry) => Text(
+                        '${entry.key}: ${entry.value.oversText} overs, ${entry.value.runs} runs, ${entry.value.wickets} wickets',
+                      ),
+                    ),
+                  ],
+                ),
+              ),
+            ),
+          ),
+          const SizedBox(height: 10),
+          FilledButton.icon(
+            onPressed: () async {
+              final bytes = await _buildPdf();
+              await Printing.sharePdf(bytes: bytes, filename: 'match_summary.pdf');
+            },
+            icon: const Icon(Icons.picture_as_pdf),
+            label: const Text('Download / Share Match Summary PDF'),
+          ),
+        ],
+      ),
+    );
+  }
+
+  String _resultText() {
+    if (innings.length < 2) {
+      return 'Match incomplete';
+    }
+
+    final first = innings[0];
+    final second = innings[1];
+
+    if (second.totalRuns > first.totalRuns) {
+      return '${second.battingTeam} won by ${10 - second.wickets} wickets';
+    }
+    if (second.totalRuns < first.totalRuns) {
+      return '${first.battingTeam} won by ${first.totalRuns - second.totalRuns} runs';
+    }
+    return 'Match tied';
+  }
+
+  Future<Uint8List> _buildPdf() async {
+    final doc = pw.Document();
+
+    doc.addPage(
+      pw.MultiPage(
+        build: (_) => [
+          pw.Header(level: 0, child: pw.Text('Cricket Match Summary')),
+          pw.Text(_resultText()),
+          pw.Text('Toss: ${setup.tossWinner} chose ${setup.tossDecision.label}'),
+          pw.SizedBox(height: 10),
+          ...innings.map((inn) => _inningsPdf(inn)),
+        ],
       ),
     );
+
+    return doc.save();
+  }
+
+  pw.Widget _inningsPdf(InningsState inn) {
+    return pw.Column(
+      crossAxisAlignment: pw.CrossAxisAlignment.start,
+      children: [
+        pw.Text(
+          '${inn.battingTeam}: ${inn.totalRuns}/${inn.wickets} in ${inn.oversText} overs | RR ${inn.runRate.toStringAsFixed(2)}',
+          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
+        ),
+        pw.SizedBox(height: 4),
+        pw.Text('Individual Scores:'),
+        ...inn.batterStats.entries
+            .map((entry) => pw.Text('${entry.key} - ${entry.value.runs} (${entry.value.balls})')),
+        pw.SizedBox(height: 4),
+        pw.Text('Bowling Figures:'),
+        ...inn.bowlerStats.entries.map(
+          (entry) => pw.Text(
+            '${entry.key} - ${entry.value.oversText} overs, ${entry.value.runs} runs, ${entry.value.wickets} wickets',
+          ),
+        ),
+        pw.SizedBox(height: 4),
+        pw.Text('Over History (ball-by-ball):'),
+        ...inn.ballHistory.map((event) => pw.Text('${event.overText}: ${event.summary}')),
+        pw.SizedBox(height: 12),
+      ],
+    );
+  }
+}
+
+class MatchSetup {
+  MatchSetup({
+    required this.teamA,
+    required this.teamB,
+    required this.playersA,
+    required this.playersB,
+    required this.oversPerInnings,
+    required this.tossWinner,
+    required this.tossDecision,
+    required this.firstBattingTeam,
+  });
+
+  final String teamA;
+  final String teamB;
+  final List<String> playersA;
+  final List<String> playersB;
+  final int oversPerInnings;
+  final String tossWinner;
+  final TossDecision tossDecision;
+  final String firstBattingTeam;
+}
+
+class InningsState {
+  InningsState({
+    required this.battingTeam,
+    required this.bowlingTeam,
+    required this.oversLimit,
+    required this.battingPlayers,
+    required this.bowlingPlayers,
+  }) {
+    for (final player in battingPlayers) {
+      batterStats[player] = BatterStat();
+    }
+    for (final player in bowlingPlayers) {
+      bowlerStats[player] = BowlerStat();
+    }
+  }
+
+  final String battingTeam;
+  final String bowlingTeam;
+  final int oversLimit;
+  final List<String> battingPlayers;
+  final List<String> bowlingPlayers;
+
+  final Map<String, BatterStat> batterStats = {};
+  final Map<String, BowlerStat> bowlerStats = {};
+  final List<BallEvent> ballHistory = [];
+
+  int totalRuns = 0;
+  int wickets = 0;
+  int legalBalls = 0;
+
+  bool get isCompleted => legalBalls >= oversLimit * 6 || wickets >= 10;
+  String get oversText => '${legalBalls ~/ 6}.${legalBalls % 6}';
+
+  double get runRate {
+    if (legalBalls == 0) {
+      return 0;
+    }
+    return totalRuns / (legalBalls / 6);
+  }
+
+  BallEvent addBall({
+    required String striker,
+    required String bowler,
+    required int runsOffBat,
+    required int extraRuns,
+    required ExtraType extraType,
+    required bool wicket,
+    DismissalType? dismissalType,
+  }) {
+    final isLegalBall = extraType != ExtraType.wide && extraType != ExtraType.noBall;
+    final totalOnBall = runsOffBat + extraRuns;
+
+    totalRuns += totalOnBall;
+
+    if (isLegalBall) {
+      legalBalls++;
+      batterStats[striker]!.balls++;
+      bowlerStats[bowler]!.legalBalls++;
+    }
+
+    batterStats[striker]!.runs += runsOffBat;
+    if (runsOffBat == 4) {
+      batterStats[striker]!.fours++;
+    }
+    if (runsOffBat == 6) {
+      batterStats[striker]!.sixes++;
+    }
+
+    final chargedToBowler = extraType != ExtraType.bye && extraType != ExtraType.legBye;
+    if (chargedToBowler) {
+      bowlerStats[bowler]!.runs += totalOnBall;
+    }
+
+    if (wicket) {
+      wickets++;
+      batterStats[striker]!.isOut = true;
+      if ((dismissalType ?? DismissalType.bowled).creditsBowler) {
+        bowlerStats[bowler]!.wickets++;
+      }
+    }
+
+    final event = BallEvent(
+      overText: oversText,
+      striker: striker,
+      bowler: bowler,
+      runsOffBat: runsOffBat,
+      extraRuns: extraRuns,
+      extraType: extraType,
+      wicket: wicket,
+      dismissalType: dismissalType,
+      totalRuns: totalOnBall,
+    );
+
+    ballHistory.add(event);
+    return event;
+  }
+
+  InningsState copy() {
+    final copied = InningsState(
+      battingTeam: battingTeam,
+      bowlingTeam: bowlingTeam,
+      oversLimit: oversLimit,
+      battingPlayers: List.of(battingPlayers),
+      bowlingPlayers: List.of(bowlingPlayers),
+    );
+
+    copied.totalRuns = totalRuns;
+    copied.wickets = wickets;
+    copied.legalBalls = legalBalls;
+
+    copied.ballHistory
+      ..clear()
+      ..addAll(ballHistory);
+
+    copied.batterStats
+      ..clear()
+      ..addEntries(
+        batterStats.entries.map((entry) => MapEntry(entry.key, entry.value.copy())),
+      );
+
+    copied.bowlerStats
+      ..clear()
+      ..addEntries(
+        bowlerStats.entries.map((entry) => MapEntry(entry.key, entry.value.copy())),
+      );
+
+    return copied;
+  }
+}
+
+class BallEvent {
+  BallEvent({
+    required this.overText,
+    required this.striker,
+    required this.bowler,
+    required this.runsOffBat,
+    required this.extraRuns,
+    required this.extraType,
+    required this.wicket,
+    required this.dismissalType,
+    required this.totalRuns,
+  });
+
+  final String overText;
+  final String striker;
+  final String bowler;
+  final int runsOffBat;
+  final int extraRuns;
+  final ExtraType extraType;
+  final bool wicket;
+  final DismissalType? dismissalType;
+  final int totalRuns;
+
+  String get summary {
+    final extras = extraType == ExtraType.none ? '' : ' + $extraRuns ${extraType.label}';
+    final wicketText = wicket
+        ? ' | WICKET (${(dismissalType ?? DismissalType.bowled).label})'
+        : '';
+    return 'Runs: $runsOffBat$extras (Ball total: $totalRuns)$wicketText';
+  }
+}
+
+enum TossDecision { batting, bowling }
+
+extension TossDecisionLabel on TossDecision {
+  String get label => this == TossDecision.batting ? 'Batting' : 'Bowling';
+}
+
+enum ExtraType { none, wide, noBall, bye, legBye }
+
+extension ExtraTypeLabel on ExtraType {
+  String get label {
+    switch (this) {
+      case ExtraType.none:
+        return 'None';
+      case ExtraType.wide:
+        return 'Wide';
+      case ExtraType.noBall:
+        return 'No Ball';
+      case ExtraType.bye:
+        return 'Bye';
+      case ExtraType.legBye:
+        return 'Leg Bye';
+    }
+  }
+}
+
+enum DismissalType {
+  bowled,
+  caught,
+  lbw,
+  stumped,
+  hitWicket,
+  runOut,
+}
+
+extension DismissalTypeInfo on DismissalType {
+  String get label {
+    switch (this) {
+      case DismissalType.bowled:
+        return 'Bowled';
+      case DismissalType.caught:
+        return 'Caught';
+      case DismissalType.lbw:
+        return 'LBW';
+      case DismissalType.stumped:
+        return 'Stumped';
+      case DismissalType.hitWicket:
+        return 'Hit Wicket';
+      case DismissalType.runOut:
+        return 'Run Out';
+    }
+  }
+
+  bool get creditsBowler {
+    return this != DismissalType.runOut;
+  }
+}
+
+class BatterStat {
+  int runs = 0;
+  int balls = 0;
+  int fours = 0;
+  int sixes = 0;
+  bool isOut = false;
+
+  BatterStat copy() {
+    return BatterStat()
+      ..runs = runs
+      ..balls = balls
+      ..fours = fours
+      ..sixes = sixes
+      ..isOut = isOut;
+  }
+}
+
+class BowlerStat {
+  int legalBalls = 0;
+  int runs = 0;
+  int wickets = 0;
+
+  String get oversText => '${legalBalls ~/ 6}.${legalBalls % 6}';
+
+  BowlerStat copy() {
+    return BowlerStat()
+      ..legalBalls = legalBalls
+      ..runs = runs
+      ..wickets = wickets;
   }
 }
