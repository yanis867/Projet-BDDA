-- corrected.sql
-- SCHÉMA ORIENTÉ OBJET COMPLET (Université)
-- 2 départements : 1 = Informatique, 2 = Mathematique
------------------------------------------------------------

SET SERVEROUTPUT ON SIZE UNLIMITED;

------------------------------------------------------------
-- 1. NETTOYAGE COMPLET
------------------------------------------------------------
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

------------------------------------------------------------
-- 2. TYPE PERSONNE (PARENT)
------------------------------------------------------------
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

CREATE OR REPLACE TYPE BODY Personne_Type AS
  MEMBER FUNCTION afficherNomComplet RETURN VARCHAR2 IS
  BEGIN
    RETURN SELF.Nom || ' ' || SELF.Prenom;
  END;

  MEMBER FUNCTION calculerAge RETURN NUMBER IS
  BEGIN
    RETURN TRUNC(MONTHS_BETWEEN(SYSDATE, SELF.DateNais) / 12);
  END;

  MEMBER PROCEDURE modifierContact(p_tel VARCHAR2, p_email VARCHAR2, p_adr VARCHAR2) IS
  BEGIN
    SELF.Tel := p_tel;
    SELF.Email := p_email;
    SELF.Adr := p_adr;
  END;
END;
/

------------------------------------------------------------
-- 3. TYPE ETUDIANT AVEC MÉTHODES
------------------------------------------------------------
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

CREATE OR REPLACE TYPE BODY Etudiant_Type AS
  MEMBER FUNCTION afficherInfos RETURN VARCHAR2 IS
    v_info VARCHAR2(500);
  BEGIN
    v_info := 'ID: ' || SELF.EtID ||
              ', Nom: ' || SELF.Nom || ' ' || SELF.Prenom ||
              ', Date Naissance: ' || TO_CHAR(SELF.DateNais, 'DD/MM/YYYY') ||
              ', Ville: ' || SELF.VilleNais ||
              ', Email: ' || SELF.Email ||
              ', Tel: ' || SELF.Tel ||
              ', Statut: ' || SELF.Statut ||
              ', Bourse: ' || SELF.Bourse ||
              ', Departement: ' || SELF.DepID ||
              ', Bac: ' || SELF.Bac ||
              ', Age: ' || SELF.calculerAge() || ' ans';
    RETURN v_info;
  END;

  MEMBER PROCEDURE inscrire(p_EnsID NUMBER, p_ScType VARCHAR2, p_ScJour VARCHAR2,
                           p_ScCreneau VARCHAR2, p_Descrip VARCHAR2, p_SID NUMBER) IS
  BEGIN
    INSERT INTO Seances VALUES (Seance_Type(
      p_EnsID, SELF.EtID, p_ScType, p_ScJour, p_ScCreneau,
      p_Descrip, p_SID, SELF.DepID
    ));
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      RAISE;
  END;

  MEMBER PROCEDURE changerNiveau(p_nouveau_statut VARCHAR2) IS
  BEGIN
    UPDATE Etudiants e
    SET e.Statut = p_nouveau_statut
    WHERE e.EtID = SELF.EtID;
    COMMIT;
  END;

  MEMBER FUNCTION payerFrais(p_montant NUMBER) RETURN VARCHAR2 IS
    v_reduction NUMBER := 0;
  BEGIN
    IF SELF.Bourse = 'Oui' THEN
      v_reduction := p_montant * 0.5;
      RETURN 'Montant: ' || p_montant || ' DZD - Reduction bourse: ' || v_reduction ||
             ' DZD - A payer: ' || (p_montant - v_reduction) || ' DZD';
    ELSE
      RETURN 'Montant a payer: ' || p_montant || ' DZD (pas de bourse)';
    END IF;
  END;

  MEMBER FUNCTION verifierBourse RETURN VARCHAR2 IS
  BEGIN
    RETURN CASE WHEN SELF.Bourse = 'Oui'
           THEN 'Etudiant boursier - Reduction 50%'
           ELSE 'Pas de bourse' END;
  END;

  OVERRIDING MEMBER FUNCTION afficherNomComplet RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Etudiant: ' || SELF.Nom || ' ' || SELF.Prenom || ' (ID: ' || SELF.EtID || ')';
  END;
END;
/

------------------------------------------------------------
-- 4. TYPE ENSEIGNANT AVEC MÉTHODES
------------------------------------------------------------
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

CREATE OR REPLACE TYPE BODY Enseignant_Type AS
  MEMBER PROCEDURE ajouterSeance(p_EtID NUMBER, p_ScType VARCHAR2, p_ScJour VARCHAR2,
                                p_ScCreneau VARCHAR2, p_Descrip VARCHAR2,
                                p_SID NUMBER, p_DepID NUMBER) IS
  BEGIN
    INSERT INTO Seances VALUES (Seance_Type(
      SELF.EnsID, p_EtID, p_ScType, p_ScJour, p_ScCreneau,
      p_Descrip, p_SID, p_DepID
    ));
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      RAISE;
  END;

  MEMBER PROCEDURE modifierGrade(p_nouveau_titre VARCHAR2) IS
  BEGIN
    UPDATE Enseignants e
    SET e.Titre = p_nouveau_titre
    WHERE e.EnsID = SELF.EnsID;
    COMMIT;
  END;

  MEMBER FUNCTION afficherPlanning RETURN SYS_REFCURSOR IS
    v_cursor SYS_REFCURSOR;
  BEGIN
    OPEN v_cursor FOR
      SELECT s.ScJour, s.ScCreneau, s.ScType, s.Descrip, s.SID
      FROM Seances s
      WHERE s.EnsID = SELF.EnsID
      ORDER BY s.ScJour, s.ScCreneau;
    RETURN v_cursor;
  END;

  MEMBER FUNCTION calculerAnciennete RETURN NUMBER IS
  BEGIN
    RETURN TRUNC(MONTHS_BETWEEN(SYSDATE, SELF.DateRect) / 12);
  END;

  MEMBER FUNCTION afficherInfos RETURN VARCHAR2 IS
  BEGIN
    RETURN 'ID: ' || SELF.EnsID ||
           ', Nom: ' || SELF.Nom || ' ' || SELF.Prenom ||
           ', Titre: ' || SELF.Titre ||
           ', Specialite: ' || SELF.Spec ||
           ', Departement: ' || SELF.DepID ||
           ', Anciennete: ' || SELF.calculerAnciennete() || ' ans' ||
           ', Email: ' || SELF.Email;
  END;

  OVERRIDING MEMBER FUNCTION afficherNomComplet RETURN VARCHAR2 IS
  BEGIN
    RETURN SELF.Titre || ' ' || SELF.Nom || ' ' || SELF.Prenom;
  END;
