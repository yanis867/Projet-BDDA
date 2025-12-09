vue pour tous les étudiants (bd admin)

CREATE OR REPLACE VIEW Etudiant_Global AS
SELECT
    V.EtID,
    V.Nom,
    V.Prenom,
    V.DateNais,
    V.Adr,
    V.Tel,
    V.Email,
    V.Nss,
    V.VilleNais,
    V.PrenomPere,
    V.Mere,
    H.DepID,
    H.DateInsc,
    H.Statut,
    H.Bac,
    H.Bourse
FROM
    etudiants_admin V
JOIN
    etudiants_Info@link_info H
ON
    V.EtID = H.EtID

UNION ALL

SELECT
    V.EtID,
    V.Nom,
    V.Prenom,
    V.DateNais,
    V.Adr,
    V.Tel,
    V.Email,
    V.Nss,
    V.VilleNais,
    V.PrenomPere,
    V.Mere,
    H.DepID,
    H.DateInsc,
    H.Statut,
    H.Bac,
    H.Bourse
FROM
    etudiants_admin V
JOIN
    etudiants_Math@link_maths H
ON
    V.EtID = H.EtID;

vue pour les étudiants dans le dept info (bd info)

CREATE VIEW V_Etudiant_Info AS
SELECT *
FROM etudiant_global@link_admin
WHERE DepID = 1;

vue pour les étudiants dans le dept math (bd math)

CREATE VIEW V_Etudiant_Math AS
SELECT *
FROM etudiant_global@link_admin
WHERE DepID = 2;





vue enseignant_global

CREATE OR REPLACE VIEW Enseignant_Global AS
SELECT
    V.EnsID,
    V.Nom,
    V.Prenom,
    V.DateNais,
    V.Adr,
    V.Tel,
    V.EMail,
    V.Nss,
    V.EtatCivil,
    H.Daterect,
    H.Spec,
    H.Titre,
    H.DepID
FROM
    enseignant_admin V
JOIN
    enseignant_Info@link_info H
ON
    V.EnsID = H.EnsID

UNION ALL

SELECT
    V.EnsID,
    V.Nom,
    V.Prenom,
    V.DateNais,
    V.Adr,
    V.Tel,
    V.EMail,
    V.Nss,
    V.EtatCivil,
    H.Daterect,
    H.Spec,
    H.Titre,
    H.DepID
FROM
    enseignant_admin V
JOIN
    enseignant_Math@link_maths H
ON
    V.EnsID = H.EnsID;