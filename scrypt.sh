#!/bin/bash
set -e

KALI_USER="kali"
KALI_PASS="kali"
SSHD_CONFIG="/etc/ssh/sshd_config"
SSHD_SNIPPET="/etc/ssh/sshd_config.d/99-kali-password.conf"

echo "=== [1/6] Проверка прав ==="
if [[ $EUID -ne 0 ]]; then
  echo "Запусти скрипт от root (sudo)"
  exit 1
fi

echo "=== [2/6] Создание пользователя kali ==="
if ! id "$KALI_USER" &>/dev/null; then
  useradd -m -s /bin/bash "$KALI_USER"
  echo "$KALI_USER:$KALI_PASS" | chpasswd
  usermod -aG sudo "$KALI_USER"
else
  echo "Пользователь kali уже существует"
fi

echo "=== [3/6] Настройка домашней директории ==="
mkdir -p /home/kali
chown -R kali:kali /home/kali
chmod 700 /home/kali

echo "=== [4/6] Настройка SSH (без перезаписи конфига) ==="

# Проверяем поддержку sshd_config.d
if grep -q "^Include /etc/ssh/sshd_config.d/\*.conf" "$SSHD_CONFIG"; then
  echo "Используем sshd_config.d"
else
  echo "Include /etc/ssh/sshd_config.d/*.conf" >> "$SSHD_CONFIG"
fi

mkdir -p /etc/ssh/sshd_config.d

cat > "$SSHD_SNIPPET" <<'EOF'
# Разрешаем вход по паролю ТОЛЬКО пользователю kali
Match User kali
    PasswordAuthentication yes
EOF

chmod 600 "$SSHD_SNIPPET"

echo "=== [5/6] Проверка конфигурации SSH ==="
sshd -t

echo "=== [6/6] Применение настроек (reload) ==="
systemctl reload ssh

echo "=== ГОТОВО ==="
echo
echo "Подключение по паролю:"
echo "ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no kali@<IP>"
