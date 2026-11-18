# Qwen locale su CPU

Chat da terminale con tre modelli Qwen, tutti quantizzati Q4_K_M.
I modelli sono gia addestrati: qui si esegue soltanto inferenza, tramite
llama-cpp-python. Non servono GPU, PyTorch, chiavi API o servizi cloud per la chat.

## Modelli disponibili

| Valore di `--model` | Modello | File GGUF |
|---|---|---:|
| `qwen2.5-coder-1.5b` | Qwen2.5-Coder-1.5B-Instruct (predefinito) | 1,12 GB |
| `qwen2.5-coder-7b` | Qwen2.5-Coder-7B-Instruct | 4,68 GB |
| `qwen3-4b` | Qwen3-4B-Instruct-2507, senza thinking | 2,50 GB |

Le dimensioni sono decimali e non rappresentano tutta la RAM necessaria.
Si carica un solo modello per processo; per cambiarlo, esci e riavvia con
un altro valore di `--model`. Chiudi la chat precedente prima di avviarne un'altra.
I tre file restano separati nella cartella `models/`.

## Avvio

Dal terminale PowerShell, nella radice MSThesis:

```powershell
.\copro\qwen\.venv\Scripts\python.exe .\copro\qwen\chat.py
```

Per selezionare esplicitamente un modello:

```powershell
.\copro\qwen\.venv\Scripts\python.exe .\copro\qwen\chat.py --model qwen2.5-coder-1.5b
.\copro\qwen\.venv\Scripts\python.exe .\copro\qwen\chat.py --model qwen2.5-coder-7b
.\copro\qwen\.venv\Scripts\python.exe .\copro\qwen\chat.py --model qwen3-4b
```

Oppure, dopo `cd copro/qwen`:

```powershell
.\.venv\Scripts\python.exe .\chat.py
```

- Scrivi una domanda e premi Invio: la risposta viene mostrata progressivamente.
- `/multi`: inserisci o incolla testo su piu righe, terminando con `/end` su una riga separata.
- `/reset`: cancella la cronologia della sessione.
- `/exit` oppure `/quit`: esci. Anche Ctrl+C termina il programma.
- `/help`: mostra i comandi.

La cronologia rimane solo in RAM, non viene salvata e non modifica i pesi.
Quando manca spazio nel contesto, vengono eliminate le coppie domanda/risposta
meno recenti, preservando le istruzioni di sistema e la richiesta attuale.
Una singola richiesta troppo lunga viene rifiutata, senza troncarla silenziosamente.
Il codice generato non viene eseguito automaticamente e va verificato.

## Configurazione

Impostazioni iniziali conservative: CPU obbligatoria (`n_gpu_layers=0` e
`offload_kqv=False`), 4 thread, 2048 token di contesto, massimo 256 token per
risposta, batch di 128 token e caricamento dei pesi tramite memory mapping.
Contesto significa istruzioni, cronologia, richiesta e spazio per la risposta.
Queste impostazioni valgono per tutti e tre i modelli. Per i nuovi modelli parti
da 2048 token di contesto; aumentarlo richiede altra RAM, soprattutto su Qwen3.

```powershell
.\copro\qwen\.venv\Scripts\python.exe .\copro\qwen\chat.py --context 1024 --max-tokens 128 --threads 4
.\copro\qwen\.venv\Scripts\python.exe .\copro\qwen\chat.py --prompt "Scrivi una funzione C che somma due interi."
.\copro\qwen\.venv\Scripts\python.exe .\copro\qwen\chat.py --system "Sei un assistente SystemVerilog. Rispondi in italiano."
.\copro\qwen\.venv\Scripts\python.exe .\copro\qwen\chat.py --model qwen3-4b --context 4096 --max-tokens 1024
```

Il consumo di RAM totale e' superiore alla dimensione del file per contesto,
runtime e sistema operativo. Chiudi applicazioni
pesanti se il sistema inizia a usare intensamente il file di paging.

## Riproduzione dell'ambiente

Richiede Python 3.11 o successivo; verificato con Python 3.13 su Windows x64.
Questi passaggi sono gia stati eseguiti in questa cartella. Per ricrearla, dalla
radice del repository e con un Python compatibile disponibile:

```powershell
python -m venv copro/qwen/.venv
.\copro\qwen\.venv\Scripts\python.exe -m pip install -r copro/qwen/requirements.txt
.\copro\qwen\.venv\Scripts\python.exe copro/qwen/chat.py --download-only
.\copro\qwen\.venv\Scripts\python.exe copro/qwen/chat.py --model qwen2.5-coder-7b --download-only
.\copro\qwen\.venv\Scripts\python.exe copro/qwen/chat.py --model qwen3-4b --download-only
```

[requirements.txt](requirements.txt) usa i wheel CPU precompilati del progetto
llama-cpp-python. Non compila codice C++ e non installa pacchetti CUDA.
L'ambiente virtuale, il modello e le cache sono esclusi da Git.

Il primo avvio scarica automaticamente soltanto il modello selezionato se assente. Per il download
serve Internet; gli avvii successivi con il file presente funzionano offline.
Ogni download usa una revisione fissata e verifica il proprio SHA-256.
`--download-only` permette anche di ricontrollare un file gia scaricato.
Le configurazioni complete sono in `MODELS` in [chat.py](chat.py):

```text
Repository: Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF
Revisione: f86cb2c1fa58255f8052cc32aeede1b7482d4361
File: models/qwen2.5-coder-1.5b-instruct-q4_k_m.gguf
SHA256: cc324af070c2ecbfd324a30884d2f951a7ff756aba85cb811a6ec436933bb046

Repository: Qwen/Qwen2.5-Coder-7B-Instruct-GGUF
Revisione: 13fb94bfda8c8cf22497dc57b78f391a9acb426a
File: models/qwen2.5-coder-7b-instruct-q4_k_m.gguf
SHA256: 509287f78cb4d4cf6b3843734733b914b2c158e43e22a7f4bf5e963800894d3c

Repository: unsloth/Qwen3-4B-Instruct-2507-GGUF
Revisione: a06e946bb6b655725eafa393f4a9745d460374c9
File: models/Qwen3-4B-Instruct-2507-Q4_K_M.gguf
SHA256: 3605803b982cb64aead44f6c1b2ae36e3acdb41d8e46c8a94c6533bc4c67e597
```

## Verifica

Test della gestione della chat, senza caricare il modello:

```powershell
.\copro\qwen\.venv\Scripts\python.exe -m unittest discover -s copro/qwen -p test_chat.py -v
```

Il test con `--prompt` esegue invece una vera generazione su CPU. I test non
certificano la correttezza dei programmi generati o la competenza SystemVerilog.

## Riferimenti

- [Modello e quick start ufficiale Qwen](https://huggingface.co/Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF), pesi con licenza Apache-2.0.
- [Qwen2.5-Coder-7B GGUF ufficiale](https://huggingface.co/Qwen/Qwen2.5-Coder-7B-Instruct-GGUF), Apache-2.0.
- [Qwen3-4B-Instruct-2507 originale](https://huggingface.co/Qwen/Qwen3-4B-Instruct-2507) e [conversione GGUF di Unsloth](https://huggingface.co/unsloth/Qwen3-4B-Instruct-2507-GGUF), Apache-2.0.
- [llama-cpp-python](https://github.com/abetlen/llama-cpp-python), binding Python del motore llama.cpp.
- [Script di chat](chat.py) e [test](test_chat.py).