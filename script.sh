#!/bin/bash

/usr/local/bin/docker-entrypoint.sh php-fpm &

if [[ -f "wp-cli.phar" ]]; then
    echo "WP-CLI уже установлен. Скачивание пропущено."
    break
else
    echo "WP-CLI не найден. Начинаем загрузку..."
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    if [[ $? -eq 0 ]]; then
        echo "wp-cli.phar успешно загружен."
	break
    else
        echo "Ошибка при загрузке wp-cli.phar. Проверьте соединение или URL."
    fi
fi



while true; do
    if php wp-cli.phar core is-installed --allow-root 2>/dev/null; then
        if php wp-cli.phar plugin is-active redis-cache --allow-root 2>/dev/null && php wp-cli.phar redis status --allow-root 2>/dev/null | grep -q "Status: Connected"; then
            echo "Redis Cache plugin is already installed, active, and enabled. Exiting..."
            break
        fi

        if [ ! -d "/var/www/html/wp-content/plugins/redis-cache" ]; then
            echo "Installing Redis Cache plugin..."
            php wp-cli.phar plugin install redis-cache --allow-root
        fi

        echo "Activating Redis Cache plugin..."
        php wp-cli.phar plugin activate redis-cache --allow-root

        echo "Enabling Redis Cache..."
        php wp-cli.phar redis enable --allow-root

        echo "Redis Cache plugin has been installed, activated, and enabled. Exiting..."
        break
    else
        echo "WordPress not installed. Retrying in 30 seconds..."
        sleep 30
    fi
done

wait