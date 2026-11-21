# unlighthouse-audit-server-setup
#### Server Setup für Accessibility Testing mit Unlighthouse

#### Nachfolgend am Beispiel mit Hetzner Cloud Server

#### Ablauf:

- In Hetzner Console einloggen:  
https://console.hetzner.com/

- Im Abschnitt Server:
  - Server hinzufügen auswählen  
  - Servertyp auswählen, z.B. CPX32 4xAMD 8GB   
  - Mit diesem Servertyp wurde diese Konfiguration ursprünglich erstellt

- Im Abschnitt "Cloud Config":  
  - die Cloud Config yaml in das entsprechende Feld kopieren (inkl. ab Zeile #cloud-config)  
  - oder den Verweis auf das setup.sh in diesem Repo:
```
#cloud-config
runcmd:
  - curl -fsSL https://raw.githubusercontent.com/d1373rgamedev/unlighthouse-audit-server-setup/refs/heads/main/setup.sh -o /root/setup.sh && chmod +x /root/setup.sh && /root/setup.sh
```

- bei Erstellung werden die Zugangsdaten per Mail zugesendet. (bei Verwendung Hetzner Cloud Server)

- Server Console öffnen und root passwort in Server-Console ändern. (bei Verwendung Hetzner Cloud Server)

- mit SSH auf Server verbinden
  - z.B. in Windows CMD  
```
ssh root@<DEINE-SERVER-IP> 
```

- Status abfragen, ob Cloud Config Script schon fertig ist:
```
cloud-init status
```

- Beliebige Website scannen:
  - z.B.
```
run-audit https://dequeuniversity.com 10

In diesem Beispiel: 10 ist die maximale Anzahl an Unterseiten (maxRoutes), die Unlighthouse bei diesem Durchlauf prüft.  
Eine gute Seite für Demo-Zwecke ist: run-audit https://dequeuniversity.com 5
```


- Report herunterladen
  - z.B. in Windows CMD
```
scp root@<DEINE-SERVER-IP>:/opt/unlighthouse/reports/rzfz.ai.tar.gz .
```
nach dem Download wird der Server nicht mehr benötigt und kann gelöscht werden.

- Webserver starten mit Report:
  - z.B. in Windows CMD
```
python -m http.server 3000 --directory dequeuniversity.com
```

Browser öffnen und Report aufrufen:
```
http://localhost:3000
```
