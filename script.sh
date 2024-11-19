#!/bin/bash

curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar

while true; do
    if php wp-cli.phar core is-installed --allow-root 2>/dev/null; then
        if [ -d "/var/www/html/wp-content/plugins/redis-cache" ]; then
            echo "Redis Cache plugin is OK."
            break
        else
            php wp-cli.phar plugin install redis-cache --allow-root
            php wp-cli.phar plugin activate redis-cache --allow-root
            php wp-cli.phar redis enable --allow-root
            break
        fi
        break
    else
        echo "WordPress not installed. Retrying in 30 seconds..."
        sleep 30
    fi
done
