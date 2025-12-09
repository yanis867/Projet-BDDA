# Mini Projet BDDA
## Implémentation et gestion d'une base de données répartie Oracle - Approche Top-down
### 1. Environement de travail
#### Machine Physique
- Système d'exploitation : Linux Mint 22.2 (zara)
- architecture : x86 - 64 Bits
- Logiciel VM : Oracle VirtualBox 7.0.16
#### Site 1, 2 & 3
- Système d'expoitation : Windows XP Professional SP3
- Architecture : x86 - 32 Bits
- SGBD : Oracle 10g

#### Note
> Le site 1 (Siège Principal) est installé sur VM au lieu de la machine physique. J'ai eu des difficultés de configuration du SGBD sur Linux Mint.

### 2. Configuration
|site   |@ IP           |BDD        |Utilisateurs       |
|-      |-              |-          |-                  |
|site 1 |192.168.56.1   |Etudiant   |admin_global, Agent|
|site 2 |192.168.56.10  |BdInfo     |AgentInfo          |
|site 3 |192.168.56.11  |BdMaths    |AgentMaths         |

### 3. Schéma Relationnel

#### Note
> Il y a une dépendance circulaire entre Département et Enseignant. Pour résoudre cela je crée d'abord la table Département Sans FK, puis la table Enseignant, après je mis à jour la table Département avec la FK.

#### Table Département
``` SQL
CREATE TABLE Departement (
    DepID NUMBER NOT NULL,
    DepDesig VARCHAR2(100),
    EnsID NUMBER, -- Sera lié apres création de la table Enseignant
    CONSTRAINT pk_departement PRIMARY KEY (DepID)
);
```

#### Table Enseignant
``` SQL
CREATE TABLE Enseignant (
    EnsID NUMBER NOT NULL,
    EnsNom VARCHAR2(50),
    EnsPrenom VARCHAR2(50),
    EnsDatenais DATE,
    Ensadr VARCHAR2(100),
    Enstel VARCHAR2(20),
    EnsMail VARCHAR2(100),
    EnsNss VARCHAR2(50),
    EnsEtatCivil VARCHAR2(20),
    EnsDaterect DATE,
    EnsSpec VARCHAR2(50),
    EnsTitre VARCHAR2(50),
    DepID NUMBER,
    CONSTRAINT pk_enseignant PRIMARY KEY (EnsID),
    CONSTRAINT fk_ens_dept FOREIGN KEY (DepID) REFERENCES Departement(DepID)
);
```

#### Mise à jour de la table Département
```SQL
ALTER TABLE Departement ADD CONSTRAINT fk_dept_chef FOREIGN KEY (EnsID) REFERENCES Enseignant(EnsID);
```

#### Table Étudiant
``` SQL
CREATE TABLE Etudiant (
    EtID NUMBER NOT NULL,
    EtNom VARCHAR2(50),
    EtPrenom VARCHAR2(50),
    EtDatenais DATE,
    EtVillenais VARCHAR2(50),
    EtPrenom_Pere VARCHAR2(50),
    EtMere VARCHAR2(50),
    EtAdr VARCHAR2(100),
    EtTel VARCHAR2(20),
    Etemail VARCHAR2(100),
    ETNss VARCHAR2(50),
    EtDateInsc DATE,
    EtBac VARCHAR2(4),
    EtStatut VARCHAR2(20),
    EtBourse VARCHAR2(20),
    DepID NUMBER,
    CONSTRAINT pk_etudiant PRIMARY KEY (EtID),
    CONSTRAINT fk_etudiant_dept FOREIGN KEY (DepID) REFERENCES Departement(DepID),
    CONSTRAINT chk_etudiant_statut CHECK (EtStatut IN ('Actif', 'Diplômé', 'Abandonné'))
);
```

