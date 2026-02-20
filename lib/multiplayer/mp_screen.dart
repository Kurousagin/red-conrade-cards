// ══════════════════════════════════════════════════════════════
//  MpScreen — Hub de Multiplayer Wi-Fi Local
// ══════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../widgets/soviet_theme.dart';
import '../providers/game_provider.dart';
import 'mp_provider.dart';
import 'mp_tap_battle.dart';
import 'mp_memory_race.dart';
import 'mp_trade_screen.dart';

class MpScreen extends StatefulWidget {
  const MpScreen({super.key});
  @override
  State<MpScreen> createState() => _MpScreenState();
}

class _MpScreenState extends State<MpScreen> {
  final _nameCtrl = TextEditingController(text: 'Camarada');
  final _ipCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ipCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mp = context.watch<MpProvider>();

    if (!mp.isConnected) return _buildConnect(mp);
    if (mp.phase == MpGamePhase.playing) return _buildGame(mp);
    if (mp.phase == MpGamePhase.result) return _buildResult(mp);
    return _buildLobby(mp);
  }

  // ── Tela inicial: HOST ou JOIN ─────────────────────────────
  Widget _buildConnect(MpProvider mp) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SovietHeader(
            title: '☭ BATALHA SOVIÉTICA ☭',
            subtitle: 'Multiplayer Wi-Fi Local — sem internet',
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Nome
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: SC.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SC.redDark),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('SEU NOME DE GUERRA',
                          style: TextStyle(
                              fontFamily: 'Oswald',
                              fontSize: 12,
                              color: SC.gold,
                              letterSpacing: 2)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameCtrl,
                        style: const TextStyle(
                            fontFamily: 'Oswald', color: SC.cream, fontSize: 16),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: SC.cardDark,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: SC.red),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: SC.redDark),
                          ),
                          prefixIcon:
                              const Icon(Icons.person, color: SC.gold, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // HOST
                _InfoCard(
                  icon: '📡',
                  title: 'CRIAR SALA (HOST)',
                  subtitle: 'Outros jogadores se conectam no seu IP via Wi-Fi',
                  color: SC.red,
                  child: _busy
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(SC.gold))
                      : SovietButton(
                          label: '☭ CRIAR SALA',
                          onTap: _startHost,
                          bgColor: SC.red,
                        ),
                ),
                const SizedBox(height: 12),

                // JOIN
                _InfoCard(
                  icon: '🔗',
                  title: 'ENTRAR EM SALA',
                  subtitle: 'Digite o IP do host (mesma rede Wi-Fi)',
                  color: SC.goldDark,
                  child: Column(
                    children: [
                      TextField(
                        controller: _ipCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                            fontFamily: 'Oswald', color: SC.cream),
                        decoration: InputDecoration(
                          hintText: '192.168.x.x',
                          hintStyle: const TextStyle(color: SC.grey),
                          filled: true,
                          fillColor: SC.cardDark,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: SC.goldDark),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: SC.goldDark),
                          ),
                          prefixIcon: const Icon(Icons.wifi, color: SC.gold, size: 20),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SovietButton(
                        label: '🔗 CONECTAR',
                        onTap: _busy ? null : _joinGame,
                        bgColor: SC.goldDark,
                        borderColor: SC.gold,
                        textColor: Colors.black,
                      ),
                    ],
                  ),
                ),

                if (mp.errorMsg != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: SC.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: SC.red),
                    ),
                    child: Row(
                      children: [
                        const Text('⚠️', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(mp.errorMsg!,
                              style: const TextStyle(
                                  fontFamily: 'Oswald',
                                  color: SC.cream,
                                  fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                // Como funciona
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: SC.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SC.redDark.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('☭ COMO FUNCIONA',
                          style: TextStyle(
                              fontFamily: 'Oswald',
                              fontSize: 12,
                              color: SC.gold,
                              letterSpacing: 2)),
                      const SizedBox(height: 8),
                      ...[
                        '1. Todos no mesmo Wi-Fi',
                        '2. Um cria a sala (HOST)',
                        '3. Outros entram com o IP',
                        '4. Host escolhe o jogo',
                        '5. Jogos: Tap Battle, Memory Race, Troca de Cartas',
                      ].map((t) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text('• $t',
                                style: const TextStyle(
                                    fontFamily: 'Oswald',
                                    fontSize: 12,
                                    color: SC.cream)),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Lobby ─────────────────────────────────────────────────
  Widget _buildLobby(MpProvider mp) {
    return Column(
      children: [
        SovietHeader(
          title: mp.isHost ? '☭ SALA DO HOST ☭' : '☭ AGUARDANDO HOST ☭',
          subtitle: mp.isHost ? 'IP: ${mp.localIp} | ${mp.players.length + 1} jogador(es)' : 'Conectado como ${mp.myName}',
          actions: [
            GestureDetector(
              onTap: () async {
                await mp.disconnect();
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                child: const Text('✕',
                    style: TextStyle(color: SC.cream, fontSize: 18)),
              ),
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // IP do host
                if (mp.isHost)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: SC.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: SC.gold, width: 2),
                    ),
                    child: Column(
                      children: [
                        const Text('SEU IP — COMPARTILHE COM OS CAMARADAS',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontFamily: 'Oswald',
                                fontSize: 11,
                                color: SC.gold,
                                letterSpacing: 1)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(mp.localIp,
                                style: const TextStyle(
                                    fontFamily: 'Oswald',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 28,
                                    color: SC.cream,
                                    letterSpacing: 4)),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: mp.localIp));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('IP copiado! ☭'),
                                    backgroundColor: SC.card,
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              child: const Icon(Icons.copy, color: SC.gold, size: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Porta: 8765',
                            style: const TextStyle(
                                fontFamily: 'Oswald',
                                fontSize: 11,
                                color: SC.grey)),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Lista de jogadores
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: SC.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SC.redDark),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'JOGADORES NA SALA (${mp.playerCount})',
                        style: const TextStyle(
                            fontFamily: 'Oswald',
                            fontSize: 12,
                            color: SC.gold,
                            letterSpacing: 2),
                      ),
                      const SizedBox(height: 10),
                      // Host sempre aparece
                      _PlayerTile(
                        name: mp.isHost ? mp.myName : (mp.players.isNotEmpty ? '...' : 'HOST'),
                        isHost: true,
                        isMe: mp.isHost,
                      ),
                      ...mp.players.map((p) => _PlayerTile(
                            name: p.name,
                            isHost: false,
                            isMe: p.id == mp.myId,
                          )),
                      if (mp.players.isEmpty && !mp.isHost)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Aguardando outros jogadores...',
                            style: TextStyle(
                                fontFamily: 'Oswald',
                                fontSize: 13,
                                color: SC.grey),
                          ),
                        ),
                    ],
                  ),
                ),

                if (mp.isHost) ...[
                  const SizedBox(height: 20),
                  const SovietDivider(label: 'ESCOLHER JOGO'),
                  const SizedBox(height: 12),
                  _GameButton(
                    icon: '👆',
                    title: 'TAP BATTLE',
                    desc: 'Quem toca mais vezes em 15s vence',
                    onTap: () => mp.hostStartGame('tap'),
                    color: SC.red,
                  ),
                  const SizedBox(height: 10),
                  _GameButton(
                    icon: '🧠',
                    title: 'MEMORY RACE',
                    desc: 'Quem achar mais pares primeiro vence',
                    onTap: () => mp.hostStartGame('memory'),
                    color: SC.goldDark,
                  ),
                  const SizedBox(height: 10),
                  _GameButton(
                    icon: '🔄',
                    title: 'TROCA DE CARTAS',
                    desc: 'Negocie cartas com os camaradas',
                    onTap: () {
                      final gp = context.read<GameProvider>();
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => MultiProvider(
                          providers: [
                            ChangeNotifierProvider.value(value: mp),
                            ChangeNotifierProvider.value(value: gp),
                          ],
                          child: const MpTradeScreen(),
                        ),
                      ));
                    },
                    color: SC.green.withValues(alpha: 0.8),
                  ),
                  if (mp.players.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Aguardando pelo menos 1 jogador para iniciar...',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontFamily: 'Oswald', fontSize: 12, color: SC.grey),
                      ),
                    ),
                ] else ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: SC.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: SC.redDark),
                    ),
                    child: const Column(
                      children: [
                        Text('⏳', style: TextStyle(fontSize: 40)),
                        SizedBox(height: 8),
                        Text(
                          'AGUARDANDO HOST\nINICIAR O JOGO...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontFamily: 'Oswald',
                              fontSize: 16,
                              color: SC.cream,
                              letterSpacing: 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Em jogo ───────────────────────────────────────────────
  Widget _buildGame(MpProvider mp) {
    if (mp.currentGame == 'tap') {
      return MpTapBattle(mp: mp);
    } else if (mp.currentGame == 'memory') {
      return MpMemoryRace(mp: mp);
    }
    return const Center(
      child: Text('Jogo desconhecido', style: TextStyle(color: SC.cream)),
    );
  }

  // ── Resultado ─────────────────────────────────────────────
  Widget _buildResult(MpProvider mp) {
    final result = mp.lastResult;
    final ranking = (result?['ranking'] as List?) ?? [];
    final winner = result?['winner'] as String? ?? '???';

    return Column(
      children: [
        const SovietHeader(title: '☭ RESULTADO FINAL ☭'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 8),
                Text(winner,
                    style: const TextStyle(
                        fontFamily: 'Oswald',
                        fontWeight: FontWeight.w700,
                        fontSize: 28,
                        color: SC.gold,
                        letterSpacing: 2)),
                const Text('VENCEDOR!',
                    style: TextStyle(
                        fontFamily: 'Oswald', fontSize: 14, color: SC.cream)),
                const SizedBox(height: 24),
                ...ranking.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final p = entry.value as Map;
                  final medals = ['🥇', '🥈', '🥉'];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: idx == 0
                          ? SC.gold.withValues(alpha: 0.15)
                          : SC.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: idx == 0 ? SC.gold : SC.redDark,
                        width: idx == 0 ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          idx < medals.length ? medals[idx] : '${idx + 1}.',
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(p['name'] as String? ?? '?',
                              style: TextStyle(
                                  fontFamily: 'Oswald',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: idx == 0 ? SC.gold : SC.cream)),
                        ),
                        Text('${p['score']} pts',
                            style: TextStyle(
                                fontFamily: 'Oswald',
                                fontSize: 16,
                                color: idx == 0 ? SC.gold : SC.grey)),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),
                if (mp.isHost)
                  SovietButton(
                    label: '↩ VOLTAR AO LOBBY',
                    onTap: mp.hostBackToLobby,
                  )
                else
                  const Text(
                    'Aguardando host voltar ao lobby...',
                    style: TextStyle(
                        fontFamily: 'Oswald', fontSize: 13, color: SC.grey),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Actions ───────────────────────────────────────────────
  Future<void> _startHost() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _busy = true);
    final mp = context.read<MpProvider>();
    await mp.startHost(_nameCtrl.text.trim());
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _joinGame() async {
    final ip = _ipCtrl.text.trim();
    if (ip.isEmpty || _nameCtrl.text.trim().isEmpty) return;
    setState(() => _busy = true);
    final mp = context.read<MpProvider>();
    await mp.joinGame(ip, _nameCtrl.text.trim());
    if (mounted) setState(() => _busy = false);
  }
}

// ── Widgets auxiliares ─────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget child;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SC.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontFamily: 'Oswald',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: SC.cream,
                      letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(
                  fontFamily: 'Oswald', fontSize: 11, color: SC.grey)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _PlayerTile extends StatelessWidget {
  final String name;
  final bool isHost;
  final bool isMe;

  const _PlayerTile({
    required this.name,
    required this.isHost,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(isHost ? '👑' : '✊', style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(name,
                style: TextStyle(
                    fontFamily: 'Oswald',
                    fontSize: 14,
                    color: isMe ? SC.gold : SC.cream,
                    fontWeight: isMe ? FontWeight.w700 : FontWeight.normal)),
          ),
          if (isHost)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: SC.red.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: SC.red),
              ),
              child: const Text('HOST',
                  style: TextStyle(
                      fontFamily: 'Oswald',
                      fontSize: 9,
                      color: SC.red,
                      letterSpacing: 1)),
            ),
          if (isMe)
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: SC.gold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('VOCÊ',
                  style: TextStyle(
                      fontFamily: 'Oswald',
                      fontSize: 9,
                      color: SC.gold,
                      letterSpacing: 1)),
            ),
        ],
      ),
    );
  }
}

class _GameButton extends StatelessWidget {
  final String icon;
  final String title;
  final String desc;
  final VoidCallback onTap;
  final Color color;

  const _GameButton({
    required this.icon,
    required this.title,
    required this.desc,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontFamily: 'Oswald',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: color)),
                  Text(desc,
                      style: const TextStyle(
                          fontFamily: 'Oswald', fontSize: 11, color: SC.grey)),
                ],
              ),
            ),
            Icon(Icons.play_arrow, color: color, size: 24),
          ],
        ),
      ),
    );
  }
}
