// ══════════════════════════════════════════════════════════════
//  MpScreen — Hub de Multiplayer via UDP LAN
//  • HOST cria sala → broadcast automático na rede
//  • CLIENT escaneia e vê salas disponíveis na lista
//  • Sem digitar IP manualmente
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
  bool _busy = false;
  bool _scanning = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mp = context.watch<MpProvider>();

    if (mp.isConnected) {
      if (mp.phase == MpGamePhase.playing) return _buildGame(mp);
      if (mp.phase == MpGamePhase.result) return _buildResult(mp);
      return _buildLobby(mp);
    }
    return _buildConnect(mp);
  }

  // ── Tela de conexão ───────────────────────────────────────
  Widget _buildConnect(MpProvider mp) {
    return SingleChildScrollView(
      child: Column(children: [
        const SovietHeader(
          title: '☭ BATALHA SOVIÉTICA ☭',
          subtitle: 'Multiplayer Wi-Fi Local — mesma rede, sem internet',
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // Nome
            _SovietField(
              label: 'SEU NOME DE GUERRA',
              controller: _nameCtrl,
              icon: Icons.person,
            ),
            const SizedBox(height: 16),

            // HOST
            _ActionCard(
              icon: '📡',
              title: 'CRIAR SALA (HOST)',
              subtitle: 'Sua sala aparece automaticamente para outros jogadores na rede',
              color: SC.red,
              child: _busy
                  ? const Center(child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(SC.gold)))
                  : SovietButton(label: '☭ CRIAR SALA', onTap: _startHost),
            ),
            const SizedBox(height: 12),

            // CLIENT — escanear
            _ActionCard(
              icon: '🔍',
              title: 'ENTRAR EM SALA',
              subtitle: 'Salas disponíveis na sua rede aparecem automaticamente',
              color: SC.goldDark,
              child: Column(children: [
                if (!_scanning)
                  SovietButton(
                    label: '🔍 BUSCAR SALAS',
                    onTap: _busy ? null : _startScan,
                    bgColor: SC.goldDark,
                    borderColor: SC.gold,
                    textColor: Colors.black,
                  )
                else ...[
                  // Lista de salas encontradas
                  if (mp.availableRooms.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(SC.gold)),
                          ),
                          const SizedBox(width: 12),
                          const Text('Procurando salas...',
                              style: TextStyle(fontFamily: 'Oswald', fontSize: 13, color: SC.grey)),
                        ],
                      ),
                    )
                  else
                    ...mp.availableRooms.map((room) => _RoomTile(
                          room: room,
                          onJoin: _busy ? null : () => _joinRoom(room),
                        )),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _stopScan,
                    child: const Text('✕ Cancelar busca',
                        style: TextStyle(fontFamily: 'Oswald', fontSize: 12, color: SC.grey)),
                  ),
                ],
              ]),
            ),

            if (mp.errorMsg != null) ...[
              const SizedBox(height: 12),
              _ErrorBox(msg: mp.errorMsg!),
            ],

            const SizedBox(height: 20),
            _HowItWorks(),
          ]),
        ),
      ]),
    );
  }

  // ── Lobby ─────────────────────────────────────────────────
  Widget _buildLobby(MpProvider mp) {
    return Column(children: [
      SovietHeader(
        title: mp.isHost ? '☭ SALA DO HOST ☭' : '☭ SALA DE ${mp.hostIp} ☭',
        subtitle: '${mp.playerCount} jogador(es) conectado(s)',
        actions: [
          GestureDetector(
            onTap: () async { await mp.disconnect(); setState(() => _scanning = false); },
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Text('✕', style: TextStyle(color: SC.cream, fontSize: 20)),
            ),
          ),
        ],
      ),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // IP info (host)
            if (mp.isHost)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: SC.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SC.gold, width: 2),
                ),
                child: Column(children: [
                  const Text('✅ SALA ATIVA — OUTROS JÁ PODEM ENCONTRÁ-LA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: 'Oswald', fontSize: 11, color: SC.gold, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(mp.myIp,
                        style: const TextStyle(
                            fontFamily: 'Oswald', fontWeight: FontWeight.w700,
                            fontSize: 22, color: SC.cream, letterSpacing: 3)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: mp.myIp));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('IP copiado! ☭'),
                          backgroundColor: SC.card,
                          duration: Duration(seconds: 1),
                        ));
                      },
                      child: const Icon(Icons.copy, color: SC.gold, size: 18),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  const Text('Todos no mesmo Wi-Fi entram automaticamente',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Oswald', fontSize: 10, color: SC.grey)),
                ]),
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
                  Text('JOGADORES NA SALA (${mp.playerCount})',
                      style: const TextStyle(
                          fontFamily: 'Oswald', fontSize: 12, color: SC.gold, letterSpacing: 2)),
                  const SizedBox(height: 10),
                  // Host
                  _PlayerTile(
                    name: mp.isHost ? '${mp.myName} (você)' : 'HOST',
                    isHost: true,
                    isMe: mp.isHost,
                  ),
                  // Clientes
                  ...mp.players.map((p) => _PlayerTile(
                        name: p.name + (p.id == mp.myIp ? ' (você)' : ''),
                        isHost: false,
                        isMe: p.id == mp.myIp,
                      )),
                  if (mp.players.isEmpty && mp.isHost)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Aguardando jogadores entrarem...',
                          style: TextStyle(fontFamily: 'Oswald', fontSize: 13, color: SC.grey)),
                    ),
                ],
              ),
            ),

            // Seleção de jogo (apenas HOST)
            if (mp.isHost) ...[
              const SizedBox(height: 20),
              const SovietDivider(label: 'ESCOLHER JOGO'),
              const SizedBox(height: 12),
              if (mp.players.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SC.cardDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: SC.redDark),
                  ),
                  child: const Text(
                    '⚠️ Aguarde pelo menos 1 jogador para iniciar um jogo',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Oswald', fontSize: 12, color: SC.grey),
                  ),
                )
              else ...[
                _GameButton(
                  icon: '👆', title: 'TAP BATTLE',
                  desc: 'Quem toca mais vezes em 15s vence',
                  onTap: () => mp.hostStartGame('tap'), color: SC.red,
                ),
                const SizedBox(height: 10),
                _GameButton(
                  icon: '🧠', title: 'MEMORY RACE',
                  desc: 'Ache mais pares que os camaradas',
                  onTap: () => mp.hostStartGame('memory'), color: SC.goldDark,
                ),
                const SizedBox(height: 10),
                _GameButton(
                  icon: '🔄', title: 'TROCA DE CARTAS',
                  desc: 'Negocie cartas com os camaradas',
                  color: SC.greenDark,
                  onTap: () {
                    final gp = context.read<GameProvider>();
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => MultiProvider(providers: [
                        ChangeNotifierProvider.value(value: mp),
                        ChangeNotifierProvider.value(value: gp),
                      ], child: const MpTradeScreen()),
                    ));
                  },
                ),
              ],
            ] else ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: SC.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SC.redDark),
                ),
                child: const Column(children: [
                  Text('⏳', style: TextStyle(fontSize: 40)),
                  SizedBox(height: 8),
                  Text('AGUARDANDO\nHOST INICIAR JOGO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: 'Oswald', fontSize: 16, color: SC.cream, letterSpacing: 2)),
                ]),
              ),
              const SizedBox(height: 12),
              // Cliente também pode ir para troca de cartas
              _GameButton(
                icon: '🔄', title: 'TROCA DE CARTAS',
                desc: 'Negocie cartas com os camaradas',
                color: SC.greenDark,
                onTap: () {
                  final gp = context.read<GameProvider>();
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => MultiProvider(providers: [
                      ChangeNotifierProvider.value(value: mp),
                      ChangeNotifierProvider.value(value: gp),
                    ], child: const MpTradeScreen()),
                  ));
                },
              ),
            ],
          ]),
        ),
      ),
    ]);
  }

  // ── Em jogo ───────────────────────────────────────────────
  Widget _buildGame(MpProvider mp) {
    if (mp.currentGame == 'tap') return MpTapBattle(mp: mp);
    if (mp.currentGame == 'memory') return MpMemoryRace(mp: mp);
    return const Center(child: Text('Jogo desconhecido', style: TextStyle(color: SC.cream)));
  }

  // ── Resultado ─────────────────────────────────────────────
  Widget _buildResult(MpProvider mp) {
    final ranking = (mp.lastResult?['ranking'] as List?) ?? [];
    final winner = mp.lastResult?['winner'] as String? ?? '???';

    return Column(children: [
      const SovietHeader(title: '☭ RESULTADO FINAL ☭'),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            const Text('🏆', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 8),
            Text(winner,
                style: const TextStyle(fontFamily: 'Oswald', fontWeight: FontWeight.w700,
                    fontSize: 28, color: SC.gold, letterSpacing: 2)),
            const Text('VENCEDOR!',
                style: TextStyle(fontFamily: 'Oswald', fontSize: 14, color: SC.cream)),
            const SizedBox(height: 24),
            ...ranking.asMap().entries.map((e) {
              final idx = e.key;
              final p = e.value as Map;
              const medals = ['🥇', '🥈', '🥉'];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: idx == 0 ? SC.gold.withValues(alpha: 0.15) : SC.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: idx == 0 ? SC.gold : SC.redDark,
                      width: idx == 0 ? 2 : 1),
                ),
                child: Row(children: [
                  Text(idx < medals.length ? medals[idx] : '${idx + 1}.',
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(p['name'] as String? ?? '?',
                        style: TextStyle(fontFamily: 'Oswald', fontWeight: FontWeight.w700,
                            fontSize: 16, color: idx == 0 ? SC.gold : SC.cream)),
                  ),
                  Text('${p['score']} pts',
                      style: TextStyle(fontFamily: 'Oswald', fontSize: 16,
                          color: idx == 0 ? SC.gold : SC.grey)),
                ]),
              );
            }),
            const SizedBox(height: 24),
            if (mp.isHost)
              SovietButton(label: '↩ VOLTAR AO LOBBY', onTap: mp.hostBackToLobby)
            else
              const Text('Aguardando host voltar ao lobby...',
                  style: TextStyle(fontFamily: 'Oswald', fontSize: 13, color: SC.grey)),
          ]),
        ),
      ),
    ]);
  }

  // ── Actions ───────────────────────────────────────────────
  Future<void> _startHost() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _busy = true);
    final mp = context.read<MpProvider>();
    await mp.startHost(_nameCtrl.text.trim());
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _startScan() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() { _scanning = true; _busy = false; });
    final mp = context.read<MpProvider>();
    await mp.startScanning(_nameCtrl.text.trim());
  }

  void _stopScan() {
    final mp = context.read<MpProvider>();
    mp.disconnect();
    setState(() => _scanning = false);
  }

  Future<void> _joinRoom(MpRoom room) async {
    setState(() => _busy = true);
    final mp = context.read<MpProvider>();
    final ok = await mp.joinRoom(room);
    if (mounted) {
      setState(() { _busy = false; _scanning = !ok; });
    }
  }
}

