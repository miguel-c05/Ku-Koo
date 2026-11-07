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
