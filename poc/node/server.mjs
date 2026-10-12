import https from "node:https";
import fs from "node:fs";

const port = Number(process.env.PORT ?? 8443);
const certPath = process.env.MLKEM_CERT;
const keyPath = process.env.MLKEM_KEY;
if (!certPath || !keyPath) {
  console.error("defina MLKEM_CERT y MLKEM_KEY");
  process.exit(1);
}

https
  .createServer(
    {
      cert: fs.readFileSync(certPath),
      key: fs.readFileSync(keyPath),
      minVersion: "TLSv1.3",
      ecdhCurve: "X25519MLKEM768",
    },
    (_req, res) => {
      res.writeHead(200, { "content-type": "text/plain" });
      res.end("ok\n");
    },
  )
  .listen(port, "127.0.0.1", () => {
    console.log(`node listening ${port}`);
  });
