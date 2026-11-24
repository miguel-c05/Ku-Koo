# Ku-Koo — Movement demo

Cena: `Scenes/movement_demo.tscn` (definida como cena principal, F5 corre-a).
Tudo é placeholder: quadrados coloridos e sons sintetizados.

## Controlos
| Tecla | Ação |
|---|---|
| A / D | andar |
| W / S | olhar para cima / baixo |
| Espaço | saltar · no ar: bater asas (1x, depois queda lenta) |
| E ou J | bicar (apanhar, largar, dar, partir fio, puxar trinco, agarrar e empurrar/puxar) |
| Q ou K | arrulhar |
| R / F1 | recomeçar / esconder ajuda |

Comando: A saltar, X bicar, Y arrulhar.

## Percurso da demo
1. Andar → saltar para o caixote → bater asas para chegar ao parapeito alto.
2. Bicar o fio (2 bicadas) → o bacalhau cai → apanhá-lo → dá-lo ao gato com fome que bloqueia a passagem.
3. Agarrar a caixa, empurrá-la contra o muro e usá-la como degrau.
4. Bicar o trinco → o portão abre.
5. Arrulhar: a pessoa vira-se, a folha treme, a companheira responde de casa (pista à direita do ecrã).
6. Afastar a folha → apanhar a minhoca.

## Estrutura
```
Scripts/Pigeon/       pigeon.gd (física), peck_ability, coo_ability, beak_hold,
                      pigeon_visuals (apresentação), pigeon_audio
Scripts/Interaction/  Interactable (base) + Pickup, Grab, Breakable, Toggle,
                      ItemReceiver, CooListener, CarryableItem, PushableBody
Scripts/World/        blocos, câmara, prompts, partner_call, slide_mover, trembler...
Scripts/Props/        gato, pessoa, trinco, folha
Scripts/Audio/        SoundBank (resource), EventSound
Scenes/Pigeon|Props|World|UI
Assets/Sprites/Placeholders, Assets/Audios/Placeholders
```

A jogabilidade nunca toca em arte nem som: o `Pigeon` emite `action(nome)`
(`jump, flap, land, step, peck, peck_hit, coo, pick_up, drop, give, grab, release`)
e expõe `state` (`IDLE, WALK, AIR, PECK, COO, PUSH`). Visuais e áudio só escutam.
Os puzzles ligam-se por sinais no editor (Node > Signals), sem código novo.

## Arte real já integrada
- `Assets/Sprites/Pigeon/`: `pigeon_idle.png` (do `pombo.png`) e `pigeon_walk_01..08.png`
  (extraídos de `pombo_andar.mp4`, fundo preto removido, 25% da resolução original).
- `pigeon_frames.tres`: animações `idle` (1 frame) e `walk` (8 frames, 8 fps, velocidade
  acompanha a do pombo). Sem animação `peck`, o sprite inclina 45° nos pés ao bicar
  (`peck_tilt_*` no nó `Visuals`). Estados sem animação usam `idle`.
- O Godot não reproduz `.mp4`: novas animações entram como sequências PNG no SpriteFrames.
- O `AnimatedSprite2D` tem a origem nos pés (`offset`); escala 0.22.

## Substituir por assets reais
- **Pombo (arte):** em `pigeon.tscn > Visuals > AnimatedSprite2D`, criar um SpriteFrames com as animações
  `idle, walk, jump, fall, glide, peck, coo, push` (+ opcionais `flap, land, pick_up, drop`).
  O rig placeholder esconde-se sozinho. Em alternativa, trocar só as texturas das partes em `Visuals/Rig`.
- **Pombo (som):** editar `Assets/Audios/pigeon_sound_bank.tres` (nome do evento → AudioStream;
  um AudioStreamRandomizer dá variações).
- **Props:** trocar a textura do `Sprite2D` de cada cena em `Scenes/Props`; sons nos nós `EventSound`.
- **Cenário:** cada `PlaceholderBlock` aceita um `Sprite2D` filho; desligar `show_placeholder`.
  As camadas de parallax (`PlaceholderSkyline`) passam a ser imagens dentro dos mesmos `Parallax2D`.
- **Remover ao ter som real:** `CooRing` e balões de texto (substituem o som na demo), pista da
  companheira e linha de estado no `DemoHUD`.

## Afinação
Valores no Inspector do `Pigeon`: altura do salto ≈ 55 px, salto + asas ≈ 93 px.
`max_air_flaps = -1` dá voo livre (para a floresta tutorial, mais tarde).
Camadas de física: 1 world · 2 pigeon · 3 props · 4 items · 5 interactables.

---

# Movement demo isométrica (estilo Hades)

Cena: `Scenes/movement_demo_iso.tscn` (abrir e F6). Mesmo pombo, mesmos assets, mesmas ações
e o mesmo percurso, mas vista de cima isométrica (tiles 64×32).

