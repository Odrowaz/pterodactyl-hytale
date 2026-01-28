import * as fs from 'fs'
import { createWriteStream } from "node:fs";
import { exit } from 'node:process';
import { pipeline } from "node:stream/promises";

let token_data;
let last_downloaded_version;

if (fs.existsSync('.hytale-downloader-credentials.json')) {
  token_data = JSON.parse(fs.readFileSync('.hytale-downloader-credentials.json'));
}

if (!token_data) {
  const oauth_request = await fetch("https://oauth.accounts.hytale.com/oauth2/device/auth", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      client_id: "hytale-server", scope: "openid offline auth:server"
    }).toString(),
  });

  const oauth_request_data = await oauth_request.json();

  console.info("Login link: " + oauth_request_data.verification_uri_complete)

  const login_promise = await new Promise(async (resolve, reject) => {
    const handle = setInterval(
      async () => {
        const oauth_token = await fetch("https://oauth.accounts.hytale.com/oauth2/token", {
          method: "POST",
          headers: { "Content-Type": "application/x-www-form-urlencoded" },
          body: new URLSearchParams({
            client_id: "hytale-server", grant_type: "urn:ietf:params:oauth:grant-type:device_code", device_code: oauth_request_data.device_code
          }).toString(),
        });

        const oauth_token_data = await oauth_token.json();

        if (oauth_token_data.access_token) {
          clearInterval(handle);
          resolve(oauth_token_data);
        }
      }, 5000
    );
  });

  token_data = login_promise;
  fs.writeFileSync('.hytale-downloader-credentials.json', JSON.stringify(token_data));
}

const check = await fetch("https://account-data.hytale.com/my-account/get-profiles", {
  method: "GET",
  headers: { "Authorization": "Bearer " + token_data.access_token },
});

if (!check.ok) {
  console.info('token expired!, trying to renew');
  const oauth_request = await fetch("https://oauth.accounts.hytale.com/oauth2/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      client_id: "hytale-server", grant_type: "refresh_token", refresh_token: token_data.refresh_token
    }).toString(),
  });

  if (!oauth_request.ok) {
    if (fs.existsSync('.hytale-downloader-credentials.json')) {
      fs.rmSync('.hytale-downloader-credentials.json');
    }
    console.error('Login flow failed, launch again!');
    exit(1);
  }

  const oauth_request_data = await oauth_request.json();
  token_data = oauth_request_data;
  fs.writeFileSync('.hytale-downloader-credentials.json', JSON.stringify(token_data));
}

const game_versions_url = await fetch("https://account-data.hytale.com/game-assets/version/release.json", {
  method: "GET",
  headers: { "Authorization": "Bearer " + token_data.access_token },
});

const game_versions_url_data = await game_versions_url.json();

const game_versions = await fetch(game_versions_url_data.url, {
  method: "GET"
});

const game_versions_data = await game_versions.json();

if (fs.existsSync('.last-downloaded')) {
  last_downloaded_version = fs.readFileSync('.last-downloaded', { encoding: 'utf-8' });
}

if (game_versions_data.version !== last_downloaded_version) {
  const game_download_url = await fetch("https://account-data.hytale.com/game-assets/" + game_versions_data.download_url, {
    method: "GET",
    headers: { "Authorization": "Bearer " + token_data.access_token },
  });

  const game_download_url_data = await game_download_url.json();

  const game_download = await fetch(game_download_url_data.url, {
    method: "GET"
  });
  console.info(`Downloading version ${game_versions_data.version}...`);
  await pipeline(game_download.body, createWriteStream(`${game_versions_data.version}.zip`));
  console.info(`Done!`);
  fs.writeFileSync('.last-downloaded', game_versions_data.version);
  fs.writeFileSync('.hytale-downloader-credentials.json', JSON.stringify(token_data));
} else {
  console.info('Nothing to download');
}
