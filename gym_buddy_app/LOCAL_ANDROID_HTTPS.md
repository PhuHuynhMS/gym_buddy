# Local Android HTTPS

Task 7 uses a `Secure` refresh-token cookie. Real Android devices will only
send that cookie over HTTPS, so local device testing should not use plain
`http://192.168.x.x:5000`.

## Expected URL

Set the Flutter config to an HTTPS URL:

```json
{
  "apiBaseUrl": "https://<your-lan-host>:5000/api/v1"
}
```

The backend certificate must include `<your-lan-host>` in its Subject
Alternative Name. If you use a LAN IP, the SAN must include that IP. If you use
a local DNS name, the SAN must include that DNS name.

## Android Debug Trust

The debug Android manifest points to:

```text
android/app/src/debug/res/xml/network_security_config.xml
```

That file trusts user-installed certificates for debug builds only. Production
builds do not use this debug manifest.

## Setup Outline

1. Create a local development CA and server certificate.

   On Windows, from `gym_buddy_server`:

   ```powershell
   npm run cert:dev -- 192.168.1.111
   ```

   Replace `192.168.1.111` with your current LAN IP or local dev domain. The
   script creates:

   ```text
   certs/gymbuddy-dev-ca.cer
   certs/server.pfx
   ```

   `server.pfx` contains the backend certificate with a SAN for the host you
   passed to `-HostName`.

2. Install `certs/gymbuddy-dev-ca.cer` on the Android device as a CA
   certificate.

3. Configure the backend environment:

   ```powershell
   $env:HOST="0.0.0.0"
   $env:PORT="5000"
   $env:HTTPS_ENABLED="true"
   $env:HTTPS_PFX_PATH="certs/server.pfx"
   $env:HTTPS_PFX_PASSPHRASE="gymbuddy-dev"
   ```

4. Run the backend over HTTPS:

   ```powershell
   cd ../gym_buddy_server
   npm run dev
   ```

   The server should log:

   ```text
   HTTPS server started at https://0.0.0.0:5000
   ```

5. Update `assets/config/app_config.json` to the HTTPS base URL.
6. Rebuild the debug app and test login, app restart, refresh, and logout.

## Backend Env Reference

The backend supports these local HTTPS variables:

```text
HOST=0.0.0.0
PORT=5000
HTTPS_ENABLED=true
HTTPS_PFX_PATH=certs/server.pfx
HTTPS_PFX_PASSPHRASE=gymbuddy-dev
HTTPS_KEY_PATH=certs/server.key
HTTPS_CERT_PATH=certs/server.crt
```

Use either the PFX variables or the PEM key/cert variables. Keep real key/cert
files out of git. `gym_buddy_server/certs/` is ignored except for its
`.gitignore` placeholder.
