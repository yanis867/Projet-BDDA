-- 00_dummy_data.sql
-- Script de peuplement de la base de données (Données de test)
-- Noms algériens et structure Objet-Relationnelle (Refactored)
-- À EXÉCUTER SUR LE SITE 1 (SIÈGE) AVANT LA FRAGMENTATION

-- ===========================================================================
-- 1. DEPARTEMENTS (Insertion initiale sans Chef pour éviter cycle)
-- ===========================================================================
INSERT INTO Departements VALUES (T_Departement(1, 'Informatique', NULL));
INSERT INTO Departements VALUES (T_Departement(2, 'Mathématiques', NULL));

COMMIT;

-- ===========================================================================
-- 2. SALLES
-- ===========================================================================
-- Dept Info (1)
INSERT INTO Salles VALUES (
    T_Salle(T_ID_Salle(1, 1), 'Cours', 'Salle 101', 30, '1er', 'Bloc A')
);
INSERT INTO Salles VALUES (
    T_Salle(T_ID_Salle(2, 1), 'TP', 'Labo 1', 20, '1er', 'Bloc A')
);
INSERT INTO Salles VALUES (
    T_Salle(T_ID_Salle(3, 1), 'Amphi', 'Amphi A', 100, 'RDC', 'Bloc Central')
);

-- Dept Maths (2)
INSERT INTO Salles VALUES (
    T_Salle(T_ID_Salle(1, 2), 'Cours', 'Salle 201', 30, '2eme', 'Bloc B')
);
INSERT INTO Salles VALUES (
    T_Salle(T_ID_Salle(2, 2), 'TD', 'Salle 202', 25, '2eme', 'Bloc B')
);
INSERT INTO Salles VALUES (
    T_Salle(T_ID_Salle(3, 2), 'Amphi', 'Amphi B', 120, 'RDC', 'Bloc Central')
);

COMMIT;

-- ===========================================================================
-- 3. ENSEIGNANTS (Table Enseignants)
-- ===========================================================================

-- Dept Info (DepID=1)
INSERT INTO Enseignants VALUES (
    T_Enseignant(
        101, 'BENALI', 'Ahmed', TO_DATE('1975-04-12', 'YYYY-MM-DD'), 'Oran', '0555123456', 'a.benali@univ.dz', '123456789',
        'Marié', TO_DATE('2005-09-01', 'YYYY-MM-DD'), 'IA', 'Professeur',
        (SELECT REF(d) FROM Departements d WHERE d.DepID = 1),
        1 -- FK DepID
    )
);

INSERT INTO Enseignants VALUES (
    T_Enseignant(
        102, 'SAIDI', 'Karim', TO_DATE('1982-11-23', 'YYYY-MM-DD'), 'Alger', '0550987654', 'k.saidi@univ.dz', '987654321',
        'Célibataire', TO_DATE('2010-09-01', 'YYYY-MM-DD'), 'Réseaux', 'MAA',
        (SELECT REF(d) FROM Departements d WHERE d.DepID = 1),
        1
    )
);

-- Dept Maths (DepID=2)
INSERT INTO Enseignants VALUES (
    T_Enseignant(
        103, 'ZERROUKI', 'Fatima', TO_DATE('1978-06-15', 'YYYY-MM-DD'), 'Constantine', '0777112233', 'f.zerrouki@univ.dz', '1122334455',
        'Mariée', TO_DATE('2008-09-01', 'YYYY-MM-DD'), 'Algèbre', 'MAB',
        (SELECT REF(d) FROM Departements d WHERE d.DepID = 2),
        2
    )
);

INSERT INTO Enseignants VALUES (
    T_Enseignant(
        104, 'TOUMI', 'Mohamed', TO_DATE('1985-02-10', 'YYYY-MM-DD'), 'Setif', '0661223344', 'm.toumi@univ.dz', '5566778899',
        'Marié', TO_DATE('2012-09-01', 'YYYY-MM-DD'), 'Analyse', 'MCA',
        (SELECT REF(d) FROM Departements d WHERE d.DepID = 2),
        2
    )
);

