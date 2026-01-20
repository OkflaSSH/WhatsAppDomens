#!/bin/bash
set -e

echo "=== Создаём пользователя kali ==="
sudo useradd -m -s /bin/bash kali || true
echo 'kali:kali' | sudo chpasswd
sudo usermod -aG sudo kali
sudo chown -R kali:kali /home/kali

echo "=== Делаем резервную копию старого sshd_config ==="
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%F_%T)

echo "=== Записываем новый конфиг SSH ==="
sudo tee /etc/ssh/sshd_config > /dev/null <<'EOF'
# ==========================
# Основные настройки SSH
# ==========================

Port 22
Protocol 2
AddressFamily any
ListenAddress 0.0.0.0
ListenAddress ::

# Разрешаем вход root только по ключам
PermitRootLogin prohibit-password

# Не разрешаем пустые пароли
PermitEmptyPasswords no

# Аутентификация по ключам
PubkeyAuthentication yes
AuthorizedKeysFile     .ssh/authorized_keys

# Используем PAM для паролей
UsePAM yes
ChallengeResponseAuthentication no

# По умолчанию вход по паролю отключён
PasswordAuthentication no

# Не показываем баннер при входе
Banner none

# ==========================
# Таймауты и безопасность
# ==========================
X11Forwarding no
AllowTcpForwarding yes
GatewayPorts yes
ClientAliveInterval 120
ClientAliveCountMax 3
LoginGraceTime 30
PermitUserEnvironment no
AllowAgentForwarding yes

# ==========================
# SFTP подсистема
# ==========================
Subsystem sftp /usr/lib/openssh/sftp-server

# ==========================
# Разрешаем вход по паролю только пользователю kali
# ==========================
Match User kali
    PasswordAuthentication yes
EOF

echo "=== Проверяем конфигурацию SSH ==="
sudo sshd -t

echo "=== Перезапускаем SSH ==="
sudo systemctl restart ssh

echo "=== Проверяем статус службы ==="
sudo systemctl status ssh --no-pager

echo "=== Готово! ==="
echo "Теперь можно подключаться:"
echo "ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no kali@<IP_или_HOST>"