END;
/

------------------------------------------------------------
-- 5. TYPE DEPARTEMENT AVEC MÉTHODES
------------------------------------------------------------
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

CREATE OR REPLACE TYPE BODY Departement_Type AS
  MEMBER FUNCTION afficherMembres RETURN SYS_REFCURSOR IS
    v_cursor SYS_REFCURSOR;
  BEGIN
    OPEN v_cursor FOR
      SELECT 'Enseignant' AS Type, e.EnsID AS ID, e.Nom, e.Prenom, e.Email
      FROM Enseignants e
      WHERE e.DepID = SELF.DepID
      UNION ALL
      SELECT 'Etudiant' AS Type, et.EtID AS ID, et.Nom, et.Prenom, et.Email
      FROM Etudiants et
      WHERE et.DepID = SELF.DepID;
    RETURN v_cursor;
  END;

  MEMBER PROCEDURE ajouterMembre(p_type VARCHAR2, p_membre_id NUMBER) IS
  BEGIN
    IF p_type = 'Enseignant' THEN
      UPDATE Enseignants SET DepID = SELF.DepID WHERE EnsID = p_membre_id;
    ELSIF p_type = 'Etudiant' THEN
      UPDATE Etudiants SET DepID = SELF.DepID WHERE EtID = p_membre_id;
    ELSE
      RAISE_APPLICATION_ERROR(-20002, 'Type invalide: Enseignant ou Etudiant');
    END IF;
    COMMIT;
  END;

  MEMBER FUNCTION compterEtudiants RETURN NUMBER IS
    v_count NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_count FROM Etudiants WHERE DepID = SELF.DepID;
    RETURN v_count;
  END;

  MEMBER FUNCTION compterEnseignants RETURN NUMBER IS
    v_count NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_count FROM Enseignants WHERE DepID = SELF.DepID;
    RETURN v_count;
  END;

  MEMBER FUNCTION afficherInfos RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Departement: ' || SELF.DepDesig ||
           ' (ID: ' || SELF.DepID || ')' ||
           ', Etudiants: ' || SELF.compterEtudiants() ||
           ', Enseignants: ' || SELF.compterEnseignants() ||
           ', Chef: ' || NVL(TO_CHAR(SELF.EnsID), 'Non defini');
  END;

  MEMBER FUNCTION afficherChef RETURN VARCHAR2 IS
    v_nom VARCHAR2(100);
  BEGIN
    SELECT e.Nom || ' ' || e.Prenom || ' (' || e.Titre || ')'
    INTO v_nom
    FROM Enseignants e
    WHERE e.EnsID = SELF.EnsID;
    RETURN v_nom;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN 'Pas de chef defini';
  END;
END;
/

------------------------------------------------------------
-- 6. TYPE SALLE AVEC MÉTHODES
------------------------------------------------------------
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

CREATE OR REPLACE TYPE BODY Salle_Type AS
  MEMBER FUNCTION afficherOccupation RETURN SYS_REFCURSOR IS
    v_cursor SYS_REFCURSOR;
  BEGIN
    OPEN v_cursor FOR
      SELECT s.ScJour, s.ScCreneau, s.ScType, s.Descrip, s.EnsID
      FROM Seances s
      WHERE s.SID = SELF.SID AND s.DepID = SELF.DepID
      ORDER BY s.ScJour, s.ScCreneau;
    RETURN v_cursor;
  END;

  MEMBER PROCEDURE ajouterReservation(p_EnsID NUMBER, p_EtID NUMBER, p_ScType VARCHAR2,
                                     p_ScJour VARCHAR2, p_ScCreneau VARCHAR2, p_Descrip VARCHAR2) IS
    v_count NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_count
    FROM Seances
    WHERE SID = SELF.SID AND DepID = SELF.DepID
      AND ScJour = p_ScJour AND ScCreneau = p_ScCreneau;

    IF v_count > 0 THEN
      RAISE_APPLICATION_ERROR(-20001, 'Salle deja reservee a ce creneau');
    END IF;

    INSERT INTO Seances VALUES (Seance_Type(
      p_EnsID, p_EtID, p_ScType, p_ScJour, p_ScCreneau,
      p_Descrip, SELF.SID, SELF.DepID
    ));
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      RAISE;
  END;

  MEMBER FUNCTION verifierDisponibilite(p_jour VARCHAR2, p_creneau VARCHAR2) RETURN VARCHAR2 IS
    v_count NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_count
    FROM Seances
    WHERE SID = SELF.SID AND DepID = SELF.DepID
      AND ScJour = p_jour AND ScCreneau = p_creneau;

    RETURN CASE WHEN v_count = 0 THEN 'Disponible' ELSE 'Occupee' END;
  END;

  MEMBER FUNCTION afficherInfos RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Salle: ' || SELF.SNom ||
           ' (ID: ' || SELF.SID || ')' ||
           ', Type: ' || SELF.SType ||
           ', Capacite: ' || SELF.SNbPlaces || ' places' ||
           ', Etage: ' || SELF.Setage ||
           ', Bloc: ' || SELF.Sbloc;
  END;

  MEMBER FUNCTION calculerTauxOccupation RETURN NUMBER IS
    v_count NUMBER;
    v_total_creneaux NUMBER := 35;
  BEGIN
    SELECT COUNT(DISTINCT ScJour || ScCreneau) INTO v_count
    FROM Seances
    WHERE SID = SELF.SID AND DepID = SELF.DepID;

    RETURN ROUND((v_count / v_total_creneaux) * 100, 22);
  END;
END;
/

------------------------------------------------------------
-- 7. TYPE SEANCE AVEC MÉTHODES
------------------------------------------------------------
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

