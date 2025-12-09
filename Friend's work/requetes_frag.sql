creation des liens:

CREATE DATABASE LINK link_etu
CONNECT TO admin IDENTIFIED BY azerty
USING 'Etudiant';

CREATE DATABASE LINK link_info
CONNECT TO system IDENTIFIED BY azerty
USING 'BdInfo';

CREATE DATABASE LINK link_math
CONNECT TO system IDENTIFIED BY azerty
USING 'BdMaths';

fragmentation mixte en suivant les instructions de la fiche de tp

etudiants_admin:

CREATE TABLE etudiants_admin AS SELECT etid, nom, prenom, datenais, adr, tel, email, nss, villenais, prenompere, mere FROM etudiants@link_etu;

etudiants_info:

CREATE TABLE etudiants_info AS SELECT etid, dateinsc, bac, statut, bourse, depid FROM etudiants@link_etu WHERE depid=1;

etudiants_math:

CREATE TABLE etudiants_math AS SELECT etid, dateinsc, bac, statut, bourse, depid FROM etudiants@link_etu WHERE depid=2;


enseignant_admin:

CREATE TABLE enseignant_admin AS SELECT ensid, nom, prenom, datenais, adr, tel, email, nss, etatcivil FROM enseignants@link_etu;

enseignant_info:

CREATE TABLE enseignant_info AS SELECT ensid, daterect, spec, titre, depid FROM enseignants@link_etu WHERE depid = 1;

enseignant_math:

CREATE TABLE enseignant_math AS SELECT ensid, daterect, spec, titre, depid FROM enseignants@link_etu WHERE depid = 2;

salles_info:

CREATE TABLE salles_info AS SELECT * FROM salles@link_etu WHERE depid=1;

salles_math:

CREATE TABLE salles_math AS SELECT * FROM salles@link_etu WHERE depid=2;

seances_info:

CREATE TABLE seances_info AS SELECT * FROM seances@link_etu WHERE depid=1;

seances_math:

CREATE TABLE seances_math AS SELECT * FROM seances@link_etu WHERE depid=2;

