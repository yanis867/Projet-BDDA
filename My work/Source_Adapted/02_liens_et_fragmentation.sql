-- 02_liens_et_fragmentation.sql
-- Adapted for User's Environment

-- 1. Creation des liens
-- Adapter les noms d'utilisateurs et mots de passe selon votre configuration

-- Lien vers Etudiant du Site 1 (depuis les autres sites)
-- Utilisateur: admin_global
CREATE DATABASE LINK link_etu
CONNECT TO admin_global IDENTIFIED BY orcl867
USING '192.168.56.1:1521/Etudiant';

-- Lien vers BdInfo du Site 2
-- Utilisateur: AgentInfo
CREATE DATABASE LINK link_info
CONNECT TO AgentInfo IDENTIFIED BY orcl867
USING '192.168.56.10:1521/BdInfo';

-- Lien vers BdMaths du Site 3
-- Utilisateur: AgentMaths
CREATE DATABASE LINK link_math
CONNECT TO AgentMaths IDENTIFIED BY orcl867
USING '192.168.56.11:1521/BdMaths';

----------------------------------------------------------------------
-- 2. Fragmentation mixte en suivant les instructions de la fiche de TP
----------------------------------------------------------------------

--------------------
-- ETUDIANTS
--------------------

-- etudiants_admin : (Site 1) Projection pour admin
CREATE TABLE etudiants_admin AS 
SELECT etid, nom, prenom, datenais, adr, tel, email, nss, villenais, prenompere, mere 
FROM etudiants@link_etu;

-- etudiants_info : (Site 2) Selection pour DepID = 1
CREATE TABLE etudiants_info AS 
SELECT etid, dateinsc, bac, statut, bourse, depid 
FROM etudiants@link_etu 
WHERE depid=1;

-- etudiants_math : (Site 3) Selection pour DepID = 2
CREATE TABLE etudiants_math AS 
SELECT etid, dateinsc, bac, statut, bourse, depid 
FROM etudiants@link_etu 
WHERE depid=2;


--------------------
-- ENSEIGNANTS
--------------------

-- enseignant_admin : (Site 1) Projection
CREATE TABLE enseignant_admin AS 
SELECT ensid, nom, prenom, datenais, adr, tel, email, nss, etatcivil 
FROM enseignants@link_etu;

-- enseignant_info : (Site 2) Selection pour DepID = 1
CREATE TABLE enseignant_info AS 
SELECT ensid, daterect, spec, titre, depid 
FROM enseignants@link_etu 
WHERE depid = 1;

-- enseignant_math : (Site 3) Selection pour DepID = 2
CREATE TABLE enseignant_math AS 
SELECT ensid, daterect, spec, titre, depid 
FROM enseignants@link_etu 
WHERE depid = 2;


--------------------
-- SALLES
--------------------

-- salles_info : (Site 2)
CREATE TABLE salles_info AS 
SELECT * FROM salles@link_etu WHERE depid=1;

-- salles_math : (Site 3)
CREATE TABLE salles_math AS 
SELECT * FROM salles@link_etu WHERE depid=2;


--------------------
-- SEANCES
--------------------

-- seances_info : (Site 2)
CREATE TABLE seances_info AS 
SELECT * FROM seances@link_etu WHERE depid=1;

-- seances_math : (Site 3)
CREATE TABLE seances_math AS 
SELECT * FROM seances@link_etu WHERE depid=2;