CREATE OR REPLACE TYPE BODY Seance_Type AS
  MEMBER PROCEDURE changerHoraire(p_nouveau_jour VARCHAR2, p_nouveau_creneau VARCHAR2) IS
  BEGIN
    UPDATE Seances s
    SET s.ScJour = p_nouveau_jour, s.ScCreneau = p_nouveau_creneau
    WHERE s.EnsID = SELF.EnsID AND s.EtID = SELF.EtID
      AND s.ScJour = SELF.ScJour AND s.ScCreneau = SELF.ScCreneau;
    COMMIT;
  END;

  MEMBER PROCEDURE ajouterEtudiant(p_nouvel_EtID NUMBER) IS
  BEGIN
    INSERT INTO Seances VALUES (Seance_Type(
      SELF.EnsID, p_nouvel_EtID, SELF.ScType, SELF.ScJour, SELF.ScCreneau,
      SELF.Descrip, SELF.SID, SELF.DepID
    ));
    COMMIT;
  END;

  MEMBER FUNCTION afficherParticipants RETURN SYS_REFCURSOR IS
    v_cursor SYS_REFCURSOR;
  BEGIN
    OPEN v_cursor FOR
      SELECT e.EtID, e.Nom, e.Prenom, e.Email
      FROM Etudiants e
      JOIN Seances s ON e.EtID = s.EtID
      WHERE s.EnsID = SELF.EnsID
        AND s.ScJour = SELF.ScJour
        AND s.ScCreneau = SELF.ScCreneau;
    RETURN v_cursor;
  END;

  MEMBER FUNCTION afficherInfos RETURN VARCHAR2 IS
  BEGIN
    RETURN 'Seance ' || SELF.ScType ||
           ' - ' || SELF.Descrip ||
           ', Jour: ' || SELF.ScJour ||
           ', Creneau: ' || SELF.ScCreneau ||
           ', Salle: ' || SELF.SID ||
           ', Enseignant ID: ' || SELF.EnsID;
  END;

  MEMBER PROCEDURE annulerSeance IS
  BEGIN
    DELETE FROM Seances s
    WHERE s.EnsID = SELF.EnsID
      AND s.ScJour = SELF.ScJour
      AND s.ScCreneau = SELF.ScCreneau
      AND s.SID = SELF.SID;
    COMMIT;
  END;
END;
/

------------------------------------------------------------
-- 8. TABLES OBJET
------------------------------------------------------------
CREATE TABLE Departements OF Departement_Type (PRIMARY KEY (DepID));
CREATE TABLE Enseignants  OF Enseignant_Type  (PRIMARY KEY (EnsID));
CREATE TABLE Etudiants    OF Etudiant_Type    (PRIMARY KEY (EtID));
CREATE TABLE Salles       OF Salle_Type       (PRIMARY KEY (SID, DepID));
CREATE TABLE Seances      OF Seance_Type;

------------------------------------------------------------
-- 9. CONTRAINTES FK
------------------------------------------------------------
ALTER TABLE Etudiants   ADD CONSTRAINT fk_etud_dept   FOREIGN KEY (DepID) REFERENCES Departements(DepID);
ALTER TABLE Enseignants ADD CONSTRAINT fk_ens_dept    FOREIGN KEY (DepID) REFERENCES Departements(DepID);
ALTER TABLE Salles      ADD CONSTRAINT fk_salle_dept  FOREIGN KEY (DepID) REFERENCES Departements(DepID);
ALTER TABLE Seances     ADD CONSTRAINT fk_seance_ens  FOREIGN KEY (EnsID) REFERENCES Enseignants(EnsID);
ALTER TABLE Seances     ADD CONSTRAINT fk_seance_etud FOREIGN KEY (EtID)  REFERENCES Etudiants(EtID);
ALTER TABLE Seances     ADD CONSTRAINT fk_seance_salle FOREIGN KEY (SID, DepID) REFERENCES Salles(SID, DepID);
ALTER TABLE Seances     ADD CONSTRAINT fk_seance_dept FOREIGN KEY (DepID) REFERENCES Departements(DepID);

------------------------------------------------------------
-- 10. DONNÉES DE BASE
------------------------------------------------------------
-- 2 departements
INSERT INTO Departements VALUES (Departement_Type(1, 'Informatique', NULL));
INSERT INTO Departements VALUES (Departement_Type(2, 'Mathematique', NULL));

-- Enseignants (10)
INSERT INTO Enseignants VALUES (Enseignant_Type('Dupont','Jean', DATE '1975-03-15',
  '12 rue Lilas, Oran','0555123456','jean.dupont@univ.dz',123456789,
  1, 'Marie', DATE '2005-09-01','Bases de donnees','Professeur',1));

INSERT INTO Enseignants VALUES (Enseignant_Type('Haddad','Amina', DATE '1976-07-15',
  'Alger centre','0555123457','amina.haddad@univ.dz',223456789,
  2, 'Celibataire', DATE '2006-09-01','Algebre','Maitre de conferences',2));

INSERT INTO Enseignants VALUES (Enseignant_Type('Bensaid','Karim', DATE '1970-04-10',
  'Oran','0555000101','karim.bensaid@univ.dz',100100100,
  3, 'Marie', DATE '2000-09-01','Informatique','Professeur',1));

INSERT INTO Enseignants VALUES (Enseignant_Type('Mansouri','Nadia', DATE '1982-11-05',
  'Alger','0555000106','nadia.mansouri@univ.dz',100600600,
  4, 'Celibataire', DATE '2012-09-01','Electronique','Maitre de conferences',2));

INSERT INTO Enseignants VALUES (Enseignant_Type('Merabet','Yacine', DATE '1972-08-22',
  'Annaba','0555000109','yacine.merabet@univ.dz',100900900,
  5, 'Marie', DATE '1999-09-01','Architecture','Professeur',1));

INSERT INTO Enseignants VALUES (Enseignant_Type('Belkacem','Yasmine', DATE '1979-10-03',
  'Oran','0555000110','yasmine.belkacem@univ.dz',101010101,
  6, 'Celibataire', DATE '2006-09-01','Gestion','Maitre de conferences',2));

INSERT INTO Enseignants VALUES (Enseignant_Type('Ziani','Ali', DATE '1965-05-14',
  'Alger','0555000111','ali.ziani@univ.dz',101110111,
  7, 'Marie', DATE '1990-09-01','Economie','Professeur',1));

INSERT INTO Enseignants VALUES (Enseignant_Type('Saad','Lamia', DATE '1983-09-09',
  'Oran','0555000112','lamia.saad@univ.dz',101210121,
  8, 'Celibataire', DATE '2011-09-01','Droit','Maitre de conferences',2));

