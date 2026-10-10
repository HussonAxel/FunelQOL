# Audit de performances — 10 octobre 2026

Les optimisations sont appliquées et les tests locaux passent. **Aucune mesure CPU/FPS dans le client WoW n'a été réalisée pendant cet audit.** Les résultats ci-dessous portent sur les appels du code réel avec une UI simulée, et sur les données Lua importées. Ils ne permettent pas de promettre un gain de FPS ou « l'addon le plus performant ».

## Résultats avant / après

Le scénario d'événements utilise deux panneaux : quêtes et contenu statique. Les producteurs de lignes sont simulés ; le routage des événements, les handlers QuestXP et le rendu Panels sont réels. Une rafale comprend 100 couples QUEST_LOG_UPDATE / UNIT_AURA(player), suivis de l'exécution des callbacks différés.

| Mesure locale | Avant | Après |
| --- | ---: | ---: |
| Callbacks différés pour la rafale | 2 | 1 |
| Rendus des quêtes pour la rafale | 2 | 1 |
| Rendus du panneau statique pour la rafale | 1 | 0 |
| Rendus après événement quête/aura, panneau quête désactivé | 3 | 0 |
| Appels du suivi OnUpdate au repos, 600 images simulées | 600 | 0 |
| Rendus statiques sur un tick de quête chronométrée | 1 | 0 |
| Nouvelles frames sur 1 000 rendus après échauffement | 0 | 0 |
| Mémoire initiale RareData, Lua 5.4 après GC | 3 951,7 Kio | 1 598,4 Kio |
| Nombre de cartes / rares disponibles | 333 / 3 400 | 333 / 3 400 |

Le gain mémoire initial pour RareData est de **2 353,3 Kio, soit 59,6 %**. Après la première utilisation du panneau Rares, la mémoire totale revient à environ 3 974 Kio : il s'agit d'une allocation différée, pas d'une suppression des données. Le bytecode et les constantes du fichier restent chargés dès le démarrage. Si un panneau Rares est déjà actif à la connexion, les tables sont créées immédiatement et ce gain au repos ne s'applique pas.

Les durées des 1 000 rendus simulés ont varié d'une exécution à l'autre. Elles sont affichées par le test pour observation, sans assertion de temps ni pourcentage de gain CPU : les méthodes graphiques simulées et leur allocation ne reproduisent pas le coût du moteur WoW.

## Modifications

- QuestXP et RaidCollection partagent la file de rafraîchissement des panneaux. Les événements qui se chevauchent ne créent plus deux files indépendantes.
- Les rafraîchissements concernent les contenus pertinents. Argent, monnaies, métiers, renoms, chambre forte et cartes de défi ont un routage explicite.
- Les panneaux désactivés ne sont pas rendus par les événements. Les modifications explicites de configuration/layout conservent leur mise à jour, et le mode édition continue à les afficher.
- Le suivi OnUpdate est caché quand aucune quête chronométrée ni analyse d'équipement en attente ne l'utilise. Les événements restent reçus sur cette frame cachée.
- Les flags de suivi sont mémorisés par panneau et agrégés après rendu : une mise à jour partielle peut arrêter un timer devenu inutile, sans perdre l'attente d'un autre panneau.
- Un tick de suivi ne rend que les quêtes et/ou les contenus raid concernés.
- La file est vidée avant le rendu pour conserver les nouveaux événements éventuellement déclenchés pendant celui-ci.
- Le hook UIParent:SetScale ignore ses arguments avant de demander un rendu complet.
- RareData crée ses tables à la première demande puis libère sa fonction de chargement. Le script d'import génère désormais ce format. Les anciennes données importées restent compatibles ; les réimporter permet de bénéficier du chargement différé.
- Correction d'un défaut découvert par la suite existante : un emplacement de chambre forte débloqué, dont le niveau d'objet n'est pas encore chargé, ne reçoit plus une légende de progression de remplacement.

## Vérification locale

Depuis le dossier FunelQOL :

```powershell
python tools/Run-Tests.py
```

