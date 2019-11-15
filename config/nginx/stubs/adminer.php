<?php

function adminer_object() {
  include_once __DIR__ . '/plugin.php';
  foreach (glob("plugins/*.php") as $filename) {
    include_once "./$filename";
  }

  $hide_db = [
    // 'information_schema',
    // 'performance_schema',
    // 'phpmyadmin',
    // 'mysql',
    // 'sys'
  ];

  $server = [
    'localhost:3306' => [
      'server' => 'localhost:3306'
    ]
  ];

  $plugins = array(
    new AdminerDumpZip,
    new AdminerDatabaseHide($hide_db),
    // new AdminerLoginServers($server),
    new AdminerEditForeign,
    new AdminerForeignSystem,
  );

  class AdminerCustomization extends AdminerPlugin {
    function name() {
      return 'Adminer';
    }
  }
  return new AdminerCustomization($plugins);

  return new AdminerPlugin($plugins);
}

include __DIR__ . '/adminer.php';