// ── Widgets auxiliares ─────────────────────────────────────────

class _SovietField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  const _SovietField({required this.label, required this.controller, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SC.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SC.redDark),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(
            fontFamily: 'Oswald', fontSize: 11, color: SC.gold, letterSpacing: 2)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(fontFamily: 'Oswald', color: SC.cream, fontSize: 16),
          decoration: InputDecoration(
            filled: true, fillColor: SC.cardDark,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: SC.red)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: SC.redDark)),
            prefixIcon: Icon(icon, color: SC.gold, size: 20),
          ),
        ),
      ]),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String icon, title, subtitle;
  final Color color;
  final Widget child;
  const _ActionCard({required this.icon, required this.title, required this.subtitle,
      required this.color, required this.child});

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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(
              fontFamily: 'Oswald', fontWeight: FontWeight.w700,
              fontSize: 14, color: SC.cream, letterSpacing: 1)),
        ]),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontFamily: 'Oswald', fontSize: 11, color: SC.grey)),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }
}

class _RoomTile extends StatelessWidget {
  final MpRoom room;
  final VoidCallback? onJoin;
  const _RoomTile({required this.room, this.onJoin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SC.cardDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SC.gold.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        const Text('📡', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(room.hostName,
                style: const TextStyle(fontFamily: 'Oswald', fontWeight: FontWeight.w700,
                    fontSize: 14, color: SC.cream)),
            Text('${room.playerCount} jogador(es) | ${room.hostIp}',
                style: const TextStyle(fontFamily: 'Oswald', fontSize: 10, color: SC.grey)),
          ]),
        ),
        GestureDetector(
          onTap: onJoin,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: SC.red, borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('ENTRAR', style: TextStyle(
                fontFamily: 'Oswald', fontWeight: FontWeight.w700,
                fontSize: 12, color: Colors.white)),
          ),
        ),
      ]),
    );
  }
}

