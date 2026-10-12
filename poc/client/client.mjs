import https from "node:https";
import fs from "node:fs";
import { spawnSync } from "node:child_process";

const port = Number(process.argv[2]);
const certPath = process.env.MLKEM_CERT;
if (!port || !certPath) {
  console.error("uso: MLKEM_CERT=cert.pem node client.mjs <puerto>");
  process.exit(1);
}

const ca = fs.readFileSync(certPath);

function negotiatedGroup() {
  const result = spawnSync(
    "openssl",
    [
      "s_client",
      "-connect",
      `127.0.0.1:${port}`,
      "-servername",
      "localhost",
      "-groups",
      "X25519MLKEM768",
      "-tls1_3",
      "-CAfile",
      certPath,
    ],
    { input: "", encoding: "utf8", timeout: 5000 },
  );
  const output = `${result.stdout ?? ""}\n${result.stderr ?? ""}`;
  const match = output.match(/Negotiated TLS1\.3 group:\s*(\S+)/);
  return match?.[1] ?? "";
}

const req = https.request(
  {
    host: "127.0.0.1",
    port,
    path: "/echo",
    method: "GET",
    ca,
    servername: "localhost",
    minVersion: "TLSv1.3",
    ecdhCurve: "X25519MLKEM768",
    rejectUnauthorized: true,
  },
  (res) => {
    res.resume();
    res.on("end", () => {
      process.exit(process.exitCode ?? 0);
    });
  },
);

req.on("socket", (socket) => {
  socket.on("secureConnect", () => {
    const info = socket.getEphemeralKeyInfo();
    const fromNode = info?.name ?? "";
    const group = fromNode || negotiatedGroup();
    console.log(`protocol=${socket.getProtocol()} group=${group}`);
    if (group.toLowerCase() !== "x25519mlkem768") {
      process.exitCode = 1;
    }
  });
});

req.on("error", (err) => {
  console.error(err.message);
  process.exit(1);
});

req.end();