INSERT INTO Enseignants VALUES (Enseignant_Type('Amrani','Salima', DATE '1977-12-17',
  'Oran','0555000114','salima.amrani@univ.dz',101410141,
  9, 'Marie', DATE '2001-09-01','Francais','Professeur',1));

INSERT INTO Enseignants VALUES (Enseignant_Type('Zerrouki','Anis', DATE '1975-09-09',
  'Oran','0555000130','anis.zerrouki@univ.dz',103030303,
  10, 'Marie', DATE '2001-09-01','Telecommunications','Professeur',2));

-- Salles (SID 300..309)
INSERT INTO Salles VALUES (Salle_Type(300,1,'Amphi','Amphi Info',300,1,'Bloc A'));
INSERT INTO Salles VALUES (Salle_Type(301,1,'Classe','C101',40,1,'Bloc A'));
INSERT INTO Salles VALUES (Salle_Type(302,1,'Lab','Lab Info',25,0,'Bloc B'));
INSERT INTO Salles VALUES (Salle_Type(303,2,'Amphi','Amphi Math',250,1,'Bloc C'));
INSERT INTO Salles VALUES (Salle_Type(304,2,'Classe','M201',40,1,'Bloc C'));
INSERT INTO Salles VALUES (Salle_Type(305,2,'Lab','Lab Math',20,0,'Bloc D'));
INSERT INTO Salles VALUES (Salle_Type(306,1,'TP','TP Info',30,0,'Bloc E'));
INSERT INTO Salles VALUES (Salle_Type(307,2,'Salle','Salle Math 3',45,1,'Bloc F'));
INSERT INTO Salles VALUES (Salle_Type(308,1,'Salle','Salle Info 4',50,1,'Bloc G'));
INSERT INTO Salles VALUES (Salle_Type(309,2,'Salle','Salle Math 5',35,2,'Bloc H'));

-- 30 Etudiants (DepID 1 ou 2)
INSERT INTO Etudiants VALUES (Etudiant_Type('Benali','Karim',DATE '2002-05-10','Oran','0555112233','karim.benali@etud.dz',201001001,1001,'Oran','Ahmed','Fatima',SYSDATE,2020,'Actif','Oui',1));
INSERT INTO Etudiants VALUES (Etudiant_Type('Rahmani','Amina',DATE '2001-11-22','Alger','0555778899','amina.rahmani@etud.dz',201002002,1002,'Alger','Mohamed','Nadia',SYSDATE,2019,'Actif','Non',2));
INSERT INTO Etudiants VALUES (Etudiant_Type('Ouali','Yacine',DATE '2000-03-15','Oran','0555333344','yacine.ouali@etud.dz',201003003,1003,'Oran','Rachid','Samira',SYSDATE,2018,'Actif','Non',1));
INSERT INTO Etudiants VALUES (Etudiant_Type('Bouzid','Leila',DATE '2003-07-07','Constantine','0555444455','leila.bouzid@etud.dz',201004004,1004,'Constantine','Noureddine','Aicha',SYSDATE,2021,'Actif','Oui',2));
INSERT INTO Etudiants VALUES (Etudiant_Type('Mekki','Sofiane',DATE '2002-12-12','Annaba','0555555566','sofiane.mekki@etud.dz',201005005,1005,'Annaba','Mustapha','Zohra',SYSDATE,2020,'Actif','Non',1));
INSERT INTO Etudiants VALUES (Etudiant_Type('Kessa','Nadia',DATE '2001-01-20','Blida','0555666677','nadia.kessa@etud.dz',201006006,1006,'Blida','Samir','Lamia',SYSDATE,2019,'Actif','Oui',2));
INSERT INTO Etudiants VALUES (Etudiant_Type('Amara','Samir',DATE '2000-09-30','Tlemcen','0555777788','samir.amara@etud.dz',201007007,1007,'Tlemcen','Ali','Fatiha',SYSDATE,2018,'Actif','Non',1));
INSERT INTO Etudiants VALUES (Etudiant_Type('Zemmouri','Farah',DATE '2003-04-25','Oran','0555888899','farah.zemmouri@etud.dz',201008008,1008,'Oran','Lotfi','Rokia',SYSDATE,2021,'Actif','Oui',2));
INSERT INTO Etudiants VALUES (Etudiant_Type('Kamal','Yassine',DATE '2002-02-02','Annaba','0555999900','yassine.kamal@etud.dz',201009009,1009,'Annaba','Salah','Nadine',SYSDATE,2020,'Actif','Non',1));
INSERT INTO Etudiants VALUES (Etudiant_Type('Boukraa','Yasmine',DATE '2004-06-06','Oran','0555000011','yasmine.boukraa@etud.dz',201010010,1010,'Oran','Reda','Sara',SYSDATE,2022,'Actif','Oui',2));
INSERT INTO Etudiants VALUES (Etudiant_Type('Zerari','Ali',DATE '2001-08-18','Alger','0555000012','ali.zerari@etud.dz',201011011,1011,'Alger','Omar','Fatima',SYSDATE,2019,'Actif','Non',1));
INSERT INTO Etudiants VALUES (Etudiant_Type('Boulahdja','Lamia',DATE '2003-10-10','Oran','0555000013','lamia.boulahdja@etud.dz',201012012,1012,'Oran','Abdel','Najat',SYSDATE,2021,'Actif','Oui',2));
INSERT INTO Etudiants VALUES (Etudiant_Type('Cherif','Rachid',DATE '2000-05-05','Bejaia','0555000014','rachid.cherif@etud.dz',201013013,1013,'Bejaia','Hassan','Sana',SYSDATE,2018,'Actif','Non',1));
INSERT INTO Etudiants VALUES (Etudiant_Type('Amrani','Salima',DATE '2002-11-11','Oran','0555000015','salima.amrani2@etud.dz',201014014,1014,'Oran','Tarek','Meriem',SYSDATE,2020,'Actif','Oui',2));
INSERT INTO Etudiants VALUES (Etudiant_Type('Khoualed','Nadir',DATE '2001-03-03','Setif','0555000016','nadir.khoualed@etud.dz',201015015,1015,'Setif','Karim','Amina',SYSDATE,2019,'Actif','Non',1));
INSERT INTO Etudiants VALUES (Etudiant_Type('Bouazza','Hichem',DATE '2000-07-23','Alger','0555000017','hichem.bouazza@etud.dz',201016016,1016,'Alger','Nacer','Zineb',SYSDATE,2018,'Actif','Non',2));
INSERT INTO Etudiants VALUES (Etudiant_Type('Bendjemaa','Djamila',DATE '2003-09-09','Oran','0555000018','djamila.bendjemaa@etud.dz',201017017,1017,'Oran','Rabah','Safa',SYSDATE,2021,'Actif','Oui',1));
INSERT INTO Etudiants VALUES (Etudiant_Type('Bouayed','Mourad',DATE '2002-01-01','Sidi Bel Abbes','0555000019','mourad.bouayed@etud.dz',201018018,1018,'Sidi Bel Abbes','Lotfi','Kenza',SYSDATE,2020,'Actif','Non',2));
INSERT INTO Etudiants VALUES (Etudiant_Type('Kherici','Laila',DATE '2004-12-12','Constantine','0555000020','laila.kherici@etud.dz',201019019,1019,'Constantine','Nabil','Wafa',SYSDATE,2022,'Actif','Oui',1));
INSERT INTO Etudiants VALUES (Etudiant_Type('Boulifa','Walid',DATE '2000-04-04','Oran','0555000021','walid.boulifa@etud.dz',201020020,1020,'Oran','Farid','Houda',SYSDATE,2018,'Actif','Non',2));
INSERT INTO Etudiants VALUES (Etudiant_Type('Meziane','Hanane',DATE '2001-06-06','Alger','0555000022','hanane.meziane@etud.dz',201021021,1021,'Alger','Sami','Lila',SYSDATE,2019,'Actif','Oui',1));
INSERT INTO Etudiants VALUES (Etudiant_Type('Boudiaf','Yazid',DATE '2002-02-14','Oran','0555000023','yazid.boudiaf@etud.dz',201022022,1022,'Oran','Riad','Nadia',SYSDATE,2020,'Actif','Non',2));
INSERT INTO Etudiants VALUES (Etudiant_Type('Khelil','Rima',DATE '2003-07-07','Annaba','0555000024','rima.khelil@etud.dz',201023023,1023,'Annaba','Lotfi','Rana',SYSDATE,2021,'Actif','Oui',1));
INSERT INTO Etudiants VALUES (Etudiant_Type('Zeroual','Karim',DATE '2001-09-09','Alger','0555000025','karim.zeroual@etud.dz',201024024,1024,'Alger','Ahmed','Nour',SYSDATE,2019,'Actif','Non',2));
INSERT INTO Etudiants VALUES (Etudiant_Type('Taibi','Nabil',DATE '2002-10-10','Oran','0555000026','nabil.taibi@etud.dz',201025025,1025,'Oran','Samir','Lamia',SYSDATE,2020,'Actif','Oui',1));
INSERT INTO Etudiants VALUES (Etudiant_Type('Benamar','Sonia',DATE '2003-11-11','Blida','0555000027','sonia.benamar@etud.dz',201026026,1026,'Blida','Hichem','Salima',SYSDATE,2021,'Actif','Oui',2));
INSERT INTO Etudiants VALUES (Etudiant_Type('Nedjma','Lotfi',DATE '2000-08-08','Oran','0555000028','lotfi.nedjma@etud.dz',201027027,1027,'Oran','Noureddine','Fatiha',SYSDATE,2018,'Actif','Non',1));
INSERT INTO Etudiants VALUES (Etudiant_Type('Chergui','Abdel',DATE '2001-12-12','Bejaia','0555000029','abdel.chergui@etud.dz',201028028,1028,'Bejaia','Rachid','Zahra',SYSDATE,2019,'Actif','Non',2));
INSERT INTO Etudiants VALUES (Etudiant_Type('Toumi','Samira',DATE '2004-03-03','Oran','0555000030','samira.toumi@etud.dz',201029029,1029,'Oran','Nadjib','Imane',SYSDATE,2022,'Actif','Oui',1));

