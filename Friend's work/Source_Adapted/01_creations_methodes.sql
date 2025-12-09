-- 01_creations_methodes.sql
-- Adapted from Friend's work for User's Environment
-- SCHÉMA ORIENTÉ OBJET COMPLET (Université)
-- 2 départements : 1 = Informatique, 2 = Mathematique


SET SERVEROUTPUT ON SIZE UNLIMITED;


-- 1. NETTOYAGE COMPLET

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE Seances CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE Salles CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE Etudiants CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE Enseignants CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE Departements CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- Drop des types (ordre : enfants -> parent)
BEGIN
   EXECUTE IMMEDIATE 'DROP TYPE Seance_Type FORCE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP TYPE Salle_Type FORCE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP TYPE Etudiant_Type FORCE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP TYPE Enseignant_Type FORCE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP TYPE Departement_Type FORCE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP TYPE Personne_Type FORCE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/


-- 2. TYPE PERSONNE (PARENT)

CREATE OR REPLACE TYPE Personne_Type AS OBJECT (
  Nom      VARCHAR2(50),
  Prenom   VARCHAR2(50),
  DateNais DATE,
  Adr      VARCHAR2(100),
  Tel      VARCHAR2(20),
  Email    VARCHAR2(50),
  Nss      NUMBER,

  MEMBER FUNCTION afficherNomComplet RETURN VARCHAR2,
  MEMBER FUNCTION calculerAge RETURN NUMBER,
  MEMBER PROCEDURE modifierContact(p_tel VARCHAR2, p_email VARCHAR2, p_adr VARCHAR2)
) NOT FINAL;
/


-- 3. TYPE ETUDIANT AVEC MÉTHODES

CREATE OR REPLACE TYPE Etudiant_Type UNDER Personne_Type (
  EtID         NUMBER,
  VilleNais    VARCHAR2(50),
  PrenomPere   VARCHAR2(50),
  Mere         VARCHAR2(50),
  DateInsc     DATE,
  Bac          NUMBER,
  Statut       VARCHAR2(20),
  Bourse       VARCHAR2(20),
  DepID        NUMBER,

  MEMBER FUNCTION afficherInfos RETURN VARCHAR2,
  MEMBER PROCEDURE inscrire(p_EnsID NUMBER, p_ScType VARCHAR2, p_ScJour VARCHAR2,
                            p_ScCreneau VARCHAR2, p_Descrip VARCHAR2, p_SID NUMBER),
  MEMBER PROCEDURE changerNiveau(p_nouveau_statut VARCHAR2),
  MEMBER FUNCTION payerFrais(p_montant NUMBER) RETURN VARCHAR2,
  MEMBER FUNCTION verifierBourse RETURN VARCHAR2,
  OVERRIDING MEMBER FUNCTION afficherNomComplet RETURN VARCHAR2
);
/


-- 4. TYPE ENSEIGNANT AVEC MÉTHODES

CREATE OR REPLACE TYPE Enseignant_Type UNDER Personne_Type (
  EnsID       NUMBER,
  EtatCivil   VARCHAR2(20),
  DateRect    DATE,
  Spec        VARCHAR2(50),
  Titre       VARCHAR2(30),
  DepID       NUMBER,

  MEMBER PROCEDURE ajouterSeance(p_EtID NUMBER, p_ScType VARCHAR2, p_ScJour VARCHAR2,
                                 p_ScCreneau VARCHAR2, p_Descrip VARCHAR2,
                                 p_SID NUMBER, p_DepID NUMBER),
  MEMBER PROCEDURE modifierGrade(p_nouveau_titre VARCHAR2),
  MEMBER FUNCTION afficherPlanning RETURN SYS_REFCURSOR,
  MEMBER FUNCTION calculerAnciennete RETURN NUMBER,
  MEMBER FUNCTION afficherInfos RETURN VARCHAR2,
  OVERRIDING MEMBER FUNCTION afficherNomComplet RETURN VARCHAR2
);
/


-- 5. TYPE DEPARTEMENT AVEC MÉTHODES

CREATE OR REPLACE TYPE Departement_Type AS OBJECT (
  DepID    NUMBER,
  DepDesig VARCHAR2(50),
  EnsID    NUMBER,

  MEMBER FUNCTION afficherMembres RETURN SYS_REFCURSOR,
  MEMBER PROCEDURE ajouterMembre(p_type VARCHAR2, p_membre_id NUMBER),
  MEMBER FUNCTION compterEtudiants RETURN NUMBER,
  MEMBER FUNCTION compterEnseignants RETURN NUMBER,
  MEMBER FUNCTION afficherInfos RETURN VARCHAR2,
  MEMBER FUNCTION afficherChef RETURN VARCHAR2
);
/


-- 6. TYPE SALLE AVEC MÉTHODES

