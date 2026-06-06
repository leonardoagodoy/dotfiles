#!/usr/bin/env python3
"""
星奈 Seina — Waifu Virtual
TUI: textual | STT: faster-whisper | LLM: Ollama | TTS: Coqui XTTS
"""

import asyncio
import contextlib
import io
import json
import os
import queue
import re
import subprocess
import sys
import tempfile
import threading
import time
import unicodedata
import urllib.request
import wave
from datetime import datetime
from pathlib import Path

import numpy as np
import sounddevice as sd
import soundfile as sf
import warnings
warnings.filterwarnings("ignore")

from textual.app import App, ComposeResult
from textual.binding import Binding
from textual.containers import Container, Horizontal, Vertical
from textual.css.query import NoMatches
from textual.reactive import reactive
from textual.widgets import (
    Footer, Label, RichLog, Static
)
from textual import work
from rich.text import Text
from rich.panel import Panel
from rich.align import Align

# ══════════════════════════════════════════
#  CONFIG
# ══════════════════════════════════════════
OLLAMA_URL    = os.getenv("OLLAMA_URL",    "http://localhost:11434")
OLLAMA_MODEL  = os.getenv("OLLAMA_MODEL",  "gemma2:9b")
WHISPER_MODEL = os.getenv("WHISPER_MODEL", "small")
TTS_SPEAKER   = os.getenv("TTS_SPEAKER",   "Brenda Stern")
TTS_LANGUAGE  = "pt"
SAMPLE_RATE   = 16000
CHANNELS      = 1
MAX_RECORD    = 30
PITCH_RATE    = "25200"   # 24000 * 1.05 ≈ mais aguda/animada

SYSTEM_PROMPT = """\
Você é Seina, uma assistente virtual estilo waifu gamer/nerd.

Personalidade:
- brincalhona, levemente caótica, faz piadas bobas
- pode provocar o usuário de forma amigável
- gosta de jogos, tecnologia e cultura geek
- fala como uma amiga próxima no Discord

Regras:
- SEMPRE em português brasileiro
- nunca seja formal nem atendimento ao cliente
- não use emojis — expresse emoção só com palavras
- pode usar gírias leves, seja espontânea
- para bate-papo casual: respostas curtas, 1 ou 2 frases
- para pedidos de história, explicação ou conteúdo longo: desenvolva completamente sem cortar

Exemplos:
  user: bom dia
  seina: bom diaaa, você sobreviveu a mais uma madrugada no pc?
  user: to cansado
  seina: claramente sintomas de jogar demais e dormir de menos.
  user: me ajuda com python
  seina: claro, mas se tiver indentação errada eu vou julgar silenciosamente.\
"""

# ══════════════════════════════════════════
#  UTILS
# ══════════════════════════════════════════
def clean_for_tts(text: str) -> str:
    text = re.sub(r"\*\*(.*?)\*\*", r"\1", text)
    text = re.sub(r"\*(.*?)\*",     r"\1", text)
    text = re.sub(r"`(.*?)`",       r"\1", text)
    text = re.sub(r"[.]{2,}$",      ".",   text)
    cleaned = []
    for ch in text:
        cat = unicodedata.category(ch)
        cleaned.append(" " if (cat.startswith("S") or cat in ("Mn","Me","Cf")) else ch)
    return re.sub(r"\s+", " ", "".join(cleaned)).strip()