COMMIT;

-- ===========================================================================
-- 4. MISE A JOUR DES DEPARTEMENTS (Assignation des Chefs)
-- ===========================================================================
UPDATE Departements d
SET d.Chef = (SELECT REF(p) FROM Enseignants p WHERE p.ID = 101)
WHERE d.DepID = 1;

UPDATE Departements d
SET d.Chef = (SELECT REF(p) FROM Enseignants p WHERE p.ID = 103)
WHERE d.DepID = 2;

COMMIT;

-- ===========================================================================
-- 5. ETUDIANTS (Table Etudiants)
-- ===========================================================================

-- Dept Info (DepID=1)
INSERT INTO Etudiants VALUES (
    T_Etudiant(
        201, 'MANSOURI', 'Amine', TO_DATE('2003-05-20', 'YYYY-MM-DD'), 'Blida', '0541000001', 'amine.m@univ-usto.dz', 'ETU001',
        TO_DATE('2021-09-15', 'YYYY-MM-DD'), '2021', 'Actif', 'Oui',
        (SELECT REF(d) FROM Departements d WHERE d.DepID = 1),
        1 -- FK DepID
    )
);
INSERT INTO Etudiants VALUES (
    T_Etudiant(
        202, 'DAHMANE', 'Sarah', TO_DATE('2004-01-15', 'YYYY-MM-DD'), 'Tipaza', '0541000002', 'sarah.d@univ-usto.dz', 'ETU002',
        TO_DATE('2022-09-15', 'YYYY-MM-DD'), '2022', 'Actif', 'Non',
        (SELECT REF(d) FROM Departements d WHERE d.DepID = 1),
        1
    )
);
INSERT INTO Etudiants VALUES (
    T_Etudiant(
        203, 'BOUZIDI', 'Yacine', TO_DATE('2002-12-10', 'YYYY-MM-DD'), 'Boumerdes', '0541000003', 'yacine.b@univ-usto.dz', 'ETU003',
        TO_DATE('2020-09-15', 'YYYY-MM-DD'), '2020', 'Diplômé', 'Oui',
        (SELECT REF(d) FROM Departements d WHERE d.DepID = 1),
        1
    )
);

-- Dept Maths (DepID=2)
INSERT INTO Etudiants VALUES (
    T_Etudiant(
        204, 'BRAHIMI', 'Leila', TO_DATE('2003-08-05', 'YYYY-MM-DD'), 'Alger', '0555000001', 'leila.b@univ-usto.dz', 'ETU004',
        TO_DATE('2021-09-15', 'YYYY-MM-DD'), '2021', 'Actif', 'Oui',
        (SELECT REF(d) FROM Departements d WHERE d.DepID = 2),
        2
    )
);
INSERT INTO Etudiants VALUES (
    T_Etudiant(
        205, 'KHALDI', 'Omar', TO_DATE('2004-03-22', 'YYYY-MM-DD'), 'Oran', '0555000002', 'omar.k@univ-usto.dz', 'ETU005',
        TO_DATE('2022-09-15', 'YYYY-MM-DD'), '2022', 'Actif', 'Non',
        (SELECT REF(d) FROM Departements d WHERE d.DepID = 2),
        2
    )
);

COMMIT;

-- ===========================================================================
-- 6. SEANCES
-- ===========================================================================

-- Cours Info
INSERT INTO Seances VALUES (1, 101, 201, 3, 'Cour', 'Lundi', '08:30', 'Introduction IA');
INSERT INTO Seances VALUES (2, 101, 202, 3, 'Cour', 'Lundi', '08:30', 'Introduction IA');

INSERT INTO Seances VALUES (3, 102, 201, 1, 'Tp', 'Mardi', '10:15', 'TP Réseaux');

-- Maths
INSERT INTO Seances VALUES (4, 103, 204, 3, 'Cour', 'Mercredi', '09:00', 'Algèbre Linéaire');
INSERT INTO Seances VALUES (5, 104, 205, 2, 'Td', 'Jeudi', '11:00', 'TD Analyse');

COMMIT;
