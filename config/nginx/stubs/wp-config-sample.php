<?php
/**
 * The base configuration for WordPress
 */
define( 'DB_NAME',     'database_name_here' );
define( 'DB_USER',     'username_here' );
define( 'DB_PASSWORD', 'password_here' );
define( 'DB_HOST',     '127.0.0.1' );
define( 'DB_CHARSET',  'utf8mb4' );
define( 'DB_COLLATE',  '' );

/**
 * Database table prefix.
 */
$table_prefix = 'web_';

/**
 * WordPress language.
 */
define( 'WPLANG', 'id_ID' );

/**
 * Authentication Unique Keys and Salts.
 */
define( 'AUTH_KEY',         'put your unique phrase here' );
define( 'SECURE_AUTH_KEY',  'put your unique phrase here' );
define( 'LOGGED_IN_KEY',    'put your unique phrase here' );
define( 'NONCE_KEY',        'put your unique phrase here' );
define( 'AUTH_SALT',        'put your unique phrase here' );
define( 'SECURE_AUTH_SALT', 'put your unique phrase here' );
define( 'LOGGED_IN_SALT',   'put your unique phrase here' );
define( 'NONCE_SALT',       'put your unique phrase here' );
define('WP_CACHE_KEY_SALT', NONCE_SALT);

/**
 * For developers: WordPress debugging mode and Multiuser.
 */
define('WP_CACHE',             true);
define('WP_DEBUG',             false);
define('WP_DEBUG_LOG',         true);
define('WP_DEBUG_DISPLAY',     false);
define('WP_AUTO_UPDATE_CORE',  true);
define('WP_POST_REVISIONS',    false);
define('WP_ALLOW_REPAIR',      true);
define('MEDIA_TRASH',          false);
define('IMAGE_EDIT_OVERWRITE', true);
define('DISABLE_NAG_NOTICES',  true);
define('DISABLE_WP_CRON',      false);
define('DISALLOW_FILE_EDIT',   true);
define('FORCE_SSL_ADMIN',      false);
define('FORCE_SSL_LOGIN',      false);
define('AUTOSAVE_INTERVAL',    300);
define('EMPTY_TRASH_DAYS',     0);
define('WP_MAX_MEMORY_LIMIT', '256M');
define('WP_MEMORY_LIMIT',     '128M');
define('FS_METHOD',         'direct');
// define('WPCOM_API_KEY', 'put-your-key-here');

/**
 * SMTP configuration.
 * SES-SMTPUser-Somebody
 */
// define( 'SMTP_HOST',   'email-smtp.us-west-2.amazonaws.com' );
// define( 'SMTP_USER',   'your_email_username' );
// define( 'SMTP_PASS',   'your_email_password' );
// define( 'SMTP_FROM',   'noreply@example.com' );
// define( 'SMTP_NAME',   'e.g Website Name' );
// define( 'SMTP_PORT',   '587' );
// define( 'SMTP_SECURE', 'tls' );
// define( 'SMTP_AUTH',    true );
// define( 'SMTP_DEBUG',   0 );

/**
 * Enable WP Multisite.
 */
// define('WP_DEFAULT_THEME', 'twentytwelve');
// define('WP_ALLOW_MULTISITE',   true);
// define('MULTISITE',            true);
// define('SUBDOMAIN_INSTALL',    true);
// define('DOMAIN_CURRENT_SITE',  'example.com');
// define('NOBLOGREDIRECT',       'example.com');
// define('PATH_CURRENT_SITE',    '/');
// define('SITE_ID_CURRENT_SITE',  1);
// define('BLOG_ID_CURRENT_SITE',  1);
// define('SUNRISE', 'on');

/* That's all, stop editing! Happy publishing. */

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', dirname( __FILE__ ) . '/' );
}

/** Sets up WordPress vars and included files. */
require_once( ABSPATH . 'wp-settings.php' );

/**
 * Force using Jetpack SSO and then disable
 * login by using username and password.
 */
// add_filter( 'jetpack_sso_bypass_login_forward_wpcom', '__return_true' );
// remove_filter( 'authenticate', 'wp_authenticate_email_password', 20 );
// remove_filter( 'authenticate', 'wp_authenticate_username_password', 20);
