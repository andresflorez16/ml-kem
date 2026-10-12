#!/usr/bin/env bash
set -euo pipefail
set +m

POC="$(cd "$(dirname "$0")" && pwd)"
CERT_DIR="$POC/certs"
export MLKEM_CERT="$CERT_DIR/cert.pem"
export MLKEM_KEY="$CERT_DIR/key.pem"

mkdir -p "$CERT_DIR"
if [[ ! -f "$MLKEM_CERT" || ! -f "$MLKEM_KEY" ]]; then
  openssl req -x509 -newkey rsa:2048 -nodes \
    -keyout "$MLKEM_KEY" -out "$MLKEM_CERT" -days 365 \
    -subj "/CN=localhost" \
    -addext "subjectAltName=DNS:localhost,IP:127.0.0.1" >/dev/null 2>&1
fi

pids=()
cleanup() {
  for pid in "${pids[@]:-}"; do
    pkill -P "$pid" 2>/dev/null || true
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
  done
}
trap cleanup EXIT

wait_port() {
  local port="$1"
  for _ in $(seq 1 120); do
    if nc -z 127.0.0.1 "$port" 2>/dev/null; then
      return 0
    fi
    sleep 1
  done
  echo "el puerto $port no abrió" >&2
  return 1
}

probe() {
  local name="$1"
  local port="$2"
  echo "== $name :$port =="
  node "$POC/client/client.mjs" "$port"
}

PORT=8443 node "$POC/node/server.mjs" &
pids+=($!)

(
  cd "$POC/go"
  go build -o server .
)
PORT=8445 "$POC/go/server" &
pids+=($!)

java_is_27() {
  [[ -n "${1:-}" && -x "$1/bin/java" ]] && "$1/bin/java" -version 2>&1 | grep -q 'version "27'
}

if ! java_is_27 "${JAVA_HOME:-}"; then
  unset JAVA_HOME
  if /usr/libexec/java_home -v 27 >/dev/null 2>&1; then
    JAVA_HOME="$(/usr/libexec/java_home -v 27)"
  fi
fi
if ! java_is_27 "${JAVA_HOME:-}"; then
  for candidate in "$HOME"/.local/jdks/jdk-27*/Contents/Home; do
    if java_is_27 "$candidate"; then
      JAVA_HOME="$candidate"
      break
    fi
  done
fi
if ! java_is_27 "${JAVA_HOME:-}"; then
  echo "hace falta JDK 27 (JEP 527) en JAVA_HOME o en ~/.local/jdks" >&2
  exit 1
fi
export JAVA_HOME
echo "JAVA_HOME=$JAVA_HOME"
"$JAVA_HOME/bin/java" -version

(
  cd "$POC/spring"
  PORT=8444 mvn -q spring-boot:run
) &
pids+=($!)

wait_port 8443
wait_port 8445
wait_port 8444

probe node 8443
probe go 8445
probe spring 8444
