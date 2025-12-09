trigger d'insertion dans admin (utilisateur agent)

CREATE OR REPLACE TRIGGER TRG_Etudiant_Global
INSTEAD OF INSERT ON Etudiant_Global
FOR EACH ROW
BEGIN
    INSERT INTO etudiants_admin@link_univ (
        EtID, Nom, Prenom, DateNais, Adr, Tel, Email, Nss, VilleNais, PrenomPere, Mere
    ) VALUES (
        :NEW.EtID, :NEW.Nom, :NEW.Prenom, :NEW.DateNais,
        :NEW.Adr, :NEW.Tel, :NEW.Email, :NEW.Nss, :NEW.VilleNais, :NEW.PrenomPere, :NEW.Mere
    );

    IF :NEW.DepID = 1 THEN
        -- Département Informatique
        INSERT INTO etudiants_info@link_info (
            EtID, DateInsc, Bac, Statut, Bourse, DepID
        ) VALUES (
            :NEW.EtID, :NEW.DateInsc, :NEW.Bac, :NEW.Statut, :NEW.Bourse, :NEW.DepID
        );

    ELSIF :NEW.DepID = 2 THEN
        -- Département Mathématiques
        INSERT INTO etudiants_math@link_math (
            EtID, DateInsc, Bac, Statut, Bourse, DepID
        ) VALUES (
            :NEW.EtID, :NEW.DateInsc, :NEW.Bac, :NEW.Statut, :NEW.Bourse, :NEW.DepID
        );

    ELSE
        RAISE_APPLICATION_ERROR(-20002,
            'DepID inconnu pour étudiant');
    END IF;

END;

test trigger:

INSERT INTO Etudiant_Global (
    EtID, Nom, Prenom, DateNais, Adr, Tel, Email, Nss, VilleNais, PrenomPere, Mere, DepID, DateInsc, Statut, Bac, Bourse
)
VALUES (
    140, 'test', 'essai', DATE '2002-01-28', 'Alger',
    '066100000000', 'karim@gmail.com', '998877', 'frankfurt', 'kaddour', 'zoulikha', 1, DATE '2024-09-10', 'Inscrit', 2022, 'Oui'
);