-- Seances (10) : toutes les salles/dep existent, pas d'apostrophe
INSERT INTO Seances VALUES (Seance_Type(1,1001,'Cours','Lundi','08h-10h','Introduction a linformatique',300,1));
INSERT INTO Seances VALUES (Seance_Type(2,1002,'Cours','Mardi','10h-12h','Algebre lineaire',303,2));
INSERT INTO Seances VALUES (Seance_Type(3,1003,'TP','Mercredi','14h-16h','TP Programmation',302,1));
INSERT INTO Seances VALUES (Seance_Type(4,1004,'Cours','Jeudi','08h-10h','Analyse',304,2));
INSERT INTO Seances VALUES (Seance_Type(5,1005,'TP','Vendredi','10h-12h','Laboratoire',306,1));
INSERT INTO Seances VALUES (Seance_Type(6,1006,'Cours','Lundi','12h-14h','Structures de donnees',301,1));
INSERT INTO Seances VALUES (Seance_Type(7,1007,'Cours','Mardi','08h-10h','Geometrie',307,2));
INSERT INTO Seances VALUES (Seance_Type(8,1008,'Cours','Mercredi','10h-12h','Systemes dexploitation',308,1));
INSERT INTO Seances VALUES (Seance_Type(9,1009,'TP','Jeudi','14h-16h','TP Calcul',305,2));
INSERT INTO Seances VALUES (Seance_Type(10,1010,'Cours','Vendredi','08h-10h','Algorithmique',309,2));

COMMIT;

------------------------------------------------------------
-- 11. ATTRIBUTION DES CHEFS
------------------------------------------------------------
UPDATE Departements SET EnsID = (SELECT MIN(EnsID) FROM Enseignants WHERE DepID = 1) WHERE DepID = 1;
UPDATE Departements SET EnsID = (SELECT MIN(EnsID) FROM Enseignants WHERE DepID = 2) WHERE DepID = 2;
COMMIT;

------------------------------------------------------------
-- 12. TESTS DES MÉTHODES
------------------------------------------------------------
SET SERVEROUTPUT ON;
DECLARE
  v_etudiant   Etudiant_Type;
  v_enseignant Enseignant_Type;
  v_dept       Departement_Type;
  v_salle      Salle_Type;
