#!/bin/bash

/usr/local/bin/docker-entrypoint.sh php-fpm &

if [[ -f "wp-cli.phar" ]]; then
    echo "WP-CLI уже установлен. Скачивание пропущено."
else
    echo "WP-CLI не найден. Начинаем загрузку..."
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    break
fi

chown -R www-data:www-data /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;
chown www-data:www-data /var/www/html/wp-cli.phar
chmod 755 /var/www/html/wp-cli.phar

while true; do
    if su -s /bin/bash www-data -c "php /var/www/html/wp-cli.phar core is-installed" 2>/dev/null; then
        echo "WordPress is installed."

        # Установка и активация Redis Cache
        if su -s /bin/bash www-data -c "php /var/www/html/wp-cli.phar plugin is-active redis-cache" 2>/dev/null && \
           su -s /bin/bash www-data -c "php /var/www/html/wp-cli.phar redis status" 2>/dev/null | grep -q "Status: Connected"; then
            echo "Redis Cache plugin is already installed, active, and enabled."
        else
            if [ ! -d "/var/www/html/wp-content/plugins/redis-cache" ]; then
                echo "Installing Redis Cache plugin..."
                su -s /bin/bash www-data -c "php /var/www/html/wp-cli.phar plugin install redis-cache"
            fi

            echo "Activating Redis Cache plugin..."
            su -s /bin/bash www-data -c "php /var/www/html/wp-cli.phar plugin activate redis-cache"

            echo "Enabling Redis Cache..."
            su -s /bin/bash www-data -c "php /var/www/html/wp-cli.phar redis enable"
        fi

        # Установка и настройка OpenID Connect
        if [ ! -d "/var/www/html/wp-content/plugins/openid-connect-generic" ]; then
            echo "Installing OpenID Connect plugin..."
            su -s /bin/bash www-data -c "php /var/www/html/wp-cli.phar plugin install openid-connect-generic"
        fi

        echo "Activating OpenID Connect plugin..."
        su -s /bin/bash www-data -c "php /var/www/html/wp-cli.phar plugin activate openid-connect-generic"

        echo "Setting OpenID Connect plugin configuration..."
        su -s /bin/bash www-data -c "php /var/www/html/wp-cli.phar option update openid_connect_generic_settings \
            'a:26:{s:10:\"login_type\";s:4:\"auto\";s:9:\"client_id\";s:9:\"wordpress\";s:13:\"client_secret\";s:32:\"rZkIDbc2mVzTC2jmAFEPH1rso1d5czZW\";s:5:\"scope\";s:20:\"openid profile email\";s:14:\"endpoint_login\";s:70:\"http://192.168.4.50:8443/realms/wordpress/protocol/openid-connect/auth\";s:17:\"endpoint_userinfo\";s:70:\"http://keycloak:8443/realms/wordpress/protocol/openid-connect/userinfo\";s:14:\"endpoint_token\";s:67:\"http://keycloak:8443/realms/wordpress/protocol/openid-connect/token\";s:20:\"endpoint_end_session\";s:72:\"http://192.168.4.62:8443/realms/wordpress/protocol/openid-connect/logout\";s:10:\"acr_values\";s:0:\"\";s:12:\"identity_key\";s:18:\"preferred_username\";s:12:\"no_sslverify\";s:1:\"1\";s:20:\"http_request_timeout\";s:1:\"5\";s:15:\"enforce_privacy\";s:1:\"0\";s:22:\"alternate_redirect_uri\";s:1:\"0\";s:12:\"nickname_key\";s:18:\"preferred_username\";s:12:\"email_format\";s:7:\"{email}\";s:18:\"displayname_format\";s:0:\"\";s:22:\"identify_with_username\";s:1:\"0\";s:16:\"state_time_limit\";s:3:\"180\";s:20:\"token_refresh_enable\";s:1:\"1\";s:19:\"link_existing_users\";s:1:\"1\";s:24:\"create_if_does_not_exist\";s:1:\"1\";s:18:\"redirect_user_back\";s:1:\"1\";s:18:\"redirect_on_logout\";s:1:\"1\";s:14:\"enable_logging\";s:1:\"0\";s:9:\"log_limit\";s:4:\"1000\";}'"

        echo "Plugins are installed, activated, and configured. Exiting..."
        break
    else
        echo "WordPress not installed. Retrying in 30 seconds..."
        sleep 30
    fi
done

wait