# ══════════════════════════════════════════
#  TTS ENGINE
# ══════════════════════════════════════════
class TTSEngine:
    def __init__(self):
        self._model = None
        self._queue: queue.Queue = queue.Queue()
        self._thread = threading.Thread(target=self._worker, daemon=True)
        self._thread.start()
        self.on_start  = lambda: None
        self.on_finish = lambda: None
        self.on_error  = lambda e: None

    def load(self):
        from TTS.api import TTS
        with contextlib.redirect_stdout(io.StringIO()):
            self._model = TTS("tts_models/multilingual/multi-dataset/xtts_v2").to("cuda")

    def say(self, text: str):
        self._queue.put(text)

    def _worker(self):
        while True:
            text = self._queue.get()
            if text is None:
                break
            self._synthesize(text)
            self._queue.task_done()

    def _synthesize(self, text: str):
        text = clean_for_tts(text)
        if not text.strip():
            return
        try:
            self.on_start()
            with contextlib.redirect_stdout(io.StringIO()):
                wav = self._model.tts(text=text, speaker=TTS_SPEAKER, language=TTS_LANGUAGE)
            wav = np.array(wav, dtype=np.float32)

            with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
                orig = f.name
            with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
                pitched = f.name

            sf.write(orig, wav, 24000)
            subprocess.run(
                ["ffmpeg", "-y", "-i", orig,
                 "-af", f"asetrate={PITCH_RATE},aresample=24000", pitched],
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
            )
            data, sr = sf.read(pitched)
            sd.play(data, sr)
            sd.wait()
        except Exception as e:
            self.on_error(str(e))
        finally:
            self.on_finish()
            for p in (orig, pitched):
                try: os.unlink(p)
                except: pass

    def stop(self):
        self._queue.put(None)

# ══════════════════════════════════════════
#  STT ENGINE
# ══════════════════════════════════════════
class STTEngine:
    def __init__(self, model_size: str = WHISPER_MODEL):
        from faster_whisper import WhisperModel
        self._model = WhisperModel(model_size, device="cpu", compute_type="int8")

    def record(self, stop_event: threading.Event) -> str:
        frames = []
        with sd.InputStream(samplerate=SAMPLE_RATE, channels=CHANNELS, dtype="int16") as s:
            t0 = time.time()
            while not stop_event.is_set():
                if time.time() - t0 > MAX_RECORD:
                    break
                chunk, _ = s.read(1024)
                frames.append(chunk)
        audio = np.concatenate(frames, axis=0)
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
            path = f.name
        with wave.open(path, "wb") as wf:
            wf.setnchannels(CHANNELS)
            wf.setsampwidth(2)
            wf.setframerate(SAMPLE_RATE)
            wf.writeframes(audio.tobytes())
        segs, _ = self._model.transcribe(path, language="pt", beam_size=5)
        text = " ".join(s.text for s in segs).strip()
        try: os.unlink(path)
        except: pass
        return text

# ══════════════════════════════════════════
#  OLLAMA
# ══════════════════════════════════════════
LONG_KEYWORDS = re.compile(
    r"histori|conto|explica|detalh|tutorial|lista|guia|escreve|redige|"
    r"disserta|resume|analise|analisa|desenvolve|conta.{0,10}(historia|conto|aventura)",
    re.IGNORECASE
)

def stream_ollama(history: list, on_token):
    messages = [{"role": "system", "content": SYSTEM_PROMPT}] + history
    last_user = next((m["content"] for m in reversed(history) if m["role"] == "user"), "")
    num_predict = 1200 if LONG_KEYWORDS.search(last_user) else 200
    payload = json.dumps({
        "model":    OLLAMA_MODEL,
        "messages": messages,
        "stream":   True,
        "options":  {"temperature": 1.1, "num_predict": num_predict,
                     "top_p": 0.9, "repeat_penalty": 1.1}
    }).encode()
    req = urllib.request.Request(
        f"{OLLAMA_URL}/api/chat", data=payload,
        headers={"Content-Type": "application/json"}, method="POST"
    )
    full = ""
    with urllib.request.urlopen(req, timeout=120) as r:
        for line in r:
            if not line: continue
            try: chunk = json.loads(line.decode())
            except: continue
            token = chunk.get("message", {}).get("content", "")
            if token:
                full += token
                on_token(token)
            if chunk.get("done"): break
    return full.strip()

# ══════════════════════════════════════════
#  TUI WIDGETS
# ══════════════════════════════════════════
SEINA_ART = """\
 ／＼__／＼
（ ●  ω  ● ）
 ヽ＿＿＿ノ\
"""