BEGIN
  DBMS_OUTPUT.PUT_LINE('========================================');
  DBMS_OUTPUT.PUT_LINE('    TESTS DES METHODES OBJET');
  DBMS_OUTPUT.PUT_LINE('========================================');

  -- Etudiant
  SELECT VALUE(e) INTO v_etudiant FROM Etudiants e WHERE e.EtID = 1001;
  DBMS_OUTPUT.PUT_LINE(CHR(10) || '=== ETUDIANT ===');
  DBMS_OUTPUT.PUT_LINE(v_etudiant.afficherInfos());
  DBMS_OUTPUT.PUT_LINE(v_etudiant.afficherNomComplet());
  DBMS_OUTPUT.PUT_LINE(v_etudiant.payerFrais(5000));
  DBMS_OUTPUT.PUT_LINE(v_etudiant.verifierBourse());

  -- Enseignant
  SELECT VALUE(ens) INTO v_enseignant FROM Enseignants ens WHERE ens.EnsID = 1;
  DBMS_OUTPUT.PUT_LINE(CHR(10) || '=== ENSEIGNANT ===');
  DBMS_OUTPUT.PUT_LINE(v_enseignant.afficherInfos());
  DBMS_OUTPUT.PUT_LINE(v_enseignant.afficherNomComplet());
  DBMS_OUTPUT.PUT_LINE('Anciennete: ' || v_enseignant.calculerAnciennete() || ' ans');

  -- Departement
  SELECT VALUE(d) INTO v_dept FROM Departements d WHERE d.DepID = 1;
  DBMS_OUTPUT.PUT_LINE(CHR(10) || '=== DEPARTEMENT ===');
  DBMS_OUTPUT.PUT_LINE(v_dept.afficherInfos());
  DBMS_OUTPUT.PUT_LINE('Chef: ' || v_dept.afficherChef());

  -- Salle
  SELECT VALUE(s) INTO v_salle FROM Salles s WHERE s.SID = 300 AND s.DepID = 1;
  DBMS_OUTPUT.PUT_LINE(CHR(10) || '=== SALLE ===');
  DBMS_OUTPUT.PUT_LINE(v_salle.afficherInfos());
  DBMS_OUTPUT.PUT_LINE('Disponibilite Lundi 08h-10h: ' ||
                       v_salle.verifierDisponibilite('Lundi','08h-10h'));

  DBMS_OUTPUT.PUT_LINE(CHR(10) || '========================================');
  DBMS_OUTPUT.PUT_LINE('    TOUS LES TESTS EXECUTES');
  DBMS_OUTPUT.PUT_LINE('========================================');
END;
/

------------------------------------------------------------
-- 13. VERIFICATION FINALE
------------------------------------------------------------
SELECT* FROM Departements;
SELECT * FROM Enseignants;
SELECT * FROM Etudiants;
SELECT *FROM Salles;
SELECT *FROM Seances;







SET SERVEROUTPUT ON SIZE UNLIMITED;
SET SERVEROUTPUT ON SIZE UNLIMITED;

DECLARE
  -- Instances objet
  v_personne   Personne_Type;
  v_etudiant   Etudiant_Type;
  v_enseignant Enseignant_Type;
  v_dept       Departement_Type;
  v_salle      Salle_Type;
  v_seance     Seance_Type;

  -- Pour curseurs
  cur SYS_REFCURSOR;

  -- Variables pour lecture de curseurs
  v_type        VARCHAR2(20);
  v_id          NUMBER;
  v_nom         VARCHAR2(50);
  v_prenom      VARCHAR2(50);
  v_email       VARCHAR2(100);

  v_jour        VARCHAR2(20);
  v_creneau     VARCHAR2(20);
  v_sctype      VARCHAR2(20);
  v_desc        VARCHAR2(100);
  v_sid         NUMBER;

  -- Sauvegarde pour restaurer quelques valeurs
  v_old_statut  VARCHAR2(20);
  v_old_titre   VARCHAR2(30);
  v_tmp         VARCHAR2(4000);

