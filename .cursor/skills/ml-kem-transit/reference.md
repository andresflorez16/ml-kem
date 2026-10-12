# Referencia: ML-KEM en tránsito

## Qué protege

`X25519MLKEM768` protege el secreto de sesión contra guardar el tráfico hoy y descifrarlo con un ordenador cuántico más adelante. El certificado sigue siendo ECDSA o RSA. ML-DSA (FIPS 204) autentica la identidad y es otra migración: un fallo de firma no se arregla con este grupo.

El secreto híbrido es la concatenación del secreto ML-KEM y del secreto X25519. Hace falta romper los dos para recuperar la sesión.

## Grupos

- `X25519MLKEM768`: default de tránsito. Key share de unos 1216 bytes (1184 de ML-KEM-768 y 32 de X25519).
- `SecP256r1MLKEM768`: mismo KEM con P-256. No está en el default de la mayoría de pilas.
- `SecP384r1MLKEM1024`: solo si ya se exige P-384. Más CPU y unos 1700 bytes de key share.
- `MLKEM512`, `MLKEM768`, `MLKEM1024`: ML-KEM puro, sin la mitad clásica. No son el default de tránsito.

## Pisos de versión

- OpenSSL 3.5+. En 3.5 el default ya ofrece `X25519MLKEM768` y `X25519` como key shares.
- Node.js 22.20+, 24.5+ y 26, porque embeben OpenSSL 3.5+. Node 20 no lo tendrá.
- Go 1.24+. `crypto/tls` lo incluye si `CurvePreferences` está vacío. `GODEBUG=tlsmlkem=0` lo apaga. Desde Go 1.26 también existen `SecP256r1MLKEM768` y `SecP384r1MLKEM1024`, y `ConnectionState.CurveID` nombra el grupo.
- JDK 27 (JEP 527). El default de JSSE pone `X25519MLKEM768` el primero. JDK 25 y anteriores no conocen el grupo.

## Preferir y exigir

Preferir, listas típicas:

- OpenSSL / Node: `X25519MLKEM768:X25519` o `auto` / `DEFAULT`
- Go: `CurvePreferences` vacío
- JSSE: no fijar `jdk.tls.namedGroups`, o `X25519MLKEM768,x25519`

Exigir: un solo nombre, `X25519MLKEM768`. El handshake debe fallar contra un peer clásico.

El orden de la lista importa en OpenSSL y en JSSE. En Go 1.24+ el orden de `CurvePreferences` se ignora: esa lista solo activa o desactiva mecanismos, y la preferencia interna sigue poniendo el híbrido delante.

## Handshake

Hay que mandar el key share híbrido en el ClientHello. Si no va, el servidor responde HelloRetryRequest y se suma un viaje. En OpenSSL el prefijo `*` marca el key share previsto; `?` ofrece el grupo sin key share.

El ClientHello crece unos 1.2 KB y puede salir del primer segmento TCP. Algunos firewalls tiran esa conexión. Si pasa, se puede dejar de predecir el key share híbrido y aceptar el HelloRetryRequest; no se quita el grupo.

La reanudación con ticket de sesión no vuelve a ejecutar ML-KEM. El secreto reanudado sale del handshake anterior. Comprobar el grupo en una conexión nueva, no en una reanudada.

## Qué no hacer

- Cifrar el body con ML-KEM. El KEM no es un AEAD y no sustituye a AES-GCM.
- Copiar una implementación de Kyber en el servicio.
- Dar por hecho el post-cuántico porque TLS conectó: hay que leer el grupo negociado.
- Dejar una guía de hardening que fije solo curvas clásicas.