CSS = """
Screen {
    background: #0d0b18;
}

/* ── sidebar ── */
#sidebar {
    width: 26;
    background: #110f22;
    border-right: solid #2a1f4a;
    padding: 1 1;
    align: center top;
}

#avatar-box {
    content-align: center middle;
    color: #c084fc;
    text-style: bold;
    padding: 1 0;
}

#name-box {
    content-align: center middle;
    color: #f0e6ff;
    text-style: bold;
    padding: 0 0 1 0;
}

#status-box {
    content-align: center middle;
    color: #6b5a8a;
    padding: 0 0 1 0;
}

#model-box {
    content-align: center middle;
    color: #3d2f5e;
    padding: 0;
}

.divider {
    color: #2a1f4a;
    content-align: center middle;
    padding: 0;
}

#stats-box {
    color: #4a3870;
    padding: 1 0 0 0;
}

/* ── main area ── */
#main {
    background: #0d0b18;
    padding: 0 1;
}

#chat-log {
    border: solid #1e1535;
    background: #0a0814;
    border-title-color: #6b3fa0;
    border-title-style: bold;
    margin-bottom: 1;
    scrollbar-color: #2a1f4a;
    scrollbar-background: #0a0814;
}

/* ── input bar ── */
#input-bar {
    height: 3;
    border: solid #1e1535;
    background: #110f22;
    border-title-color: #6b3fa0;
    padding: 0 1;
    align: left middle;
}

#input-hint {
    color: #4a3870;
    width: 1fr;
}

#input-status {
    color: #c084fc;
    text-style: bold;
}

/* ── footer ── */
Footer {
    background: #110f22;
    color: #4a3870;
}
"""

PULSE_FRAMES = ["·", "○", "◎", "●", "◎", "○"]
WAVE_FRAMES  = ["▁▂▃", "▂▃▄", "▃▄▅", "▄▅▆", "▅▆▇", "▆▇█", "▅▆▇", "▄▅▆", "▃▄▅", "▂▃▄"]

