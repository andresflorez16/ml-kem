# Contexto para agentes

Este repo integra **cifrado post-cuántico en tránsito** con ML-KEM (FIPS 203). Antes de tocar TLS, lee y sigue [`.cursor/skills/ml-kem-transit/SKILL.md`](.cursor/skills/ml-kem-transit/SKILL.md). Los detalles de grupos, tamaños y plazos de pila están en [`reference.md`](.cursor/skills/ml-kem-transit/reference.md). Las llamadas de Node, Go y Java están en [`examples.md`](.cursor/skills/ml-kem-transit/examples.md).

## Reglas de este dominio

- ML-KEM encapsula el secreto de sesión dentro de TLS 1.3. El registro sigue en AES-GCM o ChaCha20-Poly1305.
- El grupo por defecto es `X25519MLKEM768` (IANA `0x11EC`). No uses `MLKEM512` ni ML-KEM puro como default. `SecP384r1MLKEM1024` solo si el despliegue ya usa P-384.
- No implementes Kyber ni ML-KEM en la aplicación. Si la pila TLS no ofrece el grupo, actualízala o termina TLS en un borde que sí lo ofrezca.
- En producción, **prefiere** el híbrido y deja un grupo clásico de respaldo. La POC **exige** solo `X25519MLKEM768` para que un handshake clásico falle.
- Una conexión TLS correcta no demuestra post-cuántico. La prueba tiene que leer el grupo negociado y ver `X25519MLKEM768`.
- Quitar listas de grupos solo clásicas (`ecdhCurve: "X25519:P-256"`, `CurvePreferences` sin el híbrido, `jdk.tls.namedGroups` antiguo): esas listas apagan el híbrido.
- El certificado puede seguir siendo RSA o ECDSA. ML-DSA es otra migración y no forma parte de este repo.

## Qué hay en el árbol

| Ruta | Rol |
| --- | --- |
| `poc/client/client.mjs` | Cliente Node. Exige el grupo y lo imprime. |
| `poc/node/server.mjs` | Servidor HTTPS en el puerto 8443. |
| `poc/spring/` | Spring Boot 4.1.1 en el puerto 8444. JDK 27. El grupo se fija con `jdk.tls.namedGroups` en `Application.main`, porque Spring Boot no lo expone en `application.properties`. |
| `poc/go/main.go` | Servidor Go en el puerto 8445. `CurvePreferences` con `tls.X25519MLKEM768`. El grupo queda en `ConnectionState.CurveID`. |
| `poc/check.sh` | Genera el certificado, arranca los tres servidores y falla si algún cliente no imprime `X25519MLKEM768`. |

`poc/certs/` y el binario `poc/go/server` no se versionan. Node 26.0.0 devuelve `{}` en `getEphemeralKeyInfo()`; el cliente, si no recibe el nombre, lo lee de `openssl s_client` (`Negotiated TLS1.3 group`).

## Verificar

```bash
./poc/check.sh
```

Requisitos: Node 22.20+ / 24.5+ / 26, Go 1.24+, JDK 27 (JEP 527), Maven, OpenSSL 3.5+. JDK 27 se busca en `JAVA_HOME` y luego en `~/.local/jdks/jdk-27*/Contents/Home`.

## Plazo que cita la documentación

NIST IR 8547 (borrador): intercambio de claves clásico deprecado después de 2030 y retirado después de 2035. Para el tránsito, ese informe pide adelantar la migración por *harvest now, decrypt later*. FIPS 203 está final desde el 13 de agosto de 2024. No inventes otras fechas.
