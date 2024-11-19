#!/bin/bash

while true; do
    if php wp-cli.phar core is-installed --allow-root 2>/dev/null; then
        # WP is installed. Let's do some things we should only do in a confirmed WP environment.
        curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
        php wp-cli.phar plugin install redis-cache --allow-root
        php wp-cli.phar plugin activate redis-cache --allow-root
        php wp-cli.phar redis enable --allow-root
        break
    else
        # WP is not installed. Wait and try again.
        echo "WordPress not installed. Retrying in 30 seconds..."
        sleep 30
    fi
done
