SET FOREIGN_KEY_CHECKS=0;

--
-- PowerDNS Schemas
--

DROP TABLE IF EXISTS domains;
CREATE TABLE domains (
  id                    INT AUTO_INCREMENT,
  name                  VARCHAR(255) NOT NULL,
  master                VARCHAR(128) DEFAULT NULL,
  last_check            INT DEFAULT NULL,
  type                  VARCHAR(6) NOT NULL,
  notified_serial       INT UNSIGNED DEFAULT NULL,
  account               VARCHAR(40) CHARACTER SET 'utf8' DEFAULT NULL,
  PRIMARY KEY (id)
) Engine=InnoDB;

CREATE UNIQUE INDEX name_index ON domains(name);

DROP TABLE IF EXISTS recordtype;
CREATE TABLE recordtype (
  name varchar(10) NOT NULL,
  description text,
  enable boolean DEFAULT false
) ENGINE=InnoDB;

INSERT INTO `recordtype` (name, enable, description) VALUES
('A',       true, 'The A record contains an IP address'),
('AAAA',    true, 'The AAAA record contains an IPv6 address'),
('AFSDB',   false, 'A specialised rerecordtypeord type for the Andrew Filesystem'),
('ALIAS',   true, 'The ALIAS pseudorecordtyperecord type is supported to provide CNAME-like mechanisms on a zone apex'),
('CAA',     false, 'The Certificatiorecordtype Authority Authorization record, specified in RFC 6844, is used to specify Certificate Authorities that may issue certificates for a domain'),
('CERT',    false, 'Specialised recorecordtyped type for storing certificates, defined in RFC 2538'),
('CDNSKEY', false, 'The CDNSKEY (Chirecordtyped DNSKEY) type is supported'),
('CDS',     false, 'The CDS (Child Drecordtype) type is supported'),
('CNAME',   true, 'The CNAME recordrecordtypespecifies the canonical name of a record'),
('DNSKEY',  true, 'The DNSKEY DNSSErecordtype record type is fully supported, as described in RFC 4034'),
('DNAME',   false, 'The DNAME recordrecordtype as specified in RFC 6672 is supported'),
('DS',      true, 'The DS DNSSEC rerecordtypeord type is fully supported, as described in RFC 4034'),
('HINFO',   false, 'Hardware Info record, used to specify CPU and operating system'),
('KEY',     false, 'The KEY record is fully supported. For its syntax, see RFC 2535'),
('LOC',     false, 'The LOC record is fully supported. For its syntax, see RFC 1876'),
('MX',      true, 'The MX record specifies a mail exchanger host for a domain'),
('NAPTR',   false, 'Naming Authority Pointer, RFC 2915'),
('NS',      true, 'Nameserver record. Specifies nameservers for a domain'),
('NSEC',    false, 'The NSEC, NSEC3 and NSEC3PARAM DNSSEC record type are fully supported, as described in RFC 4034'),
('NSEC3',   false, 'The NSEC, NSEC3 and NSEC3PARAM DNSSEC record type are fully supported, as described in RFC 4034'),
('NSEC3PARAM', false, 'The NSEC, NSEC3 and NSEC3PARAM DNSSEC record type are fully supported, as described in RFC 4034'),
('OPENPGPKEY', false, 'The OPENPGPKEY records, specified in RFC 7929, are used to bind OpenPGP certificates to email addresses'),
('PTR',     true, 'Reverse pointer, used to specify the host name belonging to an IP or IPv6 address'),
('RP',      false, 'Responsible Person record, as described in RFC 1183'),
('RRSIG',   true, 'The RRSIG DNSSEC record type is fully supported, as described in RFC 4034'),
('SOA',     true, 'The Start of Authority record is one of the most complex available'),
('SPF',     true, 'SPF records can be used to store Sender Policy Framework details (RFC 4408)'),
('SSHFP',   false, 'The SSHFP record type, used for storing Secure Shell (SSH) fingerprints, is fully supported'),
('SRV',     true, 'SRV records can be used to encode the location and port of services on a domain name'),
('TKEY',    true, 'The TKEY (RFC 2930) and TSIG records (RFC 2845), used for key-exchange and authenticated AXFRs'),
('TSIG',    true, 'The TKEY (RFC 2930) and TSIG records (RFC 2845), used for key-exchange and authenticated AXFRs'),
('TLSA',    false, 'Since 3.0. The TLSA records, specified in RFC 6698, are used to bind SSL/TLS certificate to named hosts and ports'),
('SMIMEA',  false, 'Since 4.1. The SMIMEA record type, specified in RFC 8162, is used to bind S/MIME certificates to domains'),
('TXT',     true, 'The TXT field can be used to attach textual data to a domain. Text is stored plainly, PowerDNS understands content not enclosed in quotes'),
('URI',     true, 'The URI record, specified in RFC 7553, is used to publish mappings from hostnames to URIs');

ALTER TABLE `recordtype` ADD PRIMARY KEY (`name`), ADD UNIQUE KEY `name_index` (`name`);

DROP TABLE IF EXISTS records;
CREATE TABLE records (
  id                    BIGINT AUTO_INCREMENT,
  domain_id             INT DEFAULT NULL,
  name                  VARCHAR(255) DEFAULT NULL,
  type                  VARCHAR(10) NOT NULL,
  content               VARCHAR(64000) DEFAULT NULL,
  ttl                   INT DEFAULT 3600,
  prio                  INT DEFAULT NULL,
  change_date           INT DEFAULT NULL,
  disabled              TINYINT(1) DEFAULT 0,
  ordername             VARCHAR(255) BINARY DEFAULT NULL,
  auth                  TINYINT(1) DEFAULT 1,
  PRIMARY KEY (id)
) Engine=InnoDB;

