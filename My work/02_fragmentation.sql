-- 02_fragmentation.sql
-- Script de fragmentation et distribution (Approche Top-Down)
-- Basé sur la configuration "Mini Projet BDDA" (Refactored Schema)

-- ===========================================================================
-- SITE 1 : SIÈGE (192.168.56.1) - BASE "Etudiant"
-- ===========================================================================
-- Connecté en tant que admin_global

-- 1. Configuration des liens
ALTER SYSTEM SET GLOBAL_NAMES = FALSE;

-- Lien vers Site 2 (Info)
CREATE DATABASE LINK link_to_info
CONNECT TO AgentInfo IDENTIFIED BY orcl867
USING '192.168.56.10:1521/BdInfo';

-- Lien vers Site 3 (Maths)
CREATE DATABASE LINK link_to_maths
CONNECT TO AgentMaths IDENTIFIED BY orcl867
USING '192.168.56.11:1521/BdMaths';

-- 2. Fragmentation Verticale (Données Personnelles)
-- On reconstitue la vue "Personne" à partir des deux tables disjointes
CREATE TABLE Personnes_Admin AS
SELECT ID, Nom, Prenom, Datenais, Adr, Tel, Email, Nss FROM Enseignants
UNION ALL
SELECT ID, Nom, Prenom, Datenais, Adr, Tel, Email, Nss FROM Etudiants;

-- 3. Création de Vues Globales (Pour contourner ORA-22804 sur tables objets)
-- Ces vues "aplatissent" les colonnes pour qu'elles soient vues comme du SQL standard à travers le dblink

CREATE OR REPLACE VIEW V_Etudiants_Global AS
SELECT 
    ID, Nom, Prenom, Datenais, Adr, Tel, Email, Nss,
    EtDateInsc AS DateInsc, EtBac AS Bac, EtStatut AS Statut, EtBourse AS Bourse, DepID
FROM Etudiants;

CREATE OR REPLACE VIEW V_Enseignants_Global AS
SELECT 
    ID, Nom, Prenom, Datenais, Adr, Tel, Email, Nss,
    EnsEtatCivil AS EtatCivil, EnsDaterect AS DateRect, EnsSpec AS Spec, EnsTitre AS Titre, DepID
FROM Enseignants;

CREATE OR REPLACE VIEW V_Salles_Global AS
SELECT 
    s.SalleID.SID AS SID,
    s.SalleID.DepID AS DepID,
    s.SType,
    s.Snom,
    s.SNbPlaces,
    s.Setage,
    s.Sbloc
FROM Salles s;

-- ===========================================================================
-- SITE 2 : DÉPARTEMENT INFORMATIQUE (192.168.56.10) - BASE "BdInfo"
-- ===========================================================================
-- Connecté en tant que AgentInfo

-- 1. Lien vers le Siège
CREATE DATABASE LINK link_to_siege
CONNECT TO admin_global IDENTIFIED BY orcl867
USING 'BDETUDIANT_SITE';

-- 2. Fragmentation Mixte - Etudiants (Données Métier Info)
CREATE TABLE Etudiants_Info AS
SELECT *
FROM V_Etudiants_Global@link_to_siege
WHERE DepID = 1;

-- 3. Fragmentation Mixte - Enseignants (Données Métier Info)
CREATE TABLE Enseignants_Info AS
SELECT *
FROM V_Enseignants_Global@link_to_siege
WHERE DepID = 1;

-- 4. Fragmentation Horizontale - Salles
CREATE TABLE Salles_Info AS
SELECT *
FROM V_Salles_Global@link_to_siege
WHERE DepID = 1;

-- 5. Fragmentation Horizontale - Séances
CREATE TABLE Seances_Info AS
SELECT *
FROM Seances@link_to_siege
WHERE DepID = 1; -- @TODO: depID pas implémenté (a refaire) 

-- ===========================================================================
-- SITE 3 : DÉPARTEMENT MATHÉMATIQUES (192.168.56.11) - BASE "BdMaths"
-- ===========================================================================
-- Connecté en tant que AgentMaths

-- 1. Lien vers le Siège
CREATE DATABASE LINK link_to_siege
CONNECT TO admin_global IDENTIFIED BY orcl867
USING 'BDETUDIANT_SITE';

-- 2. Fragmentation Mixte - Etudiants (Données Métier Maths)
CREATE TABLE Etudiants_Math AS
SELECT *
FROM V_Etudiants_Global@link_to_siege
WHERE DepID = 2;

-- 3. Fragmentation Mixte - Enseignants (Données Métier Maths)
CREATE TABLE Enseignants_Math AS
SELECT *
FROM V_Enseignants_Global@link_to_siege
WHERE DepID = 2;

-- 4. Fragmentation Horizontale - Salles
CREATE TABLE Salles_Math AS
SELECT *
FROM V_Salles_Global@link_to_siege
WHERE DepID = 2;

-- 5. Fragmentation Horizontale - Séances
CREATE TABLE Seances_Math AS
SELECT *
FROM Seances@link_to_siege
WHERE DepID = 2; -- @TODO: depID pas implémenté (a refaire) 
