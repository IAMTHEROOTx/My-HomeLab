# 🔧 Mise en place d’un serveur Ubuntu sans fil (Wi-Fi)

> 🖥️ **Objectif** : Connecter un serveur Ubuntu (22.04+, `noble`) à un réseau Wi-Fi **sans accès initial à Internet**, configurer **SSH** pour le contrôler à distance, et **automatiser la reconnexion au démarrage**.
![Mise en place d’un serveur Uunbtu sans fil avec accès SSH](https://github.com/user-attachments/assets/02a7a473-c8b5-4de7-bb71-089c31e4fecb)

---

## 📜 Sommaire

- [Présentation du projet](#🧾-présentation-du-projet)
- [Pré-requis](#📦-pré-requis)
- [Étapes détaillées](#🔌-étapes-détaillées)
  - [1. Préparation réseau minimale](#1-préparation-réseau-minimale)
  - [2. Connexion Wi-Fi manuelle](#2-connexion-wi-fi-manuelle)
  - [3. SSH (connexion distante)](#3-ssh-connexion-distante)
  - [4. Automatiser la connexion Wi-Fi au démarrage](#4-automatiser-la-connexion-wi-fi-au-démarrage)
- [Commandes utiles](#🧰-commandes-utiles)
- [Fiabilisation](#🛠️-fiabilisation)
- [Annexes : IP statique avec Netplan](#📎-annexes--ip-statique-avec-netplan)
- [Crédits & Contexte](#🧠-crédits--contexte)
- [Illustrations (à ajouter)](#📸-illustrations-à-ajouter)

---

## 🧾 Présentation du projet

Ce projet documente la configuration d’un **serveur Ubuntu sans interface graphique** qui doit se connecter en Wi-Fi **sans accès Internet initial**, pour ensuite être contrôlé à distance via **SSH**.

---

## 📦 Pré-requis

- Ubuntu Server 24.04 (noble) ou supérieur
- Une **clé USB** pour transférer des fichiers `.deb`
- Un **dongle Wi-Fi** compatible avec `iwconfig` / `wpa_supplicant`
- Un second PC (pour transfert, SSH)
- Connexion Internet sur ce second PC (pour télécharger les paquets)

---

## 🔌 Étapes détaillées

### 1. Préparation réseau minimale

Ubuntu Server ne contient pas les outils Wi-Fi par défaut. On commence par les installer via clé USB :

#### ➤ Installer `wireless-tools` :

Sur un autre PC connecté à Internet (Linux ou Windows) :
https://packages.ubuntu.com

Recherchez wireless-tools pour Ubuntu 24.04 "noble".

Téléchargez le fichier .deb depuis un des miroirs proposés.

Transfèrez-le sur votre serveur Ubuntu via clé USB.

Branchez la clé USB sur le serveur, puis monte-la si nécessaire :

```bash
sudo mkdir /mnt/usb
sudo mount /dev/sdX1 /mnt/usb  # remplace sdX1 par le nom réel de ta clé (ex: sdb1)
```

Installez le paquet .deb :

```bash
sudo dpkg -i /mnt/usb/wireless-tools_*.deb
```
➤ Résolution d’erreurs fréquentes :
```bash
Erreur : usb2-2: device descriptor read/8, error -110
```
signale un problème de communication USB, souvent lié à :

- un port USB défectueux
- une clé USB mal insérée ou incompatible
- un manque d'alimentation pour le périphérique
- ou une erreur dans le contrôleur USB du noyau
```bash
unable to enumerate USB device
```
Changez de port USB ou changez de clé USB.
```bash
cannot access archive: No such file or directory
```
👉 Activer manuellement :
```bash
lsblk
sudo mkdir /mnt/usb
sudo mount /dev/sdX1 /mnt/usb   # Remplacez sdX1 par la bonne lettre de votre clé, ex: sdb1
```

Pour vérifier que le fichier est bien la 
```bash
ls /mnt/usb
```

Vous devriez voir:
```bash
wireless-tools_30~pre9-13.1ubuntu3_amd64.deb
```

Si le fichier est bien visible, installe-le avec :

```bash
sudo dpkg -i /mnt/usb/wireless-tools_30~pre9-13.1ubuntu3_amd64.deb
```
Ensuite nous avons besoin de libiw30_30, on suit le meme processus :

```bash
libiw30_30~pre9-13.1ubuntu3_amd64.deb
```
```bash
sudo dpkg -i /mnt/usb/wireless-tools_30~pre9-13.1ubuntu3_amd64.deb
```

2. Connexion Wi-Fi manuelle
Créer le fichier de configuration :

```bash
sudo nano /etc/wpa_supplicant.conf
Contenu :

ctrl_interface=DIR=/run/wpa_supplicant GROUP=netdev
network={
  ssid="NomDuReseauWiFi"
  psk="MotDePasseWiFi"
}
```
Connexion manuelle :

```bash
sudo ip link set wlp0s12f0 up
sudo wpa_supplicant -B -i wlp0s12f0 -c /etc/wpa_supplicant.conf
sudo dhclient wlp0s12f0
```
Vérification :
```bash
ping google.com
```
3. SSH (connexion distante)

Installation :

```bash
sudo apt install openssh-server
sudo systemctl enable ssh
sudo systemctl start ssh
```
Vérifier le statut :

```bash

sudo systemctl status ssh
```
Connexion depuis un autre PC :

```bash

ssh nom_utilisateur@ip_du_serveur
```
4. Automatiser la connexion Wi-Fi au démarrage
```bash
Créer deux services systemd.

/etc/systemd/system/wifi-auto.service

[Unit]
Description=Auto connect to WiFi
After=network.target

[Service]
ExecStart=/sbin/wpa_supplicant -B -i wlp0s12f0 -c /etc/wpa_supplicant.conf

[Install]
WantedBy=multi-user.target
/etc/systemd/system/dhclient-wifi.service
ini

[Unit]
Description=DHCP client for WiFi
After=wifi-auto.service

[Service]
ExecStart=/sbin/dhclient wlp0s12f0

[Install]
WantedBy=multi-user.target
```
Activer au démarrage :

```bash
sudo systemctl enable wifi-auto.service
sudo systemctl enable dhclient-wifi.service
```
🧰 Commandes utiles
```bash
Action	    Commande
Redémarrer	sudo reboot
Éteindre	sudo poweroff
Suspendre	systemctl suspend
Hiberner	systemctl hibernate
Statut du Wi-Fi	iwconfig wlp0s12f0
IP du serveur	ip a show wlp0s12f0
Trafic réseau live	sudo iftop -i wlp0s12f0
```
🛠️ Fiabilisation
```bash
Activer SSH au démarrage :

sudo systemctl enable ssh
```
Configurer le pare-feu :
```bash
sudo ufw allow ssh
sudo ufw enable
```
Éviter les changements d’IP :

Réserver une IP statique dans la box/routeur

Ou configurer une IP fixe via Netplan (voir section suivante)

📎 Annexes : IP statique avec Netplan
Modifier ou créer un fichier Netplan :

```yaml
network:
  version: 2
  renderer: networkd
  wifis:
    wlp0s12f0:
      dhcp4: no
      addresses: [192.168.1.42/24]
      gateway4: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]
      access-points:
        "NomDuReseauWiFi":
          password: "MotDePasseWiFi"
          ```
Appliquer la configuration :

```bash
sudo netplan apply
```
🧠 Crédits & Contexte

Ce guide est la documentation de mon déploiement de Ubuntu Server pour mon Homelab où :

Le serveur n’avait pas d’accès Internet

L'installation s'est faite via clé USB et .deb

Problèmes rencontrés :


Résultat : connexion stable, accès SSH, reconnexion automatique