CREATE INDEX nametype_index ON records(name,type);
CREATE INDEX domain_id ON records(domain_id);
CREATE INDEX ordername ON records (ordername);
ALTER TABLE records ADD CONSTRAINT `records_ibfk_2` FOREIGN KEY (`type`) REFERENCES `recordtype` (`name`) ON DELETE CASCADE;

DROP TABLE IF EXISTS supermasters;
CREATE TABLE supermasters (
  ip                    VARCHAR(64) NOT NULL,
  nameserver            VARCHAR(255) NOT NULL,
  account               VARCHAR(40) CHARACTER SET 'utf8' NOT NULL,
  PRIMARY KEY (ip, nameserver)
) Engine=InnoDB;

DROP TABLE IF EXISTS comments;
CREATE TABLE comments (
  id                    INT AUTO_INCREMENT,
  domain_id             INT NOT NULL,
  name                  VARCHAR(255) NOT NULL,
  type                  VARCHAR(10) NOT NULL,
  modified_at           INT NOT NULL,
  account               VARCHAR(40) CHARACTER SET 'utf8' DEFAULT NULL,
  comment               TEXT CHARACTER SET 'utf8' NOT NULL,
  PRIMARY KEY (id)
) Engine=InnoDB;

CREATE INDEX comments_name_type_idx ON comments (name, type);
CREATE INDEX comments_order_idx ON comments (domain_id, modified_at);

DROP TABLE IF EXISTS domainmetadata;
CREATE TABLE domainmetadata (
  id                    INT AUTO_INCREMENT,
  domain_id             INT NOT NULL,
  kind                  VARCHAR(32),
  content               TEXT,
  PRIMARY KEY (id)
) Engine=InnoDB;

CREATE INDEX domainmetadata_idx ON domainmetadata (domain_id, kind);

DROP TABLE IF EXISTS cryptokeys;
CREATE TABLE cryptokeys (
  id                    INT AUTO_INCREMENT,
  domain_id             INT NOT NULL,
  flags                 INT NOT NULL,
  active                BOOL,
  content               TEXT,
  PRIMARY KEY(id)
) Engine=InnoDB;

CREATE INDEX domainidindex ON cryptokeys(domain_id);

DROP TABLE IF EXISTS tsigkeys;
CREATE TABLE tsigkeys (
  id                    INT AUTO_INCREMENT,
  name                  VARCHAR(255),
  algorithm             VARCHAR(50),
  secret                VARCHAR(255),
  PRIMARY KEY (id)
) Engine=InnoDB;

CREATE UNIQUE INDEX namealgoindex ON tsigkeys(name, algorithm);

--
-- ProFTPd Schemas
--

DROP TABLE IF EXISTS ftpgroup;
CREATE TABLE ftpgroup (
  groupname varchar(16) NOT NULL default '',
  gid smallint(6) NOT NULL default '2001',
  members varchar(16) NOT NULL default '',
  KEY groupname (groupname)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS ftpquotalimits;
CREATE TABLE ftpquotalimits (
  name varchar(30) default NULL,
  quota_type enum('user','group','class','all') NOT NULL default 'user',
  per_session enum('false','true') NOT NULL default 'false',
  limit_type enum('soft','hard') NOT NULL default 'soft',
  bytes_in_avail bigint(20) unsigned NOT NULL default '0',
  bytes_out_avail bigint(20) unsigned NOT NULL default '0',
  bytes_xfer_avail bigint(20) unsigned NOT NULL default '0',
  files_in_avail int(10) unsigned NOT NULL default '0',
  files_out_avail int(10) unsigned NOT NULL default '0',
  files_xfer_avail int(10) unsigned NOT NULL default '0'
) ENGINE=InnoDB;

DROP TABLE IF EXISTS ftpquotatallies;
CREATE TABLE ftpquotatallies (
  name varchar(30) NOT NULL default '',
  quota_type enum('user','group','class','all') NOT NULL default 'user',
  bytes_in_used bigint(20) unsigned NOT NULL default '0',
  bytes_out_used bigint(20) unsigned NOT NULL default '0',
  bytes_xfer_used bigint(20) unsigned NOT NULL default '0',
  files_in_used int(10) unsigned NOT NULL default '0',
  files_out_used int(10) unsigned NOT NULL default '0',
  files_xfer_used int(10) unsigned NOT NULL default '0'
) ENGINE=InnoDB;

DROP TABLE IF EXISTS ftpuser;
CREATE TABLE ftpuser (
  id int(10) unsigned NOT NULL auto_increment,
  userid varchar(32) NOT NULL default '',
  passwd varchar(64) NOT NULL default '',
  uid smallint(6) NOT NULL default '2001',
  gid smallint(6) NOT NULL default '2001',
  homedir varchar(255) NOT NULL default '',
  shell varchar(16) NOT NULL default '/sbin/nologin',
  count int(11) NOT NULL default '0',
  accessed datetime NOT NULL default '0000-00-00 00:00:00',
  modified datetime NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY (id),
  UNIQUE KEY userid (userid)
) ENGINE=InnoDB;

--
-- Postfix Schemas
--

CREATE TABLE `mail_users` (
  `id` int(11) NOT NULL auto_increment,
  `domain_id` int(11) NOT NULL,
  `password` varchar(106) NOT NULL,
  `email` varchar(100) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`),
  FOREIGN KEY (domain_id) REFERENCES domains(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `mail_aliases` (
  `id` int(11) NOT NULL auto_increment,
  `domain_id` int(11) NOT NULL,
  `source` varchar(100) NOT NULL,
  `destination` varchar(100) NOT NULL,
  PRIMARY KEY (`id`),
  FOREIGN KEY (domain_id) REFERENCES domains(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET FOREIGN_KEY_CHECKS=1;
