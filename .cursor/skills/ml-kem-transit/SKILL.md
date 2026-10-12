---
name: ml-kem-transit
description: >-
  Integra cifrado post-cuántico en tránsito con el grupo híbrido TLS 1.3
  X25519MLKEM768 (ML-KEM-768 y X25519), en cualquier lenguaje. Use when adding
  post-quantum encryption in transit, ML-KEM, Kyber, hybrid TLS, or
  quantum-safe key exchange, or when the user mentions cifrado post-cuántico,
  ML-KEM o TLS híbrido.
---

# ML-KEM en tránsito

ML-KEM (FIPS 203) encapsula un secreto compartido en el handshake TLS 1.3. No cifra el payload: el registro sigue en AES-GCM o ChaCha20-Poly1305. El grupo por defecto es **X25519MLKEM768** (IANA `0x11EC`): X25519 y ML-KEM-768 aportan los dos secretos y se concatenan.

No implementes ML-KEM, Kyber ni un intercambio propio en la aplicación. Usa el grupo de la pila TLS.

## Procedimiento

1. Identifica la pila TLS del proceso: OpenSSL, BoringSSL, Go `crypto/tls`, JSSE, rustls o Schannel.
2. Comprueba el piso de versión en [reference.md](reference.md). Si la pila no ofrece `X25519MLKEM768`, actualízala o termina TLS en un borde que sí lo ofrezca.
3. Deja TLS 1.3 y el cifrado de registro como están. No uses `MLKEM512` ni ML-KEM puro como default. `SecP384r1MLKEM1024` solo si el despliegue ya usa P-384.
4. Elige la política:
   - **Preferir** (producción): híbrido primero y un grupo clásico de respaldo. Es el default de OpenSSL 3.5+, Go 1.24+ y JDK 27 si nadie ha fijado una lista.
   - **Exigir**: la lista queda solo en `X25519MLKEM768` y el handshake falla si el peer no lo ofrece.
5. Borra listas de grupos solo clásicas. Pisan el híbrido aunque la pila lo traiga por defecto: `ecdhCurve: "X25519:P-256"`, `CurvePreferences` sin el híbrido, `jdk.tls.namedGroups` antiguo.
6. Verifica el grupo negociado. Una conexión TLS correcta no basta: el nombre tiene que ser `X25519MLKEM768`.

## Lenguaje que no está en los ejemplos

1. Localiza la opción de grupos con nombre (named groups / supported groups / curves) de esa pila.
2. Pon `X25519MLKEM768` el primero y envía su key share en el ClientHello.
3. No cambies el cipher suite de registro para "hacerlo post-cuántico".
4. Añade una prueba que lea el grupo negociado y falle si es otro.
5. Si la API no puede nombrarlo, no lo reimplementes: actualiza la pila o termina TLS delante.

Llamadas concretas de Node, Go y Java/Spring: [examples.md](examples.md). Tamaños, firewalls, reanudación y ML-DSA: [reference.md](reference.md). La POC del repo (`poc/`) exige el híbrido a propósito; en producción se prefiere, con respaldo clásico, salvo política contraria.
