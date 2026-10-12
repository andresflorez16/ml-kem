# ML-KEM en tránsito

Este repositorio enseña a proteger el tráfico de red con criptografía post-cuántica y lo demuestra con un cliente y tres servidores. El mecanismo es **ML-KEM** (FIPS 203), el estándar de NIST para acordar una clave de sesión resistente a un futuro ordenador cuántico.

ML-KEM no cifra el contenido del mensaje. Encapsula un secreto compartido durante el handshake de **TLS 1.3**. Los datos siguen cifrados con AES-GCM. El grupo que usa este repo es el híbrido **X25519MLKEM768**: X25519 y ML-KEM-768 aportan cada uno un secreto, y la sesión solo se recupera si se rompen los dos.

## Por qué migrar, y en qué plazo

Un atacante puede grabar hoy tráfico TLS clásico y descifrarlo cuando exista un ordenador cuántico capaz. NIST llama a eso *harvest now, decrypt later*. El certificado del servidor puede seguir siendo ECDSA o RSA durante un tiempo: la firma se comprueba en el momento. El secreto de la sesión, no. Por eso el intercambio de claves en tránsito es la parte que hay que mover primero.

NIST publicó ML-KEM como estándar final el **13 de agosto de 2024** (FIPS 203) y pide usarlo ya. En el plan de transición [NIST IR 8547](https://csrc.nist.gov/pubs/ir/8547/ipd) (borrador público inicial), el intercambio de claves clásico —ECDH, DH y RSA— queda **deprecado después de 2030** y **retirado después de 2035**. Deprecado significa que se puede seguir usando, asumiendo el riesgo. Retirado significa que deja de ser aceptable en los estándares de NIST.

Ese mismo informe advierte que, para la confidencialidad de las comunicaciones, la guía de cada protocolo puede exigir el salto a ML-KEM **antes** de 2035, justo por el riesgo de grabar el tráfico ahora. La página de criptografía post-cuántica de NIST resume el plan así: retirar de sus estándares los algoritmos vulnerables a cuánticos para 2035, y mover antes los sistemas de alto riesgo. El objetivo que NIST cita, el del National Security Memorandum 10, es haber mitigado todo el riesgo cuántico que sea viable **para 2035**.

| Hito | Fecha | Qué implica para el tránsito |
| --- | --- | --- |
| FIPS 203, ML-KEM final | 13 de agosto de 2024 | Ya se puede y se debe desplegar |
| Intercambio de claves clásico deprecado | después de 2030 | Seguir en ECDH/RSA exige aceptar el riesgo |
| Intercambio de claves clásico retirado | después de 2035 | Deja de ser aceptable en los estándares de NIST |

## Cómo está organizado

- [`.cursor/skills/ml-kem-transit/`](.cursor/skills/ml-kem-transit/SKILL.md) es la guía para un agente o un desarrollador, en cualquier lenguaje: qué pila TLS hace falta, cuándo preferir el híbrido y cuándo exigirlo, y cómo comprobar el grupo negociado.
- [`poc/`](poc/) es la prueba. Un cliente Node exige `X25519MLKEM768` y comprueba el grupo contra tres servidores HTTPS: Node (8443), Spring Boot (8444) y Go (8445). Los tres rechazan un handshake que no ofrezca ese grupo. En producción lo habitual es preferirlo y dejar un grupo clásico de respaldo.

## Cómo ejecutar la prueba

Hace falta Node 22.20+ (o 24.5+, o 26), Go 1.24+, JDK 27, Maven y OpenSSL 3.5+. JDK 27 es el primero con el grupo híbrido en JSSE (JEP 527). Si no está en `JAVA_HOME`, el script lo busca en `~/.local/jdks`.

```bash
./poc/check.sh
```

El certificado de localhost se genera en `poc/certs/` y no se versiona. La prueba termina bien cuando las tres líneas dicen `group=X25519MLKEM768`.

## Referencias

- NIST, [FIPS 203, Module-Lattice-Based Key-Encapsulation Mechanism Standard](https://csrc.nist.gov/pubs/fips/203/final), 13 de agosto de 2024. ML-KEM-512, ML-KEM-768 y ML-KEM-1024.
- NIST, [IR 8547, Transition to Post-Quantum Cryptography Standards](https://csrc.nist.gov/pubs/ir/8547/ipd) (borrador público inicial). PDF: [NIST.IR.8547.ipd](https://nvlpubs.nist.gov/nistpubs/ir/2024/NIST.IR.8547.ipd.pdf). Tablas 2 y 4: deprecado después de 2030, retirado después de 2035. Sección 4.1.2: adelantar el intercambio de claves por *harvest now, decrypt later*.
- NIST, [Post-Quantum Cryptography](https://csrc.nist.gov/projects/post-quantum-cryptography). Pide migrar ahora y retirar los algoritmos vulnerables para 2035.
- National Security Memorandum 10, citado en IR 8547: mitigar el riesgo cuántico que sea viable para 2035.