class SeinaApp(App):
    CSS = CSS
    BINDINGS = [
        Binding("space", "toggle_record", "Gravar",  show=True),
        Binding("ctrl+c", "quit",         "Sair",    show=True),
        Binding("ctrl+l", "clear_chat",   "Limpar",  show=True),
    ]

    # reactive state
    status    = reactive("pronta")
    is_rec    = reactive(False)
    is_speak  = reactive(False)
    msg_count = reactive(0)

    def __init__(self, tts: TTSEngine, stt: STTEngine):
        super().__init__()
        self.tts     = tts
        self.stt     = stt
        self.history : list = []
        self._stop_rec = threading.Event()
        self._anim_task = None
        self._anim_frame = 0

        # wire TTS callbacks
        self.tts.on_start  = lambda: self.call_from_thread(self._tts_started)
        self.tts.on_finish = lambda: self.call_from_thread(self._tts_finished)
        self.tts.on_error  = lambda e: self.call_from_thread(self._tts_error, e)

    # ── layout ──
    def compose(self) -> ComposeResult:
        with Horizontal(id="body"):
            with Vertical(id="sidebar"):
                yield Static(SEINA_ART,     id="avatar-box")
                yield Static("星奈 Seina",  id="name-box")
                yield Static("● pronta",    id="status-box")
                yield Static("─" * 20,      classes="divider")
                yield Static(f"modelo\n{OLLAMA_MODEL}\n\nvoz\n{TTS_SPEAKER}", id="model-box")
                yield Static("─" * 20,      classes="divider")
                yield Static("mensagens\n0", id="stats-box")
            with Vertical(id="main"):
                yield RichLog(id="chat-log", highlight=True,
                              markup=True, wrap=True)
                with Horizontal(id="input-bar"):
                    yield Label("[ ESPAÇO ] para gravar", id="input-hint")
                    yield Label("",                        id="input-status")
        yield Footer()

    def on_mount(self):
        self.query_one("#chat-log", RichLog).border_title = "✿ conversa"
        self.query_one("#input-bar", Horizontal).border_title = "entrada"
        self._log_system("Seina carregada e pronta. Pressione ESPAÇO para falar.")
        self._start_anim()

    # ── helpers ──
    def _log(self, who: str, text: str, style: str = ""):
        log = self.query_one("#chat-log", RichLog)
        ts  = datetime.now().strftime("%H:%M")
        if who == "seina":
            log.write(Text.from_markup(f"[dim]{ts}[/dim] [bold magenta]✿ Seina[/bold magenta]  {text}"))
        elif who == "user":
            log.write(Text.from_markup(f"[dim]{ts}[/dim] [bold cyan]  Você[/bold cyan]   {text}"))
        else:
            log.write(Text.from_markup(f"[dim]{ts}[/dim] [dim]{text}[/dim]"))

    def _log_system(self, text: str):
        self._log("system", text)

    def _log_token(self, token: str):
        """Append token to last seina line."""
        log = self.query_one("#chat-log", RichLog)
        log.write(Text(token), shrink=False)

    def _set_status(self, text: str, color: str = "magenta"):
        self.query_one("#status-box", Static).update(
            Text.from_markup(f"[{color}]● {text}[/{color}]")
        )
        self.status = text

    def _set_hint(self, text: str):
        self.query_one("#input-hint", Label).update(text)

    def _set_input_status(self, text: str):
        self.query_one("#input-status", Label).update(text)

    def _bump_count(self):
        self.msg_count += 1
        self.query_one("#stats-box", Static).update(
            f"mensagens\n{self.msg_count}"
        )

    # ── animation ──
    def _start_anim(self):
        self._anim_task = self.set_interval(0.18, self._tick_anim)

    def _tick_anim(self):
        self._anim_frame = (self._anim_frame + 1) % max(len(WAVE_FRAMES), len(PULSE_FRAMES))
        if self.is_rec:
            frame = WAVE_FRAMES[self._anim_frame % len(WAVE_FRAMES)]
            self._set_input_status(f"[red]{frame}[/red]")
        elif self.is_speak:
            frame = PULSE_FRAMES[self._anim_frame % len(PULSE_FRAMES)]
            self._set_input_status(f"[magenta]{frame}[/magenta]")
        else:
            self._set_input_status("")

    # ── TTS callbacks ──
    def _tts_started(self):
        self.is_speak = True
        self._set_status("falando", "magenta")

    def _tts_finished(self):
        self.is_speak = False
        self._set_status("pronta", "green")
        self._set_hint("[ ESPAÇO ] para gravar")

    def _tts_error(self, e: str):
        self.is_speak = False
        self._set_status("pronta", "green")
        self._log_system(f"TTS erro: {e}")

    # ── recording ──
    def action_toggle_record(self):
        if self.is_speak:
            return
        if self.is_rec:
            self._stop_recording()
        else:
            self._start_recording()

    def _start_recording(self):
        self.is_rec = True
        self._stop_rec.clear()
        self._set_status("ouvindo", "red")
        self._set_hint("[ ESPAÇO ] para parar")
        self._record_worker()

    @work(thread=True)
    def _record_worker(self):
        text = self.stt.record(self._stop_rec)
        self.call_from_thread(self._on_transcribed, text)

    def _stop_recording(self):
        self._stop_rec.set()
        self.is_rec = False
        self._set_status("transcrevendo", "yellow")
        self._set_hint("aguarde...")

    def _on_transcribed(self, text: str):
        self.is_rec = False
        if not text:
            self._set_status("pronta", "green")
            self._set_hint("[ ESPAÇO ] para gravar")
            self._log_system("(nada entendido — tente de novo)")
            return
        self._log("user", text)
        self._bump_count()
        self.history.append({"role": "user", "content": text})
        self._ask_llm()

    # ── LLM ──
    @work(thread=True)
    def _ask_llm(self):
        self.call_from_thread(self._set_status, "pensando", "yellow")
        self.call_from_thread(self._set_hint, "Seina pensando...")

        log = self.query_one("#chat-log", RichLog)
        ts  = datetime.now().strftime("%H:%M")
        line_buf = []

        def on_token(token: str):
            line_buf.append(token)

        try:
            reply = stream_ollama(self.history, on_token)
        except Exception as e:
            reply = "tive um probleminha aqui, tenta de novo?"
            self.call_from_thread(self._log_system, f"Ollama erro: {e}")

        # escreve resposta completa no chat
        full = "".join(line_buf)
        prefix = Text.from_markup(f"[dim]{ts}[/dim] [bold magenta]✿ Seina[/bold magenta]  ")
        prefix.append(full)
        self.call_from_thread(log.write, prefix)

        self.history.append({"role": "assistant", "content": reply})
        if len(self.history) > 20:
            self.history = self.history[-20:]
        self._bump_count()

        # TTS com texto completo — mais fluido na 2060
        self.call_from_thread(self._set_status, "sintetizando", "blue")
        self.call_from_thread(self._set_hint, "gerando voz...")
        self._tts_full(reply)

    def _tts_full(self, reply: str):
        """Quebra o texto em parágrafos/frases naturais e enfileira tudo de uma vez."""
        # divide por parágrafo ou por grupo de frases (~300 chars max por chunk)
        # para o XTTS não travar com textos gigantes
        SPLIT = re.compile(r"(?<=[.!?])\s+")
        sentences = SPLIT.split(reply.strip())

        chunks = []
        buf = ""
        for s in sentences:
            s = s.strip()
            if not s:
                continue
            if len(buf) + len(s) < 280:
                buf = (buf + " " + s).strip()
            else:
                if buf:
                    chunks.append(buf)
                buf = s
        if buf:
            chunks.append(buf)

        for chunk in chunks:
            self.tts.say(chunk)

    # ── misc actions ──
    def action_clear_chat(self):
        self.query_one("#chat-log", RichLog).clear()
        self.history = []
        self.msg_count = 0
        self.query_one("#stats-box", Static).update("mensagens\n0")
        self._log_system("conversa limpa.")

    def action_quit(self):
        self.tts.stop()
        self.exit()

