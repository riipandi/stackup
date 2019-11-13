--
-- Pure-FTPd Schemas
--

DROP TABLE IF EXISTS ftp_users;
CREATE TABLE ftp_users (
    id int(11) unsigned NOT NULL auto_increment,
    User varchar(16) NOT NULL,
    status enum('0','1') NOT NULL default '0',
    Password varchar(64) NOT NULL,
    Uid varchar(11) NOT NULL default '2001',
    Gid varchar(11) NOT NULL default '2001',
    Dir varchar(200) NOT NULL default '/var/www/public_ftp',
    ULBandwidth smallint(5) NOT NULL default '0',
    DLBandwidth smallint(5) NOT NULL default '0',
    comment tinytext,
    ipaccess varchar(15) NOT NULL default '*',
    QuotaSize smallint(5) NOT NULL default '0',
    QuotaFiles int(11) NOT NULL default 0,
    PRIMARY KEY (id),
    UNIQUE KEY User (User)
) ENGINE=MyISAM;