class _PlayerTile extends StatelessWidget {
  final String name;
  final bool isHost, isMe;
  const _PlayerTile({required this.name, required this.isHost, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Text(isHost ? '👑' : '✊', style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(name,
              style: TextStyle(fontFamily: 'Oswald', fontSize: 14,
                  color: isMe ? SC.gold : SC.cream,
                  fontWeight: isMe ? FontWeight.w700 : FontWeight.normal)),
        ),
        if (isHost)
          _Badge(label: 'HOST', color: SC.red),
      ]),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Text(label, style: TextStyle(
          fontFamily: 'Oswald', fontSize: 9, color: color, letterSpacing: 1)),
    );
  }
}

class _GameButton extends StatelessWidget {
  final String icon, title, desc;
  final VoidCallback? onTap;
  final Color color;
  const _GameButton({required this.icon, required this.title, required this.desc,
      this.onTap, required this.color});

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
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontFamily: 'Oswald', fontWeight: FontWeight.w700,
                fontSize: 16, color: color)),
            Text(desc, style: const TextStyle(fontFamily: 'Oswald', fontSize: 11, color: SC.grey)),
          ])),
          Icon(Icons.play_arrow, color: color, size: 24),
        ]),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String msg;
  const _ErrorBox({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SC.red.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SC.red),
      ),
      child: Row(children: [
        const Text('⚠️', style: TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(
            fontFamily: 'Oswald', color: SC.cream, fontSize: 13))),
      ]),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SC.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SC.redDark.withValues(alpha: 0.5)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('☭ COMO FUNCIONA',
            style: TextStyle(fontFamily: 'Oswald', fontSize: 12, color: SC.gold, letterSpacing: 2)),
        const SizedBox(height: 8),
        ...[
          '📱 Todos no mesmo Wi-Fi',
          '📡 HOST cria sala → broadcast automático',
          '🔍 Clientes clicam em "Buscar Salas"',
          '⚡ Sala aparece na lista → clique ENTRAR',
          '🎮 Jogos: Tap Battle, Memory Race, Troca',
          '✅ Funciona em qualquer Android (sem root)',
        ].map((t) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('• $t', style: const TextStyle(
                  fontFamily: 'Oswald', fontSize: 12, color: SC.cream)),
            )),
      ]),
    );
  }
}