CREATE OR REPLACE TYPE Salle_Type AS OBJECT (
  SID       NUMBER,
  DepID     NUMBER,
  SType     VARCHAR2(20),
  SNom      VARCHAR2(50),
  SNbPlaces NUMBER,
  Setage    NUMBER,
  Sbloc     VARCHAR2(20),

  MEMBER FUNCTION afficherOccupation RETURN SYS_REFCURSOR,
  MEMBER PROCEDURE ajouterReservation(p_EnsID NUMBER, p_EtID NUMBER, p_ScType VARCHAR2,
                                     p_ScJour VARCHAR2, p_ScCreneau VARCHAR2, p_Descrip VARCHAR2),
  MEMBER FUNCTION verifierDisponibilite(p_jour VARCHAR2, p_creneau VARCHAR2) RETURN VARCHAR2,
  MEMBER FUNCTION afficherInfos RETURN VARCHAR2,
  MEMBER FUNCTION calculerTauxOccupation RETURN NUMBER
);
/



-- 7. TYPE SEANCE AVEC MÉTHODES

CREATE OR REPLACE TYPE Seance_Type AS OBJECT (
  EnsID     NUMBER,
  EtID      NUMBER,
  ScType    VARCHAR2(20),
  ScJour    VARCHAR2(20),
  ScCreneau VARCHAR2(20),
  Descrip   VARCHAR2(100),
  SID       NUMBER,
  DepID     NUMBER,

  MEMBER PROCEDURE changerHoraire(p_nouveau_jour VARCHAR2, p_nouveau_creneau VARCHAR2),
  MEMBER PROCEDURE ajouterEtudiant(p_nouvel_EtID NUMBER),
  MEMBER FUNCTION afficherParticipants RETURN SYS_REFCURSOR,
  MEMBER FUNCTION afficherInfos RETURN VARCHAR2,
  MEMBER PROCEDURE annulerSeance
);
/




-- 8. TABLES OBJET

CREATE TABLE Departements OF Departement_Type (PRIMARY KEY (DepID));

CREATE TABLE Enseignants  OF Enseignant_Type  (PRIMARY KEY (EnsID));
ALTER TABLE Enseignants ADD CONSTRAINT fk_ens_dept    FOREIGN KEY (DepID) REFERENCES Departements(DepID);

CREATE TABLE Etudiants    OF Etudiant_Type    (PRIMARY KEY (EtID));
ALTER TABLE Etudiants   ADD CONSTRAINT fk_etud_dept   FOREIGN KEY (DepID) REFERENCES Departements(DepID);

CREATE TABLE Salles       OF Salle_Type       (PRIMARY KEY (SID, DepID));
ALTER TABLE Salles      ADD CONSTRAINT fk_salle_dept  FOREIGN KEY (DepID) REFERENCES Departements(DepID);

CREATE TABLE Seances      OF Seance_Type;
ALTER TABLE Seances     ADD CONSTRAINT fk_seance_ens  FOREIGN KEY (EnsID) REFERENCES Enseignants(EnsID);
ALTER TABLE Seances     ADD CONSTRAINT fk_seance_etud FOREIGN KEY (EtID)  REFERENCES Etudiants(EtID);
ALTER TABLE Seances     ADD CONSTRAINT fk_seance_salle FOREIGN KEY (SID, DepID) REFERENCES Salles(SID, DepID);
ALTER TABLE Seances     ADD CONSTRAINT fk_seance_dept FOREIGN KEY (DepID) REFERENCES Departements(DepID);


-- 10. DONNÉES DE BASE


INSERT INTO Departements VALUES (Departement_Type(1, 'Informatique', NULL));
INSERT INTO Departements VALUES (Departement_Type(2, 'Mathematique', NULL));


INSERT INTO Enseignants VALUES (Enseignant_Type('Doe','John', DATE '1901-01-01',
  '1 rue un','0111111111','john.doe@gmail.com',111111111,
  1, 'Marie', DATE '1951-01-01','ASD','Professeur',1));


INSERT INTO Salles VALUES (Salle_Type(304,2,'Classe','M201',40,1,'Bloc C'));



INSERT INTO Etudiants VALUES (Etudiant_Type('Bendjemaa','Djamila',DATE '2003-09-09','Oran','0555000018','djamila.bendjemaa@etud.dz',201017017,1017,'Oran','Rabah','Safa',SYSDATE,2021,'Actif','Oui',1));
INSERT INTO Etudiants VALUES (Etudiant_Type('Bouayed','Mourad',DATE '2002-01-01','Sidi Bel Abbes','0555000019','mourad.bouayed@etud.dz',201018018,1018,'Sidi Bel Abbes','Lotfi','Kenza',SYSDATE,2020,'Actif','Non',2));



INSERT INTO Seances VALUES (Seance_Type(1,1017,'Cours','Jeudi','08h-10h','Analyse',304,2));


UPDATE Departements SET EnsID = (SELECT MIN(EnsID) FROM Enseignants WHERE DepID = 1) WHERE DepID = 1;
UPDATE Departements SET EnsID = (SELECT MIN(EnsID) FROM Enseignants WHERE DepID = 2) WHERE DepID = 2;
COMMIT;