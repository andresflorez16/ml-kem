# Ejemplos

La POC del repo exige el híbrido: si el peer no ofrece `X25519MLKEM768`, el handshake falla. En producción se prefiere y se deja un grupo clásico de respaldo, salvo que la política exija post-cuántico.

El cliente Node de `poc/client/client.mjs` imprime el grupo negociado. Los servidores están en `poc/node`, `poc/go` y `poc/spring`.

## Node.js

`ecdhCurve` configura los grupos de TLS 1.3. `auto` ya incluye el híbrido en Node 22.20+, 24.5+ y 26. Una lista clásica lo apaga.

Exigir:

```javascript
import https from "node:https";

https.createServer(
  {
    key,
    cert,
    minVersion: "TLSv1.3",
    ecdhCurve: "X25519MLKEM768",
  },
  handler,
);
```

Preferir: `ecdhCurve: "X25519MLKEM768:X25519"` o no definir la opción.

El grupo se lee en el socket **cliente**. En el servidor, `getEphemeralKeyInfo()` devuelve `null`.

```javascript
socket.on("secureConnect", () => {
  const info = socket.getEphemeralKeyInfo();
  // En Node reciente: { type: "TLSGroup", name: "X25519MLKEM768" }.
  // Node 26.0.0 todavía devuelve {}. Si name viene vacío, confirma con
  // openssl s_client y la línea "Negotiated TLS1.3 group".
});
```

## Go

Desde Go 1.24 el default ya es el híbrido. Exigirlo:

```go
srv := &http.Server{
    TLSConfig: &tls.Config{
        Certificates: []tls.Certificate{cert},
        MinVersion:   tls.VersionTLS13,
        CurvePreferences: []tls.CurveID{tls.X25519MLKEM768},
    },
}
```

Preferir: dejar `CurvePreferences` en nil. No hace falta `crypto/mlkem` en la aplicación.

El grupo queda en `r.TLS.CurveID` (cliente y servidor). `CurveID.String()` devuelve `X25519MLKEM768`.

## Java y Spring Boot

JDK 27 (JEP 527). En un socket JSSE:

```java
SSLParameters params = socket.getSSLParameters();
params.setNamedGroups(new String[] { "X25519MLKEM768" }); // exigir
socket.setSSLParameters(params);
```

Preferir: `"X25519MLKEM768", "x25519"`, o no tocar la lista.

Spring Boot no copia los grupos con nombre a `SslBundles` (issue 46968). No hay propiedad `application.properties` para esto. Hay que fijar la propiedad de JSSE antes de crear el `SSLContext`:

```java
System.setProperty("jdk.tls.namedGroups", "X25519MLKEM768");
```

o arrancar con `-Djdk.tls.namedGroups=X25519MLKEM768`. En JDK 17 o 25 ese nombre no existe y el servidor no llega a negociar el híbrido.

JSSE no expone el grupo negociado en `SSLSession`. La comprobación de la POC la hace el cliente Node. Con `-Djavax.net.debug=ssl:handshake`, el `key_share` del ServerHello muestra `x25519mlkem768`.
