#!/bin/bash

/usr/local/bin/docker-entrypoint.sh php-fpm &

# Заменяем пользователя на f803 и проверяем, установлен ли WP-CLI
if [[ -f "wp-cli.phar" ]]; then
    echo "WP-CLI уже установлен. Скачивание пропущено."
else
    echo "WP-CLI не найден. Начинаем загрузку..."
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    # Убираем break, так как продолжим выполнение с новым пользователем
fi

# Изменяем владельца на f803
chown -R f803:f803 /var/www/html

# Устанавливаем права на директории и файлы, даем доступ всем пользователям
find /var/www/html -type d -exec chmod 777 {} \;
find /var/www/html -type f -exec chmod 666 {} \;
chown f803:f803 /var/www/html/wp-cli.phar
chmod 775 /var/www/html/wp-cli.phar

# Убираем лишнюю команду, так как правами уже управляем через chmod 777 и chmod 666
# find /var/www/html -type d -exec chmod g+s {} \;   # Убрали команду, так как не нужно для общего доступа

# Переходим к выполнению WP-CLI команд от имени пользователя f803
while true; do
    if su -s /bin/bash f803 -c "php /var/www/html/wp-cli.phar core is-installed" 2>/dev/null; then
        echo "WordPress is installed."

        if su -s /bin/bash f803 -c "php /var/www/html/wp-cli.phar plugin is-active redis-cache" 2>/dev/null && \
           su -s /bin/bash f803 -c "php /var/www/html/wp-cli.phar redis status" 2>/dev/null | grep -q "Status: Connected"; then
            echo "Redis Cache plugin is already installed, active, and enabled. Exiting..."
            break
        fi

        if [ ! -d "/var/www/html/wp-content/plugins/redis-cache" ]; then
            echo "Installing Redis Cache plugin..."
            su -s /bin/bash f803 -c "php /var/www/html/wp-cli.phar plugin install redis-cache"
        fi

        echo "Activating Redis Cache plugin..."
        su -s /bin/bash f803 -c "php /var/www/html/wp-cli.phar plugin activate redis-cache"

        echo "Enabling Redis Cache..."
        su -s /bin/bash f803 -c "php /var/www/html/wp-cli.phar redis enable"

        echo "Redis Cache plugin has been installed, activated, and enabled. Exiting..."
        break
    else
        echo "WordPress not installed. Retrying in 30 seconds..."
        sleep 30
    fi
done

wait
