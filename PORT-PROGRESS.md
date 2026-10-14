# Hex V3 Legacy Port — progresso

Atualizado em 2026-10-14. Este arquivo registra a auditoria local da primeira passagem de correções; não significa que houve teste dentro do jogo.

## 1. Charts e eventos — EM REPARO
- [x] Charts Easy/Normal/Hard encontrados e JSONs inspecionados estruturalmente.
- [x] Eventos em arquivos `events.json` contabilizados; handlers gerais já existem em `scripts/HexModchartRuntime.hx`.
- [x] Primeiros handlers HScript para `hex`, `hexAnd`, `mine_reg` e `mine_slasher` instalados localmente.
- [x] Assets de mina/explosão copiados do Hex V3 original.
- [ ] Verificar visualmente todas as notas especiais, miss/hold behavior, retry e botplay no Android.
- [ ] Auditar manualmente os eventos exclusivos que não estejam cobertos pelo runtime.

Tipos especiais encontrados nesta auditoria: `{"hex": 118, "hexAnd": 264, "mine_slasher": 62, "mine_reg": 253}`.

## 2. Stages e eventos de stages — CONVERTIDOS, NÃO VALIDADOS EM JOGO
- [x] O port contém pares de stage `.hx` e `.json`.
- [ ] Corrigir e executar de novo o diagnóstico de assets/posições; o relatório anterior falhou por `PermissionError` ao tentar inspecionar `/`.
- [ ] Conferir transições, objetos, zIndex e eventos por música no aparelho.

## 3. Shaders especiais — PARCIAL
- [x] Shaders e runtime pós-processamento existentes.
- [ ] Comparar os efeitos de cada música com o Hex original e substituir aproximações.
- [ ] Medir FPS/memória no celular; nenhuma medição de desempenho foi realizada por esta auditoria.

## 4. Story Mode — AINDA NÃO IMPLEMENTADO
- [ ] Implementar popup de escolha entre versões normais e 2026 para Week X e Weekend X.
- [ ] Não habilitar as semanas para Story Mode antes do popup: atualmente cada lista de semana inclui as variantes de versões, e habilitá-las sem separar a playlist faria tocar versões duplicadas em sequência.

## 5. Freeplay e dificuldade do chart — AINDA NÃO IMPLEMENTADO
- [x] Os charts Easy/Normal/Hard existem nos arquivos.
- [ ] Trocar portraits por elementos do Freeplay original do Hex.
- [ ] Ligar a escolha de dificuldade ao carregamento; o `FreeplayState.loadSong()` nativo usa o parâmetro padrão se não receber uma dificuldade explícita.

## 6. Modcharts e dificuldade — PROTÓTIPO
- [x] Runtime, bridge, modifier de compatibilidade e cues convertidos existem.
- [ ] Resolver as expressões ainda não traduzidas e comparar cues com o código original.
- [ ] Só depois adicionar Easy, Normal, Hard e Off independente da dificuldade do chart.

## Validação desta passagem
- Charts JSON estruturalmente inválidos: 0
- Arquivos de áudio esperados ausentes: 0
- Referências de stage sem JSON: 0
- Tipos de nota dos charts sem handler HScript: 0
- Assets de minas ainda ausentes: 0

**Importante:** os handlers de minas e Hex são uma primeira adaptação para a API do Legacy, não uma equivalência garantida com o engine original do Hex. Faça cópia de segurança, teste em Android e observe o log HScript antes de considerar a etapa concluída.