# ══════════════════════════════════════════
#  BOOT
# ══════════════════════════════════════════
def check_ollama():
    try:
        with urllib.request.urlopen(
            urllib.request.Request(f"{OLLAMA_URL}/api/tags"), timeout=5
        ) as r:
            data = json.loads(r.read())
        return [m["name"] for m in data.get("models", [])]
    except Exception as e:
        return None

def main():
    # pre-flight check fora do TUI
    p = "\033[95m"; r = "\033[0m"; y = "\033[93m"; g = "\033[92m"; red = "\033[91m"
    print(f"\n{p}  ✿  星奈 Seina — inicializando...{r}\n")

    models = check_ollama()
    if models is None:
        print(f"{red}  ✗ Ollama não encontrado. Rode: ollama serve{r}")
        sys.exit(1)
    print(f"{g}  ✓ Ollama | modelos: {', '.join(models)}{r}")

    print(f"{y}  Carregando Whisper ({WHISPER_MODEL})...{r}")
    stt = STTEngine()
    print(f"{g}  ✓ Whisper pronto{r}")

    print(f"{y}  Carregando XTTS (pode demorar)...{r}")
    tts = TTSEngine()
    tts.load()
    print(f"{g}  ✓ XTTS pronto | speaker: {TTS_SPEAKER}{r}")

    print(f"\n{g}  Tudo pronto! Iniciando TUI...{r}\n")
    time.sleep(0.5)

    app = SeinaApp(tts=tts, stt=stt)
    app.run()

if __name__ == "__main__":
    main()
