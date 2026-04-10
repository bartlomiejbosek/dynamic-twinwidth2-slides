#!/bin/bash

# ==========================================
# Skrypt Piper TTS dla Arch Linux
# Zamienia wszystkie pliki TXT w katalogu skryptu na odpowiadające im MP3
# ==========================================

# Kolory do wyświetlania komunikatów
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Generowanie MP3 ze wszystkich plików TXT ===${NC}\n"

# 1. Sprawdzanie dostępności wymaganych programów w pętli (czystszy kod)
for cmd in piper-tts wget ffmpeg; do
    if ! command -v "$cmd" &> /dev/null; then
        echo -e "${RED}Błąd: Nie znaleziono programu '$cmd'.${NC}"
        if [ "$cmd" = "ffmpeg" ]; then
            echo "Zainstaluj go poleceniem: sudo pacman -S ffmpeg"
        elif [ "$cmd" = "wget" ]; then
            echo "Zainstaluj go poleceniem: sudo pacman -S wget"
        else
            echo "Upewnij się, że pakiet piper-tts z AUR jest zainstalowany."
        fi
        exit 1
    fi
done

# 2. Konfiguracja ścieżek
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
VOICE_DIR="$HOME/piper_voices"
MODEL_FILE="$VOICE_DIR/pl_PL-gosia-medium.onnx"
CONFIG_FILE="$VOICE_DIR/pl_PL-gosia-medium.onnx.json"

MODEL_URL="https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/pl/pl_PL/gosia/medium/pl_PL-gosia-medium.onnx"
CONFIG_URL="https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/pl/pl_PL/gosia/medium/pl_PL-gosia-medium.onnx.json"

# 3. Tworzenie katalogu na modele głosowe
if [ ! -d "$VOICE_DIR" ]; then
    echo -e "${YELLOW}Tworzę katalog na modele głosowe: $VOICE_DIR${NC}"
    mkdir -p "$VOICE_DIR"
fi

# 4. Pobieranie modelu (tylko jeśli go nie ma)
echo -e "\n${YELLOW}Sprawdzanie plików modelu głosu...${NC}"
if [ ! -f "$MODEL_FILE" ]; then
    echo "Pobieram plik modelu (.onnx)..."
    wget -q --show-progress -O "$MODEL_FILE" "$MODEL_URL"
else
    echo "Plik modelu już istnieje, pomijam pobieranie."
fi

# 5. Pobieranie konfiguracji (tylko jeśli jej nie ma)
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Pobieram plik konfiguracyjny (.json)..."
    wget -q --show-progress -O "$CONFIG_FILE" "$CONFIG_URL"
else
    echo "Plik konfiguracyjny już istnieje, pomijam pobieranie."
fi

# 6. Wyszukanie plików wejściowych
shopt -s nullglob
TEXT_FILES=("$SCRIPT_DIR"/*.txt)
shopt -u nullglob

if [ "${#TEXT_FILES[@]}" -eq 0 ]; then
    echo -e "\n${RED}Błąd: Nie znaleziono żadnych plików .txt w katalogu: $SCRIPT_DIR${NC}"
    exit 1
fi

SUCCESS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

# 7. Generowanie audio dla każdego pliku TXT
for TEXT_FILE in "${TEXT_FILES[@]}"; do
    BASENAME="${TEXT_FILE%.txt}"
    WAV_FILE="${BASENAME}.wav"
    MP3_FILE="${BASENAME}.mp3"

    echo -e "\n${YELLOW}Przetwarzanie pliku: $TEXT_FILE${NC}"

    if [ -f "$MP3_FILE" ]; then
        echo -e "${YELLOW}Pomijam, plik MP3 już istnieje: $MP3_FILE${NC}"
        SKIP_COUNT=$((SKIP_COUNT + 1))
        continue
    fi

    if [ ! -s "$TEXT_FILE" ]; then
        echo -e "${RED}Pomijam pusty plik: $TEXT_FILE${NC}"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        continue
    fi

    echo -e "${YELLOW}1/2: Generowanie WAV...${NC}"
    if ! piper-tts --model "$MODEL_FILE" --output_file "$WAV_FILE" < "$TEXT_FILE"; then
        echo -e "${RED}Błąd generowania WAV dla: $TEXT_FILE${NC}"
        rm -f "$WAV_FILE"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        continue
    fi

    if [ ! -f "$WAV_FILE" ]; then
        echo -e "${RED}Błąd: Piper nie utworzył pliku WAV dla: $TEXT_FILE${NC}"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        continue
    fi

    echo -e "${YELLOW}2/2: Konwersja WAV -> MP3...${NC}"
    if ffmpeg -y -i "$WAV_FILE" -b:a 192k "$MP3_FILE" -loglevel error; then
        rm -f "$WAV_FILE"
        echo -e "${GREEN}Sukces: $MP3_FILE${NC}"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo -e "${RED}Błąd konwersji do MP3 dla: $TEXT_FILE${NC}"
        rm -f "$WAV_FILE"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
done

# 8. Podsumowanie
echo -e "\n${GREEN}Gotowe.${NC} Wygenerowano: ${GREEN}$SUCCESS_COUNT${NC}, pominięto: ${YELLOW}$SKIP_COUNT${NC}, błędy: ${RED}$FAIL_COUNT${NC}"

if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 1
fi