| Tecla | Ação |
|---|---|
| WASD / setas | andar em 8 direções (as diagonais seguem os eixos do chão) |
| Espaço | saltar · no ar: bater asas (1x, queda lenta) |
| E/J · Q/K · R · F1 | bicar · arrulhar · recomeçar · ajuda |

**Altura em vez de gravidade:** o salto é uma altura `z` acima do chão; a sombra fica no chão e
mostra onde se aterra. Os obstáculos têm altura: cerca baixa (12) salta-se, plataforma (34)
precisa de salto + asas, rebordo alto (56) precisa da caixa + salto + asas, muros (60+) bloqueiam.
O pombo pode estar em cima de caixas e plataformas, e só bica o que está à altura do bico
(o fio do bacalhau só se alcança de cima do rebordo).

**Percurso (sobe o ecrã, de baixo-direita para cima-esquerda, como no Hades):** cerca →
plataforma → rebordo + fio + bacalhau (pendurado à frente do rebordo) → gato na passagem do
muro → caixa empurrada até ao terraço alto → trinco e portão (afunda no chão) → pátio do
arrulho (pessoa, folha, companheira) → degrau final. Como se avança para o fundo, cada
obstáculo é abordado pelas faces visíveis.

**Ordem de desenho e visibilidade:** não se usa o y-sort do Godot. O `IsoDepthSorter` dá a cada
filho de `World` um `z_index` = profundidade; quem está em cima de algo (pombo, objetos) fica
sempre à frente do que o suporta. Blocos altos (≥ 30) ficam semitransparentes quando o pombo
está atrás deles.

**Código (`Scripts/Iso`, `Scenes/Iso`):**
- `PigeonTopDown` estende `Pigeon`: reaproveita bicar, arrulhar, bico, visuais (sprite real) e
  som; `pigeon_iso.tscn` é uma cena herdada de `pigeon.tscn` (arte nova chega às duas demos).
- `IsoMath`: projeção, alturas e colisão por altura. `IsoDepthSorter`: ordem de desenho. `IsoBlock`: bloco com altura (origem no
  centro da base; muros longos em segmentos de 1 tile por causa do y-sort).
- `IsoPushableBody`, `IsoCarryableItem`: caixa e objetos sem gravidade no ecrã.
- Gato, folha e bacalhau têm variantes iso; pessoa, trinco, companheira e HUD são os mesmos.
- Os interativos ganharam `height` (só conta na vista iso; a demo lateral ignora-o).

Para trocar o chão e os blocos por arte: `IsoFloor` → `TileMapLayer` isométrico; cada `IsoBlock`
aceita um `Sprite2D` filho com `show_placeholder` desligado.

---

# Nível 1 · o talho

Cena: `Scenes/Level1/level_1_butchery.tscn` (abrir e F6). Vista lateral, segue o GDD batida a batida.
Três salas da esquerda para a direita, placeholders, sem música.

1. **Abertura:** ecrã preto, arrulho da companheira ao longe à direita, fade-in no enquadramento do
   quadro; o controlo só começa depois de uma pausa.
2. **Pendurado:** A / D baloiçam (pêndulo). Bicar só parte o fio no alto do balanço (≥ 42°); mais
   abaixo só abana. O pombo cai no saco de grão com o balanço que levava.
3. **Sala 1:** passa por baixo dos animais pendurados, sobe caixote → barril → prateleira, bica a
   corda do trinco e afasta-se para a puxar: a porta abre.
4. **Corredor:** ninho de checkpoint na prateleira. O caçador corta em ciclo; o cutelo pára, um
   instante depois olha ~2 s. Visto na luz enquanto olha = apanhado (som, corte a preto, volta ao
   ninho). Atrás do balde ou na sombra não é visto. "Fica na sombra" só aparece após a 1.ª captura.
5. **Entrada:** casaco e sapatos de criança, porta da rua fechada. Empurra o banco até à cadeira,
   sobe banco → cadeira → banco da janela, bica a portada e sai: fim do nível.

Instruções no ecrã: só as três novas do GDD (baloiçar, bicar o fio, puxar) + "fica na sombra".

**Scripts (`Scripts/Level1`):** `HangingString` (prego, fio, pêndulo), `PullCord` (corda que se
agarra e puxa), `SwingDoor` (porta/portada), `Hunter` (ciclo cortar/pausa/olhar/voltar, desenhado
em código; aceita um `AnimatedSprite2D` com chop, pause, look, turn, reach), `LightZone`,
`HidingSpot`, `CheckpointNest`, `Level1Butchery` (abertura, checkpoints, captura, fim).
Gerais: `TriggerZone`, `PlaceholderDecor` (animais pendurados, moscas, feixes de luz, retângulos).

**Afinação:** caçador — `chop_time`, `pause_time`, `look_time` no nó `Hunter`; fio —
`break_angle_degrees`, `pump_strength`, `length` no `HangingString`. O banco é obrigatório:
a cadeira (100 px) fica acima de salto + asas (≈ 93 px).

