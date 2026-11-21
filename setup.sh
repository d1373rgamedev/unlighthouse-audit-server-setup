#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

# 1. System-Pakete, lrzsz & Bibliotheken für Headless Chrome installieren
apt-get update
apt-get install -y curl wget unzip lrzsz ca-certificates fonts-liberation \
  libasound2t64 libatk-bridge2.0-0 libatk1.0-0 libcairo2 libcups2 \
  libdrm2 libgbm1 libnss3 libpango-1.0-0 libxcomposite1 libxdamage1 \
  libxfixes3 libxkbcommon0 libxrandr2

# 2. Aktuelles Node.js LTS über Snap installieren
snap install node --classic
export PATH="/snap/bin:$PATH"

# 3. Unlighthouse & Chrome installieren
mkdir -p /opt/unlighthouse/reports
cd /opt/unlighthouse
npm init -y
npm install -D @unlighthouse/cli puppeteer
npx puppeteer browsers install chrome --install-deps

# 4. Unlighthouse-Konfiguration (inkl. User-Agent, Video-Timeout & Cookie-Banner-Klick)
cat << 'CONFIG_EOF' > /opt/unlighthouse/unlighthouse.config.ts
export default {
  scanner: {
    categories: ['accessibility'],
    throttle: false,
    samples: 1,
    crawler: true,
    userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
  },
  lighthouseOptions: {
    maxWaitForLoad: 15000,
    pauseAfterLoadMs: 500,
  },
  puppeteerClusterOptions: {
    maxConcurrency: 3,
  },
  puppeteerOptions: {
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage'],
  },
  hooks: {
    async 'puppeteer:after-goto'(page) {
      try {
        await new Promise(r => setTimeout(r, 800));
        const clickConsent = async (frame) => {
          return await frame.evaluate(() => {
            const buttons = Array.from(document.querySelectorAll('button, a[role="button"]'));
            const target = buttons.find(el =>
              /alle akzeptieren|zustimmen|einverstanden|akzeptieren|ablehnen|accept|accept all/i.test(el.innerText || '')
            );
            if (target) {
              target.click();
              return true;
            }
            return false;
          });
        };
        if (!(await clickConsent(page))) {
          for (const frame of page.frames()) {
            if (await clickConsent(frame)) break;
          }
        }
      } catch (e) {}
    },
  },
}
CONFIG_EOF

# 5. Globalen Befehl 'run-audit' einrichten (ohne --output-path Bug)
cat << 'AUDIT_EOF' > /usr/local/bin/run-audit
#!/bin/bash
set -e
export PATH="/snap/bin:$PATH"

if [ -z "$1" ]; then
  echo "Verwendung: run-audit <URL> [MAX_ROUTES]"
  echo "Beispiel:   run-audit https://dequeuniversity.com 5"
  exit 1
fi

SITE_URL="$1"
MAX_ROUTES="${2:-15}"
DOMAIN=$(echo "$SITE_URL" | sed -E 's|^https?://||; s|/.*$||; s|[^a-zA-Z0-9.-]|_|g')
OUT_DIR="/opt/unlighthouse/reports/${DOMAIN}"
ARCHIVE="/opt/unlighthouse/reports/${DOMAIN}.tar.gz"
SERVER_IP=$(curl -s -4 ifconfig.me || hostname -I | awk '{print $1}')

cd /opt/unlighthouse
rm -rf .unlighthouse "$OUT_DIR" "$ARCHIVE"

echo "Starte Unlighthouse Accessibility-Scan für ${SITE_URL} (max. ${MAX_ROUTES} Routen)..."
npx unlighthouse-ci \
  --site "$SITE_URL" \
  --config unlighthouse.config.ts \
  --max-routes "$MAX_ROUTES" \
  --build-static

mv /opt/unlighthouse/.unlighthouse "$OUT_DIR"
tar -czf "$ARCHIVE" -C /opt/unlighthouse/reports "${DOMAIN}"

echo ""
echo "=========================================================="
echo "Fertig! Report liegt unter: ${OUT_DIR}"
echo ""
echo "1. Herunterladen auf Windows/Mac/Linux (lokales Terminal):"
echo "   scp root@${SERVER_IP}:${ARCHIVE} ."
echo ""
echo "2. Live ansehen via SSH-Tunnel (lokales Terminal):"
echo "   ssh -L 3000:localhost:3000 root@${SERVER_IP} \"python3 -m http.server 3000 --directory ${OUT_DIR}\""
echo "=========================================================="
AUDIT_EOF

chmod +x /usr/local/bin/run-audit
touch /root/SETUP_FERTIG
echo "=== SETUP ERFOLGREICH ABGESCHLOSSEN ==="
