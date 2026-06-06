# 星奈 Seina — Waifu Virtual Local

100% offline • CachyOS / Arch Linux • Firefox-friendly

## Stack
| Componente | Ferramenta        |
|------------|-------------------|
| STT        | faster-whisper    |
| LLM        | Ollama (Qwen)     |
| TTS        | piper-tts (pt-BR) |
| Áudio in   | sounddevice       |
| Áudio out  | aplay / pw-play   |

## Instalação rápida

```bash
# 1. Clone / copie os arquivos
cd seina/

# 2. Instale dependências
bash instalar.sh

# 3. Rode Ollama em outro terminal (com CORS liberado)
OLLAMA_ORIGINS='*' ollama serve

# 4. Garanta que tem o modelo
ollama pull qwen2.5:latest

# 5. Rode a Seina
python3 seina.py
```

## Variáveis de ambiente

```bash
OLLAMA_URL=http://localhost:11434   # padrão
OLLAMA_MODEL=qwen2.5:latest        # ou qwen2.5:7b, etc.
WHISPER_MODEL=small                 # tiny/base/small/medium
PIPER_VOICE=faber                   # faber (padrão) ou edresson
```

## Como usar

- **Enter** → começa a gravar
- **Enter** → para a gravação
- A Seina transcreve, pensa e responde com voz
- **Ctrl+C** → sai

## Downloads automáticos (primeira execução)

- piper-tts binary (~5MB)
- Voz pt-BR faber-medium (~60MB)
- Modelo Whisper small (~240MB, cachê em ~/.cache/huggingface)

## Personalidade

Edite `SYSTEM_PROMPT` no início do `seina.py` para mudar a personalidade.

## Vozes disponíveis

- `faber` — voz masculina jovem (funciona bem em TTS feminino com pitch)
- `edresson` — voz masculina (piper pt-BR é limitado, soa natural)

> Dica: para voz mais feminina, experimente vozes es-ES ou en-US do piper
> que têm opções femininas mais variadas. Defina PIPER_VOICE=amy por exemplo
> e edite a URL no código para apontar para a voz inglesa desejada.