## Nível 1 com a arte da equipa (nov. 2026)

O nível usa agora os cenários pintados (1920×1080 cada) à escala 0,378 (chão de cada sala = y 0;
a câmara mostra uma sala inteira de altura, como no GDD):
**quarto dos pendurados → porta com a corda do trinco → corredor A → corredor B → entrada.**

- **Pombo:** todas as animações novas (idle, andar, bicar, saltar/bater asas/cair/aterrar, arrulhar,
  apanhar/largar, empurrar, puxar) normalizadas para a mesma escala e com os pés no mesmo ponto
  (`Assets/Sprites/Pigeon/Frames`, `pigeon_frames.tres`). Pendurado usa um sprite próprio
  (`HangSprite`, `pigeon_hang_frames.tres`) ancorado no fio. Vale para todas as cenas.
- **Fio:** o prego está sobre o saco de grão em cima do barril; o fio parte a partir de 25° e o
  balanço vai até 40°, por isso a queda cai no saco.
- **Objetos pintados no fundo** (barril, caixotes, sacos, cadeira, mesa, parapeito) são plataformas
  atravessáveis por baixo: dá para subir, não bloqueiam a passagem.
- **Porta:** secção construída com o kit de interior + a porta com a corda; um caixote para chegar
  à corda; a porta roda ao abrir.
- **Fase furtiva mais longa:** duas passagens. O caçador é visto pela porta aberta do corredor,
  na oficina (Workroom) por trás. Corredor A: balde → luz → sombra. Corredor B (escuro): caçador
  mais rápido, duas poças de luz com um barril no meio para se esconder. Um ninho por corredor.
- **Entrada:** começa escura; o banco está junto à porta e puxa-se para debaixo da mesa;
  banco → mesa → parapeito; bicar a portada (brilha quando o bico está nela) abre-a, a sala passa
  à versão iluminada, entra o feixe de luz com pó e o pombo sai pela janela.
- **Fontes:** Special Elite é a fonte por omissão do projeto (instruções no cenário, HUD).
- Ainda sem arte: o caçador (placeholder desenhado em código) e os sons.
- Não usados por agora: Entrance_2 (sem janela), cesto/sacos v1.

## Nível 1: salas seguidas, um só tom (nov. 2026, revisão)

As salas estão lado a lado e a câmara acompanha o pombo, sem cortes. Todas as pinturas usam a
versão escura, acertadas para a mesma luminosidade; em cada junção o brilho sobe/desce até se
encontrar e a pintura da direita funde-se sobre a da esquerda (60 px). Ficheiros `Rooms/r1..r5_*.png`.

**Parte 1 (seguida): quarto dos pendurados → corredor da porta**
- No quarto, a parede da direita fecha a passagem pelo chão. O único caminho é a abertura lá em
  cima: caixote → caixote de cima → abertura → túnel curto pela parede → sai pelo pilar do
  corredor e cai em cima da mesa (a abertura fica com o aspeto da pintura, sem mancha escura).
- Ao passar, o quarto que fica para trás escurece (`RoomShade`) e o túnel fecha-se atrás do pombo.
- Coelho, lebre e pássaros pendurados à frente da câmara, a balançar.

**Porta (corte):** subir ao caixote, bicar a corda e puxar; a porta fechada desvanece e aparece a
porta aberta. Com o pombo em frente à porta aberta, **Enter** (ou B no comando) entra: corte a negro.

**Parte 2 (seguida): sala das armas → corredor do caçador → entrada**
- Sala das armas sem caçador; um pilar de madeira marca a junção com o corredor.
- Corredor do caçador (única cena furtiva): ninho → luz → balde → luz → barril → luz. O pombo fica
  à frente do balde/barril (do nosso lado) e escurece quando está escondido. Prateleira partida
  como decoração. O caçador só trabalha quando o pombo está nesta parte da casa.
- Entrada: banco, mesa, parapeito, portada; a luz do dia entra só nesta sala e esbate-se para o corredor.
- Dá para subir a mais coisas: o balde do corredor da porta e a tina da sala das armas; no fim do
  corredor do caçador, barril → prateleira partida → prateleira da parede (sem mesa: só a
  entrada tem mesa; o barril tem sombra no chão); na entrada,
  assento → encosto da cadeira → prateleira dos casacos.

**Código:** `LevelRoom` (sala; `segment` = salas que se juntam; a câmara fica nos limites do
segmento), `RoomPassage` (porta para outro segmento; `require_action = enter_door` obriga a
carregar Enter), `RoomShade`, `ForegroundSway`. `PlaceholderBlock` ganhou `solid` /
`make_solid()` (o túnel que se fecha). Nova ação de input `enter_door` (Enter, Enter do teclado
numérico, botão B). Arte gerada por `build_l1_strip.py`. Ficheiros de arte antigos ficam na pasta,
mas a cena já não os usa.
