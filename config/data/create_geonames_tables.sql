DROP TABLE IF EXISTS gn_geoname CASCADE;
CREATE TABLE gn_geoname (
    geonameid      INT,
    name           VARCHAR(200),
    asciiname      VARCHAR(200),
    alternatenames VARCHAR,
    latitude       FLOAT,
    longitude      FLOAT,
    fclass         CHAR(1),
    fcode          VARCHAR(10),
    country        VARCHAR(2),
    cc2            VARCHAR(60),
    admin1         VARCHAR(20),
    admin2         VARCHAR(80),
    admin3         VARCHAR(20),
    admin4         VARCHAR(20),
    population     BIGINT,
    elevation      INT,
    gtopo30        INT,
    timezone       VARCHAR(40),
    moddate        DATE
);

DROP TABLE IF EXISTS gn_alternatename;
CREATE TABLE gn_alternatename (
    alternatenameId INT,
    geonameid       INT,
    isoLanguage     VARCHAR(7),
    alternateName   VARCHAR(300),
    isPreferredName BOOLEAN,
    isShortName     BOOLEAN,
    isColloquial    BOOLEAN,
    isHistoric      BOOLEAN
);

ALTER TABLE ONLY gn_alternatename
        ADD CONSTRAINT pk_alternatenameid PRIMARY KEY (alternatenameid);
ALTER TABLE ONLY gn_geoname
        ADD CONSTRAINT pk_geonameid PRIMARY KEY (geonameid);
ALTER TABLE ONLY gn_alternatename
        ADD CONSTRAINT fk_geonameid FOREIGN KEY (geonameid) REFERENCES gn_geoname(geonameid);
CREATE INDEX index_alternatename_geonameid ON gn_alternatename USING hash (geonameid);