Environnement : Python 3.13, lupa 2.8, Windows. Le runner compile les fichiers de l'addon et de ses bibliothèques en Lua 5.1 ; les mocks utilisent Lua 5.4 pour leur bibliothèque utf8. Dépendance de l'outil : `python -m pip install lupa` si elle n'est pas installée.

Neuf fichiers de tests passent : delve-leveling, performance-data, performance, profiling, quest-xp, raid-achievements, raid-collection-integration, raid-collection et smoke. Le test des données de rares est ignoré si le fichier importé est absent.

Le grand smoke test dépassait déjà 200 variables locales dans son bloc principal. Un bloc de test a été isolé ; les méthodes de texture manquantes du mock ont été ajoutées. Une attente d'arrondi est désormais fondée sur string.format, et le GUID simulé du trésor utilise le bon nombre de champs. Les autres assertions sont conservées.

## Mesure dans WoW

Après `/reload`, les commandes suivantes sont disponibles. Elles ne créent aucun ticker, frame d'événements ou hook de profilage permanent.

```text
/funelqol perf start repos
... jouer le scénario pendant 60 secondes ...
/funelqol perf stop
/funelqol perf report
/funelqol perf bench 5
```

`start` et `stop` lisent le profiler natif et actualisent la mémoire uniquement aux deux bornes. `report` réaffiche le dernier résultat. Les dix derniers scénarios et le dernier benchmark sont conservés dans FunelQOLDB.performance, écrit sur disque par WoW à la déconnexion ou au reload. Un scénario en cours est abandonné au reload.

`bench` mesure de 1 à 20 appels de RefreshPanels avec C_AddOnProfiler.MeasureCall : temps moyen, maximum et allocations moyennes. Il s'exécute hors combat, de manière synchrone, et provoque des rendus complets réels ; commencer par 5 appels. Il mesure les panneaux actuels, y compris la préparation des données et les appels UI. Son coût ne représente pas la consommation habituelle par image.

Scénarios à comparer, avec le même personnage, le même layout, les mêmes addons et les mêmes limites FPS :

1. Repos 60 s, sans quête chronométrée ni chargement d'équipement ; panneau Rares absent puis activé.
2. Ouverture/fermeture de la carte et rafales de changements de quêtes pendant 60 s.
3. Quête chronométrée, puis fin/abandon : vérifier que le suivi s'arrête.
4. Combat pendant plusieurs minutes, avec buffs et téléportations affichés.
5. Entrée/sortie de raid, collection et analyse native des améliorations/catalyses ; comparer chargement à froid et cache chaud.
6. Mode édition, changement de layout et panneaux désactivés : vérifier titres, dimensions, ancrages et retour à l'état masqué.

Comparer les différences de compteurs >1/>5/>10/>50 ms sur des durées égales. La moyenne de session et le pic concernent toute la session depuis le reload ; la moyenne récente concerne les 60 derniers ticks du profiler, pas 60 secondes ni nécessairement tout le scénario. Les variations mémoire incluent le GC naturel : elles ne constituent pas à elles seules une mesure des allocations ou une preuve de fuite.

Le profiler natif a des limites d'attribution : des chemins déclenchés par Blizzard et plusieurs handlers de souris ne sont pas couverts. Utiliser MeasureCall pour mesurer explicitement le rendu et examiner séparément les interactions. Aucun changement de scriptProfile, aucun ResetCPUUsage et aucun GC forcé ne sont effectués par les commandes en jeu.

## Passe 0.18.10

Changements FunelQOL (non mesurés en jeu, couverts par les tests hors client) :