#### Table Salle
``` SQL
CREATE TABLE Salle (
    SID NUMBER NOT NULL,
    DepID NUMBER NOT NULL,
    SType VARCHAR2(20),
    Snom VARCHAR2(50),
    SNbPlaces NUMBER,
    Setage VARCHAR2(20),
    Sbloc VARCHAR2(20),
    CONSTRAINT pk_salle PRIMARY KEY (SID, DepID),
    CONSTRAINT fk_salle_dept FOREIGN KEY (DepID) REFERENCES Departement(DepID),
    CONSTRAINT chk_salle_type CHECK (SType IN ('Emphi', 'Classe', 'Salle de TP'))
);
```

#### Table Séance
``` SQL
CREATE TABLE Seance (
    EnsID NUMBER NOT NULL,
    EtID NUMBER NOT NULL,
    ScType VARCHAR2(10),
    ScJour VARCHAR2(20),
    ScCreneau VARCHAR2(20),
    Descrip VARCHAR2(100),
    SID NUMBER,
    DepID NUMBER,
    CONSTRAINT pk_seance PRIMARY KEY (EnsID, EtID, ScType, ScJour, ScCreneau),
    CONSTRAINT fk_seance_ens FOREIGN KEY (EnsID) REFERENCES Enseignant(EnsID),
    CONSTRAINT fk_seance_etud FOREIGN KEY (EtID) REFERENCES Etudiant(EtID),
    -- La FK vers Salle doit inclure SID et DepID car la PK de Salle est composite
    CONSTRAINT fk_seance_salle FOREIGN KEY (SID, DepID) REFERENCES Salle(SID, DepID),
    CONSTRAINT chk_seance_type CHECK (ScType IN ('Cour', 'Td', 'Tp'))
);
```
### 4. Modélisation des données
#### Diagramme UML
<img src="./Diagrammes/Untitled Diagram.drawio.svg">

#### Implémentation des Types Objets
Il faut dabord créer des types incoplets pour eviter le problème de dépendence entre Département et Enseignant.
```SQL
CREATE TYPE T_Enseignant;
/
```

##### a. Département
```SQL
CREATE OR REPLACE TYPE T_Departement AS OBJECT (
    DepID       NUMBER,
    DepDesig    VARCHAR2(100),
    Chef        REF T_Enseignant,

    MEMBER FUNCTION afficherMembres RETURN SYS_REFCURSOR,
    MEMBER PROCEDURE ajouterMembre(p_type VARCHAR2, p_membre_id NUMBER),
    MEMBER FUNCTION compterEtudiants RETURN NUMBER,
    MEMBER FUNCTION compterEnseignants RETURN NUMBER,
    MEMBER FUNCTION afficherInfos RETURN VARCHAR2,
    MEMBER FUNCTION afficherChef RETURN VARCHAR2
);
/
```
##### b. Salle
- Clé composée de Salle
```SQL
CREATE OR REPLACE TYPE T_ID_Salle AS OBJECT (
    SID NUMBER,
    DepID NUMBER 
);
/
```
- Type salle
```SQL
CREATE TYPE T_Salle AS OBJECT (
    SalleID     T_ID_Salle,
    SType       VARCHAR2(20),
    Snom        VARCHAR2(50),
    SNbPlaces   NUMBER,
    Setage      VARCHAR2(20),
    Sbloc       VARCHAR2(20),
    MEMBER FUNCTION afficherOccupation RETURN SYS_REFCURSOR,
    MEMBER PROCEDURE ajouterReservation(p_EnsID NUMBER, p_EtID NUMBER, p_ScType VARCHAR2,
                                     p_ScJour VARCHAR2, p_ScCreneau VARCHAR2, p_Descrip VARCHAR2),
    MEMBER FUNCTION verifierDisponibilite(p_jour VARCHAR2, p_creneau VARCHAR2) RETURN VARCHAR2,
    MEMBER FUNCTION afficherInfos RETURN VARCHAR2,
    MEMBER FUNCTION calculerTauxOccupation RETURN NUMBER   
);
/
```

