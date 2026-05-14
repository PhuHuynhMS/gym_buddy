import fs from "node:fs";
import http from "node:http";
import https from "node:https";
import app from "./src/app";
import connectDB from "./src/config/db";

connectDB();

const PORT = Number(process.env.PORT || 5000);
const HOST = process.env.HOST || "0.0.0.0";
const HTTPS_ENABLED = process.env.HTTPS_ENABLED === "true";

const startServer = () => {
  if (!HTTPS_ENABLED) {
    http.createServer(app).listen(PORT, HOST, () => {
      console.log(`HTTP server started at http://${HOST}:${PORT}`);
    });
    return;
  }

  const keyPath = process.env.HTTPS_KEY_PATH;
  const certPath = process.env.HTTPS_CERT_PATH;
  const pfxPath = process.env.HTTPS_PFX_PATH;
  const pfxPassphrase = process.env.HTTPS_PFX_PASSPHRASE;

  if (pfxPath) {
    https
      .createServer(
        {
          pfx: fs.readFileSync(pfxPath),
          passphrase: pfxPassphrase,
        },
        app,
      )
      .listen(PORT, HOST, () => {
        console.log(`HTTPS server started at https://${HOST}:${PORT}`);
      });
    return;
  }

  if (!keyPath || !certPath) {
    throw new Error(
      "HTTPS_ENABLED=true requires either HTTPS_PFX_PATH or HTTPS_KEY_PATH and HTTPS_CERT_PATH.",
    );
  }

  const serverOptions = {
    key: fs.readFileSync(keyPath),
    cert: fs.readFileSync(certPath),
  };

  https.createServer(serverOptions, app).listen(PORT, HOST, () => {
    console.log(`HTTPS server started at https://${HOST}:${PORT}`);
  });
};

startServer();