BEGIN
  DBMS_OUTPUT.PUT_LINE('========================================');
  DBMS_OUTPUT.PUT_LINE(' LISTE DES METHODES PAR TYPE');
  DBMS_OUTPUT.PUT_LINE('========================================');

  DBMS_OUTPUT.PUT_LINE('- Personne_Type');
  DBMS_OUTPUT.PUT_LINE('    * afficherNomComplet()');
  DBMS_OUTPUT.PUT_LINE('    * calculerAge()');
  DBMS_OUTPUT.PUT_LINE('    * modifierContact(p_tel, p_email, p_adr)');

  DBMS_OUTPUT.PUT_LINE('- Etudiant_Type (extends Personne_Type)');
  DBMS_OUTPUT.PUT_LINE('    * afficherInfos()');
  DBMS_OUTPUT.PUT_LINE('    * inscrire(p_EnsID, p_ScType, p_ScJour, p_ScCreneau, p_Descrip, p_SID)');
  DBMS_OUTPUT.PUT_LINE('    * changerNiveau(p_nouveau_statut)');
  DBMS_OUTPUT.PUT_LINE('    * payerFrais(p_montant)');
  DBMS_OUTPUT.PUT_LINE('    * verifierBourse()');
  DBMS_OUTPUT.PUT_LINE('    * (override) afficherNomComplet()');

  DBMS_OUTPUT.PUT_LINE('- Enseignant_Type (extends Personne_Type)');
  DBMS_OUTPUT.PUT_LINE('    * ajouterSeance(...)');
  DBMS_OUTPUT.PUT_LINE('    * modifierGrade(p_nouveau_titre)');
  DBMS_OUTPUT.PUT_LINE('    * afficherPlanning()  -- renvoie SYS_REFCURSOR');
  DBMS_OUTPUT.PUT_LINE('    * calculerAnciennete()');
  DBMS_OUTPUT.PUT_LINE('    * afficherInfos()');
  DBMS_OUTPUT.PUT_LINE('    * (override) afficherNomComplet()');

  DBMS_OUTPUT.PUT_LINE('- Departement_Type');
  DBMS_OUTPUT.PUT_LINE('    * afficherMembres()   -- SYS_REFCURSOR');
  DBMS_OUTPUT.PUT_LINE('    * ajouterMembre(p_type, p_membre_id)');
  DBMS_OUTPUT.PUT_LINE('    * compterEtudiants()');
  DBMS_OUTPUT.PUT_LINE('    * compterEnseignants()');
  DBMS_OUTPUT.PUT_LINE('    * afficherInfos()');
  DBMS_OUTPUT.PUT_LINE('    * afficherChef()');

  DBMS_OUTPUT.PUT_LINE('- Salle_Type');
  DBMS_OUTPUT.PUT_LINE('    * afficherOccupation() -- SYS_REFCURSOR');
  DBMS_OUTPUT.PUT_LINE('    * ajouterReservation(...)');
  DBMS_OUTPUT.PUT_LINE('    * verifierDisponibilite(p_jour, p_creneau)');
  DBMS_OUTPUT.PUT_LINE('    * afficherInfos()');
  DBMS_OUTPUT.PUT_LINE('    * calculerTauxOccupation()');

  DBMS_OUTPUT.PUT_LINE('- Seance_Type');
  DBMS_OUTPUT.PUT_LINE('    * changerHoraire(p_nouveau_jour, p_nouveau_creneau)');
  DBMS_OUTPUT.PUT_LINE('    * ajouterEtudiant(p_nouvel_EtID)');
  DBMS_OUTPUT.PUT_LINE('    * afficherParticipants() -- SYS_REFCURSOR');
  DBMS_OUTPUT.PUT_LINE('    * afficherInfos()');
  DBMS_OUTPUT.PUT_LINE('    * annulerSeance()');

  DBMS_OUTPUT.PUT_LINE(CHR(10) || '========================================');
  DBMS_OUTPUT.PUT_LINE('   PREPARATION DES DONNEES POUR LES TESTS');
  DBMS_OUTPUT.PUT_LINE('========================================');

  -- On prend un etudiant existant
  SELECT VALUE(e)
  INTO v_etudiant
  FROM Etudiants e
  WHERE ROWNUM = 1;

  -- Un enseignant du meme departement
  SELECT VALUE(ens)
  INTO v_enseignant
  FROM Enseignants ens
  WHERE ens.DepID = v_etudiant.DepID
    AND ROWNUM = 1;

  -- Une salle du meme departement
  SELECT VALUE(s)
  INTO v_salle
  FROM Salles s
  WHERE s.DepID = v_etudiant.DepID
    AND ROWNUM = 1;

  -- Departement de l'etudiant
  SELECT VALUE(d)
  INTO v_dept
  FROM Departements d
  WHERE d.DepID = v_etudiant.DepID;

  -- On cree une seance de test pour tester Seance_Type
  INSERT INTO Seances
  VALUES (
    Seance_Type(
      v_enseignant.EnsID,
      v_etudiant.EtID,
      'Cours',
      'Lundi',
      '08h-10h',
      'Seance test',
      v_salle.SID,
      v_salle.DepID
    )
  );

  -- Recuperer cette seance dans un objet
  SELECT VALUE(s)
  INTO v_seance
  FROM Seances s
  WHERE s.EnsID    = v_enseignant.EnsID
    AND s.EtID     = v_etudiant.EtID
    AND s.SID      = v_salle.SID
    AND s.DepID    = v_salle.DepID
    AND s.ScJour   = 'Lundi'
    AND s.ScCreneau = '08h-10h'
    AND ROWNUM = 1;   -- <-- évite ORA-01422 s'il existe plusieurs lignes

  COMMIT;

  DBMS_OUTPUT.PUT_LINE(CHR(10) || '========================================');
  DBMS_OUTPUT.PUT_LINE('   TESTS PERSONNE_TYPE (via un etudiant)');
  DBMS_OUTPUT.PUT_LINE('========================================');

  v_personne := TREAT(v_etudiant AS Personne_Type);

  DBMS_OUTPUT.PUT_LINE('afficherNomComplet (Personne_Type) = ' ||
                       v_personne.afficherNomComplet());

  DBMS_OUTPUT.PUT_LINE('calculerAge (Personne_Type) = ' ||
                       v_personne.calculerAge() || ' ans');

  v_personne.modifierContact('0555000000','test.contact@univ.dz','Adresse modifiee');
  DBMS_OUTPUT.PUT_LINE('modifierContact effectue pour Personne_Type');

  DBMS_OUTPUT.PUT_LINE(CHR(10) || '========================================');
  DBMS_OUTPUT.PUT_LINE('   TESTS ETUDIANT_TYPE');
  DBMS_OUTPUT.PUT_LINE('========================================');

  DBMS_OUTPUT.PUT_LINE('afficherInfos = ' || v_etudiant.afficherInfos());
  DBMS_OUTPUT.PUT_LINE('afficherNomComplet (override) = ' ||
                       v_etudiant.afficherNomComplet());
  DBMS_OUTPUT.PUT_LINE('payerFrais(5000) = ' || v_etudiant.payerFrais(5000));
  DBMS_OUTPUT.PUT_LINE('verifierBourse = ' || v_etudiant.verifierBourse());

  -- changerNiveau : on sauvegarde le statut, on change, puis on remet
  SELECT Statut INTO v_old_statut
  FROM Etudiants
  WHERE EtID = v_etudiant.EtID;

  v_etudiant.changerNiveau('Suspendu');
  DBMS_OUTPUT.PUT_LINE('changerNiveau -> Suspendu');

  v_etudiant.changerNiveau(v_old_statut);
  DBMS_OUTPUT.PUT_LINE('changerNiveau -> retour a ' || v_old_statut);

  -- inscrire : on ajoute une nouvelle seance
  v_etudiant.inscrire(
    v_enseignant.EnsID,
    'TD',
    'Mardi',
    '10h-12h',
    'Inscription test TD',
    v_salle.SID
  );
  DBMS_OUTPUT.PUT_LINE('inscrire : seance TD ajoutee pour letudiant');

  DBMS_OUTPUT.PUT_LINE(CHR(10) || '========================================');
  DBMS_OUTPUT.PUT_LINE('   TESTS ENSEIGNANT_TYPE');
  DBMS_OUTPUT.PUT_LINE('========================================');

  DBMS_OUTPUT.PUT_LINE('afficherInfos = ' || v_enseignant.afficherInfos());
  DBMS_OUTPUT.PUT_LINE('afficherNomComplet (override) = ' ||
                       v_enseignant.afficherNomComplet());
  DBMS_OUTPUT.PUT_LINE('calculerAnciennete = ' ||
                       v_enseignant.calculerAnciennete() || ' ans');

  -- modifierGrade : on sauvegarde puis on remet
  SELECT Titre INTO v_old_titre
  FROM Enseignants
  WHERE EnsID = v_enseignant.EnsID;

  v_enseignant.modifierGrade('Grade Test');
  DBMS_OUTPUT.PUT_LINE('modifierGrade -> Grade Test');

  v_enseignant.modifierGrade(v_old_titre);
  DBMS_OUTPUT.PUT_LINE('modifierGrade -> retour a ' || v_old_titre);

  -- ajouterSeance
  v_enseignant.ajouterSeance(
    v_etudiant.EtID,
    'Cours',
    'Mercredi',
    '14h-16h',
    'Cours test par enseignant',
    v_salle.SID,
    v_salle.DepID
  );
  DBMS_OUTPUT.PUT_LINE('ajouterSeance : seance ajoutee');

  -- afficherPlanning
  DBMS_OUTPUT.PUT_LINE('afficherPlanning :');
  cur := v_enseignant.afficherPlanning();
  LOOP
    FETCH cur INTO v_jour, v_creneau, v_sctype, v_desc, v_sid;
    EXIT WHEN cur%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('  ' || v_jour || ' ' || v_creneau ||
                         ' - ' || v_sctype || ' - ' || v_desc ||
                         ' (Salle ' || v_sid || ')');
  END LOOP;
  CLOSE cur;

  DBMS_OUTPUT.PUT_LINE(CHR(10) || '========================================');
  DBMS_OUTPUT.PUT_LINE('   TESTS DEPARTEMENT_TYPE');
  DBMS_OUTPUT.PUT_LINE('========================================');

  DBMS_OUTPUT.PUT_LINE('afficherInfos = ' || v_dept.afficherInfos());
  DBMS_OUTPUT.PUT_LINE('compterEtudiants = ' ||
                       v_dept.compterEtudiants());
  DBMS_OUTPUT.PUT_LINE('compterEnseignants = ' ||
                       v_dept.compterEnseignants());
  DBMS_OUTPUT.PUT_LINE('afficherChef = ' || v_dept.afficherChef());

  DBMS_OUTPUT.PUT_LINE('afficherMembres :');
  cur := v_dept.afficherMembres();
  LOOP
    FETCH cur INTO v_type, v_id, v_nom, v_prenom, v_email;
    EXIT WHEN cur%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('  [' || v_type || '] ' || v_id ||
                         ' - ' || v_nom || ' ' || v_prenom ||
                         ' <' || v_email || '>');
  END LOOP;
  CLOSE cur;

  DBMS_OUTPUT.PUT_LINE(CHR(10) || '========================================');
  DBMS_OUTPUT.PUT_LINE('   TESTS SALLE_TYPE');
  DBMS_OUTPUT.PUT_LINE('========================================');

  DBMS_OUTPUT.PUT_LINE('afficherInfos = ' || v_salle.afficherInfos());

  v_tmp := v_salle.verifierDisponibilite('Jeudi','08h-10h');
  DBMS_OUTPUT.PUT_LINE('verifierDisponibilite(Jeudi, 08h-10h) = ' || v_tmp);

  DBMS_OUTPUT.PUT_LINE('ajouterReservation :');
  v_salle.ajouterReservation(
    v_enseignant.EnsID,
    v_etudiant.EtID,
    'TD',
    'Jeudi',
    '08h-10h',
    'Reservation test'
  );
  DBMS_OUTPUT.PUT_LINE('  Reservation ajoutee');

  DBMS_OUTPUT.PUT_LINE('afficherOccupation :');
  cur := v_salle.afficherOccupation();
  LOOP
    FETCH cur INTO v_jour, v_creneau, v_sctype, v_desc, v_id;
    EXIT WHEN cur%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('  ' || v_jour || ' ' || v_creneau ||
                         ' - ' || v_sctype || ' - ' || v_desc ||
                         ' (EnsID ' || v_id || ')');
  END LOOP;
  CLOSE cur;

  DBMS_OUTPUT.PUT_LINE('calculerTauxOccupation = ' ||
                       v_salle.calculerTauxOccupation() || ' %');

  DBMS_OUTPUT.PUT_LINE(CHR(10) || '========================================');
  DBMS_OUTPUT.PUT_LINE('   TESTS SEANCE_TYPE');
  DBMS_OUTPUT.PUT_LINE('========================================');

  DBMS_OUTPUT.PUT_LINE('afficherInfos = ' || v_seance.afficherInfos());

  -- changerHoraire puis retour a l'horaire initial
  v_seance.changerHoraire('Dimanche','16h-18h');
  DBMS_OUTPUT.PUT_LINE('changerHoraire -> Dimanche 16h-18h');

  v_seance.changerHoraire('Lundi','08h-10h');
  DBMS_OUTPUT.PUT_LINE('changerHoraire -> retour Lundi 08h-10h');

  -- ajouterEtudiant (on suppose qu'un autre etudiant existe)
  BEGIN
    DECLARE
      v_autre_etud Etudiant_Type;
    BEGIN
      SELECT VALUE(e)
      INTO v_autre_etud
      FROM Etudiants e
      WHERE e.EtID <> v_etudiant.EtID
        AND ROWNUM = 1;

      v_seance.ajouterEtudiant(v_autre_etud.EtID);
      DBMS_OUTPUT.PUT_LINE('ajouterEtudiant : etudiant ' ||
                           v_autre_etud.EtID || ' ajoute a la seance');
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('ajouterEtudiant : aucun autre etudiant trouve, test saute');
    END;
  END;

  -- afficherParticipants
  DBMS_OUTPUT.PUT_LINE('afficherParticipants :');
  cur := v_seance.afficherParticipants();
  LOOP
    FETCH cur INTO v_id, v_nom, v_prenom, v_email;
    EXIT WHEN cur%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('  Etudiant ' || v_id || ' - ' ||
                         v_nom || ' ' || v_prenom ||
                         ' <' || v_email || '>');
  END LOOP;
  CLOSE cur;

  -- annulerSeance (sur la seance de test que nous avons cree)
  v_seance.annulerSeance();
  DBMS_OUTPUT.PUT_LINE('annulerSeance : seance de test annulee');

  DBMS_OUTPUT.PUT_LINE(CHR(10) || '========================================');
  DBMS_OUTPUT.PUT_LINE('  FIN DES TESTS DES METHODES OBJET');
  DBMS_OUTPUT.PUT_LINE('========================================');

END;
/