##### c. Personne
``` SQL
CREATE OR REPLACE TYPE T_Personne AS OBJECT (
    ID          NUMBER,
    Nom         VARCHAR2(50),
    Prenom      VARCHAR2(50),
    Datenais    DATE,
    Adr         VARCHAR2(100),
    Tel         VARCHAR2(20),
    Email       VARCHAR2(100),
    Nss         VARCHAR2(50),

    MEMBER FUNCTION afficherNomComplet RETURN VARCHAR2,
    MEMBER FUNCTION calculerAge RETURN NUMBER,
    MEMBER PROCEDURE modifierContact(p_tel VARCHAR2, p_email VARCHAR2, p_adr VARCHAR2)
) NOT FINAL;
/
```

##### d. Enseignant
```SQL
CREATE OR REPLACE TYPE T_Enseignant UNDER T_Personne (
    EnsEtatCivil VARCHAR2(50),
    EnsDaterect DATE,
    EnsSpec     VARCHAR2(50),
    EnsTitre    VARCHAR2(50),
    Departement REF T_Departement,

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
```

##### e. Etudiant
```SQL
CREATE OR REPLACE TYPE T_Etudiant UNDER T_Personne (
    EtDateInsc  DATE,
    EtBac       VARCHAR2(4),
    EtStatut    VARCHAR2(20),
    EtBourse    VARCHAR2(20),
    Departement REF T_Departement,

    MEMBER FUNCTION afficherInfos RETURN VARCHAR2,
    MEMBER PROCEDURE inscrire(p_EnsID NUMBER, p_ScType VARCHAR2, p_ScJour VARCHAR2,
                            p_ScCreneau VARCHAR2, p_Descrip VARCHAR2, p_SID NUMBER),
    MEMBER PROCEDURE changerNiveau(p_nouveau_statut VARCHAR2),
    MEMBER FUNCTION payerFrais(p_montant NUMBER) RETURN VARCHAR2,
    MEMBER FUNCTION verifierBourse RETURN VARCHAR2,
    OVERRIDING MEMBER FUNCTION afficherNomComplet RETURN VARCHAR2

);
/
```

#### Création des Tables Objets

##### Table pour stocker Département
```SQL
CREATE TABLE Departements OF T_Departement
    (CONSTRAINT pk_dept PRIMARY KEY (DepID));
```


##### Table pour stocker Personne, Enseignant & Etudiant
```SQL
CREATE TABLE Personnes OF T_Personne
    (
        CONSTRAINT pk_personne PRIMARY KEY (ID)
        -- Création d'un index pour les références (REF) (donne erreur, marche sans)
        --SCOPE FOR (Departement) IS Departements
    )
    -- Permet de stocker les sous-types (Etudiant, Enseignant)
    OBJECT IDENTIFIER IS PRIMARY KEY;
```

##### Mettre à jour la table Departement pour que la référence de Chef pointe vers Personnes
```SQL 
ALTER TABLE Departements ADD (
    SCOPE FOR (Chef) IS Personnes
);
```

##### Table pour stocker Salle
```SQL
CREATE TABLE Salles OF T_Salle
    -- La PK est un champ composite dans le type
    (CONSTRAINT pk_salle_obj PRIMARY KEY (SalleID.SID, SalleID.DepID));
```

