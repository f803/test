#!/bin/bash


if [[ -f "wp-cli.phar" ]]; then
    echo "WP-CLI уже установлен. Скачивание пропущено."
else
    echo "WP-CLI не найден. Начинаем загрузку..."
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    sudo mv wp-cli.phar /usr/local/bin/wp
    chmod +x wp-cli.phar
    chown -R www-data:www-data /var/www/html
    find /var/www/html -type d -exec chmod 755 {} \;
    find /var/www/html -type f -exec chmod 644 {} \;
fi


while true; do
    if su -s /bin/bash www-data -c "wp cli core is-installed" 2>/dev/null; then
        echo "WordPress is installed."

        if su -s /bin/bash www-data -c "wp cli plugin is-active redis-cache" 2>/dev/null && \
           su -s /bin/bash www-data -c "php /var/www/html/wp-cli.phar redis status" 2>/dev/null | grep -q "Status: Connected"; then
            echo "Redis Cache plugin is already installed, active, and enabled."
        else
            if [ ! -d "/var/www/html/wp-content/plugins/redis-cache" ]; then
                echo "Installing Redis Cache plugin..."
                su -s /bin/bash www-data -c "wp cli plugin install redis-cache"
                echo "Activating Redis Cache plugin..."
                su -s /bin/bash www-data -c "wp cli plugin activate redis-cache"
                echo "Enabling Redis Cache..."
                su -s /bin/bash www-data -c "wp cli redis enable"
            fi
        fi
    else
        echo "WordPress not installed. Retrying in 30 seconds..."
        sleep 30
    fi
done

wait
