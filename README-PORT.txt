Hex V3 -> VS Impostor: Legacy Mobile — build gerado

Instalação
1. Faça backup da pasta do mod anterior.
2. Extraia a pasta inteira `hex-v3-legacy-port` dentro da pasta `content` do VS Impostor: Legacy.
3. Abra o jogo e confira as músicas de Freeplay e o log HScript. Este pacote foi validado estaticamente; não foi executado no Android nesta sessão.

Conteúdo detectado e convertido
- 30 variações de música com chart e metadata encontrados; veja `PORT-REPORT.json` para audio/assets ausentes.
- 28 stages JSON convertidos em arquivos `.hx`/`.json` do Legacy; conversão dos props não significa equivalência de shaders ou scripts Haxe do Hex.
- Sete charts de ModChart da branch `main` processados pelo exportador quando o download/local source funcionou. O JSON `HEX_MODCHART_CONVERSION_REPORT.json` registra expressões e hooks que não puderam ser traduzidos.
- Runtime global, aliases de modifiers Hex e bridge para stage copiados para `scripts/` e `scripts/modifiers/`.
- Reconciliação pós-build de eventos a partir do chart Hex, normalização de z-index estático e relatório `hex_v3_legacy_repair_report.txt`; auditoria somente leitura em `STAGE-DIAGNOSTICS.json` e `.txt` lista gaps de assets/posições.
- HUD visual Hex: letterbox, círculos inferiores, timer, escala de ícones, reposicionamento aproximado da health bar e posicionamento dos julgamentos; assets/fontes disponíveis copiados quando encontrados.
- Looks/shaders Hex copiados quando os arquivos fonte existem no repositório extraído.

Skins
- As flags `allowBFskin` e `allowGFskin` são habilitadas em Freeplay para todas as músicas, exceto Bombs N' Combs, Eye2Eye, Right Pace, That Retro Song e Jumpin'. `allowPet` fica desligado.
- Limitação da própria engine: `PlayState.hx` aplica `!isStoryMode && SONG.allowBFskin/allowGFskin`, então HScript/JSON não reativa skin no Story Mode sem mudança nativa.

Limitações técnicas importantes
- O exportador Haxe->JSON lê `to()`/`jump()`, expande loops constantes e aproxima alguns hooks; ele não interpreta a DSL do Hex integralmente. `layer`, `virtual`, `make`, `base`, hooks com closures, callbacks 3D, geometria de `stage3d`, FOV/objetos de câmera e campos adicionais podem ficar incompletos.
- Os ModCharts Hex listam quatro IDs de player/field em algumas músicas; o Legacy Mobile não cria automaticamente os mesmos quatro note fields. O port não muda `lanes` para 4 sem mapear a estrutura de notas, para evitar charts reclassificados.
- Eye2Eye usa o runtime dedicado `songs/eye2eye/eye2eye.hx`; a saída cues de Eye2Eye é intencionalmente ignorada para não duplicar transformações. Os efeitos 3D/scene continuam aproximados e precisam de validação visual no aparelho.
- O HUD original do Hex inclui pause/game-over próprios, transições e diálogos da Story Mode em classes compiladas. O pacote porta a camada visual acessível por HScript, não substitui essas classes nativas.
- Shaders são copiados e os canais `screen.glitch`, `stage.gray` e `stage.invert` usam um shader de pós-processamento leve, anexado sem remover filtros já existentes quando a API permite. Look LUT é animado através de `characterLook.frag` quando existe a imagem `<characterId>-<look>.png`.
- Nenhum teste de gameplay real foi executado nesta sessão. Teste iniciar, pular introdução, pause/resume, retry/restart, sustains, splashes, troca de personagem, shaders e cada chart no Android; use `PORT-REPORT.json` e `HEX_MODCHART_CONVERSION_REPORT.json` para priorizar diferenças.

Arquivos úteis
- `data/modcharts/*.json`: cues exportados dos sete ModCharts suportados.
- `scripts/HexModchartRuntime.hx`: timeline, eventos, shader look/post-FX e reset.
- `scripts/modifiers/HexCompatibility.hx`: canais Hex compatíveis com o sistema de modifiers do Legacy.
- `scripts/HexCompatibilityBridge.hx`: ponte entre modifiers e stage.
- `scripts/HexGameplayHUD.hx`: camada visual do HUD Hex.