- RotationButton : les rafales d'événements de raccourcis (`ACTIONBAR_SLOT_CHANGED`, `UPDATE_BINDINGS`…) déclenchent un seul rescan à l'image suivante, au lieu d'un rescan par événement. La validation de la configuration n'a lieu qu'une fois par table.
- QuestXP : `UNIT_AURA` et `PLAYER_XP_UPDATE` utilisent [RegisterUnitEvent](https://warcraft.wiki.gg/wiki/API_Frame_RegisterUnitEvent) sur `player` : le client filtre les autres unités avant Lua.
- Panels : `GET_ITEM_INFO_RECEIVED` ([payload itemID, success](https://warcraft.wiki.gg/wiki/GET_ITEM_INFO_RECEIVED), émis pour les requêtes de tous les addons) n'invalide plus les actions de raid. Le rendu complet est réservé aux objets réellement attendus par Rares/Raid. `SUPER_TRACKING_PATH_UPDATED` ne rafraîchit plus que les quêtes. Les valeurs par défaut des panneaux sont mises en cache.
- Téléportations : le calcul des cooldowns n'alloue plus de closure `pcall` ; les secrets sont exclus par `issecretvalue`.
- Rares : un nom introuvable est redemandé au plus toutes les 5 s.
- Collection de raid : l'éditeur de catégories est construit une seule fois puis réutilisé.

Changements RefineUI (copie locale ; sauvegarde `C:\Users\aaaxe\AddOnBackups\RefineUI-20261010-221858.tar.gz`) :

- Menace des nameplates : les retours de `UnitThreatSituation` et `UnitThreatLeadSituation` sont ignorés s'ils sont secrets, au lieu d'être comparés.
- Nameplates : `UNIT_FLAGS`/`UNIT_FACTION` ignorent les tokens hors `nameplateN`, puisque la plaque reçoit déjà son propre événement.
- API d'objets : `GetItemInfo`, `GetItemInfoInstant`, `GetItemSubClassInfo`, `GetItemQualityColor`, `GetDetailedItemLevelInfo` et `IsUsableItem` passent par `C_Item` quand il existe ([dépréciés en 10.2.6](https://warcraft.wiki.gg/wiki/API_GetItemInfo)).
- Portails : le cooldown du favori ne s'actualise que s'il est visible ; la reconstruction sécurisée du favori est regroupée par rafale (0,25 s).
- Liste des expéditions : `QUEST_LOG_UPDATE` n'invalide les caches que si la carte est ouverte. La fermeture de la carte les invalide déjà.
- Micro-menu : la latence n'est réécrite que si elle a changé.

Non traité volontairement : filtrage des cooldowns de téléportation par spellID, caches d'icônes/obtention des rares, debounce des pins de carte, retrait de `CRITERIA_UPDATE` des gouffres, et côté RefineUI les changements de visibilité/taille des nameplates, BuffReminder par unité et le préchargement des pools du sac. Ces points ont un gain incertain ou présentent un risque fonctionnel sans mesure en jeu.

## Sources et pistes restantes

- [Index API Warcraft Wiki](https://warcraft.wiki.gg/wiki/World_of_Warcraft_API).
- [C_AddOnProfiler.GetAddOnMetric](https://warcraft.wiki.gg/wiki/API_C_AddOnProfiler.GetAddOnMetric) : métriques en millisecondes, activation sans scriptProfile, remise à zéro au reload et limites d'attribution.
- [C_AddOnProfiler.MeasureCall](https://warcraft.wiki.gg/wiki/API_C_AddOnProfiler.MeasureCall) : elapsedMilliseconds et allocatedBytes par appel.
- [GetAddOnMemoryUsage](https://warcraft.wiki.gg/wiki/API_GetAddOnMemoryUsage) : valeur en Kio, mise à jour par UpdateAddOnMemoryUsage.
- [OnUpdate](https://warcraft.wiki.gg/wiki/UIHANDLER_OnUpdate) : exécution à chaque image ; cacher la frame interrompt ces appels.

Une extension de données chargée à la demande pourrait également différer le parsing et les constantes de RareData, au prix d'un dossier compagnon et de modifications d'installation/import. Les caches supplémentaires pour les téléportations, les tooltips ou les mises en page demandent d'abord des mesures client : leur invalidation ajoute du code et peut rendre les données obsolètes. Ces pistes restent à évaluer à partir des résultats en jeu.