##### Table Seance (Table d'Association)
```SQL
-- On utilise ici des REF pour pointer vers les objets Enseignant, Etudiant, Salle
-- CREATE TABLE Seances (
--     ScID        NUMBER PRIMARY KEY,
--     EnsRef      REF T_Enseignant REFERENCES Personnes,
--     EtudRef     REF T_Etudiant REFERENCES Personnes,
--     SalleRef    REF T_Salle REFERENCES Salles,
--     ScType      VARCHAR2(10),
--     ScJour      VARCHAR2(20),
--     ScCreneau   VARCHAR2(20),
--     Descrip     VARCHAR2(100),
--     -- Contrainte d'unicité sur l'ensemble pour éviter les doublons de planning
--     CONSTRAINT uq_seance UNIQUE (EnsRef, ScJour, ScCreneau, SalleRef)
-- );


CREATE TABLE Seances (
    ScID        NUMBER PRIMARY KEY,
    -- Remplacer REF T_Enseignant par EnsID (NUMBER)
    EnsID       NUMBER NOT NULL, 
    -- Remplacer REF T_Etudiant par EtudID (NUMBER)
    EtudID      NUMBER NOT NULL, 
    -- Remplacer REF T_Salle par SalleID (Le type T_ID_Salle était NUMBER, on prend juste l'ID)
    SalleID     NUMBER, 
    ScType      VARCHAR2(10),
    ScJour      VARCHAR2(20),
    ScCreneau   VARCHAR2(20),
    Descrip     VARCHAR2(100),
    -- Contrainte d'unicité utilisant les IDs (NUMBER)
    CONSTRAINT uq_seance UNIQUE (EnsID, ScJour, ScCreneau, SalleID), 
    -- Ajout des contraintes de clé étrangère (FK)
    -- L'EnsID et l'EtudID doivent exister dans la table Personnes
    CONSTRAINT fk_seance_ens_obj FOREIGN KEY (EnsID) REFERENCES Personnes (ID),
    CONSTRAINT fk_seance_etud_obj FOREIGN KEY (EtudID) REFERENCES Personnes (ID)
    -- NOTE : La FK vers Salle est plus complexe car Salle a une PK composite/objet.
    -- Si Salles a une PK simple (SID), cette FK fonctionnerait:
    -- CONSTRAINT fk_seance_salle FOREIGN KEY (SalleID) REFERENCES Salles (SID)
);
```
> **Note**: Executer ces requêtes sur les 3 sites.

#### Avantages de la modélisation orientée objet
- **Transparence & encapsulation**: Les objets peuvent être déplacés et utilisrs tant que unités complètes, ce qui garentit la cohérence.
- **Réutilisabilité & simpicité**: la modlélisation orientée objet permet de représenter les les entités complexes par objets apparant simples, mais qui supportent des données complexes. Ceci facilite le transfert des données entre les sites du système distribué.

### 5. Fragmentation & Distribution Top-Down
> **Note:** Avant de commencer la fragmentation, il faut d'abord créer les liens entre les sites. (voir [7. Liens inter-sites](#7-liens-inter-sites)).

#### 5.1.Fragmentation des Etudiants & Enseignants
Le type de fragmentation pour site 2 & 3 est la fragmentation mixte.
Pour site 1, verticale.
##### 5.1.a. Fragmentatioin Verticale
**Objectif**: Séparer les informations personnels des données métier.
- **Site 1**: stocker les données de l'objet `Personne`.
- **Site 2**: stocker les données de l'objet `Etudiant`.
- **Site 3**: stocker les données de l'objet `Enseignant`.

##### 5.1.b. Fragmentatioin Horizontale
**Objectif**: Distribuer les données métier sur les sites selon le departement.
- **Site 2**: `DepID = 1`.
- **Site 3**: `DepID = 2`.

#### 5.2 Fragmentation des Salles & Séances (Horizontale)
**Objectif**: Distribuer sur les sites selon le departement.
- **Site 2**: `DepID = 1`.
- **Site 3**: `DepID = 2`.





<hr>

### 6. Reconstitution

### 7. Liens inter-sites
``` SQL
ALTER SYSTEM SET GLOBAL_NAMES = FALSE;
```
#### Lien vers Departement informatique
``` SQL
CREATE DATABASE LINK link_to_info
CONNECT TO AgentInfo IDENTIFIED BY orcl867
USING 'BDINFO_SITE';
```
#### Lien vers Departement mathématique\n
``` SQL
CREATE DATABASE LINK link_to_maths
CONNECT TO AgentMaths IDENTIFIED BY orcl867
USING 'BDMATHS_SITE';
```
#### Pour tester les liens
``` SQL
SELECT * FROM dual@link_to_info;
SELECT * FROM dual@link_to_maths;
```

### 8. Automatisation & scheduler

### 9. Mesure & comparaison de temps de réponse

### 10. Questions