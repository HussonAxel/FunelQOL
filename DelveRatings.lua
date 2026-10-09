local _, addon = ...
-- User-supplied reference times and grades, not measured clear times.
-- Criteria IDs resolve Blizzard's localized story names. Unverified/renamed
-- stories deliberately have no criteria ID rather than an assumed mapping.
addon.delveRatings = {
    { name = "The Gulf of Memory", zone = "Harandar", achievementID = 61731, stories = {
        { "Sporasaur Special", "0:44.01", "S", 220587 },
        { "Alnmoth Munchies", "1:52.34", "D", 220586 },
        { "Descent of the Haranir", "2:14.10", "F", 220585 },
    } },
    { name = "The Darkway", zone = "Quel'Thalas", achievementID = 61728, stories = {
        { "Ogre Powered", "1:03.24", "A", 220571 },
        { "Eggsplosive Growth", "1:28.41", "B" },
        { "Focusers Under Pressure", "1:43.81", "C", 220569 },
        { "Leyline Technician", "2:04.70", "F", 220570 },
    } },
    { name = "The Ring of Glory", zone = "The Coiled Isle", achievementID = 63436, stories = {
        { "Adopt-a-thon", "1:06.29", "A", 230518 },
        { "Game Day", "1:35.81", "C", 230517 },
        { "Open Night", "1:38.01", "C", 230516 },
    } },
    { name = "Parhelion Plaza", zone = "Quel'Thalas", achievementID = 61725, stories = {
        { "Holding the Line", "1:07.72", "A", 220601 },
        { "Caustic Crush", "2:04.77", "F", 230850 },
        { "March of the Arcane Brigade", "2:46.21", "F", 220602 },
        { "Bombing Run", "3:06.51", "F", 220603 },
    } },
    { name = "Collegiate Calamity", zone = "Quel'Thalas", achievementID = 61726, stories = {
        { "Invasive Glow", "1:13.22", "A", 220589 },
        { "Academy Under Siege", "1:29.37", "B", 220590 },
        { "Faculty of Fear", "1:49.02", "D", 220591 },
        { "An Elementary Anditode", "1:56.90", "D" },
    } },
    { name = "Twilight Crypts", zone = "Zul'Aman", achievementID = 61730, stories = {
        { "Party Crasher", "1:27.81", "B", 220573 },
        { "Trapped!", "1:41.16", "C", 220574 },
        { "Loosed Loa", "1:58.92", "D", 220575 },
        { "Why Did it Have to Be Snakes?", "2:09.17", "F", 230852 },
    } },
    { name = "Sunkiller Sanctum", zone = "Voidstorm", achievementID = 61732, stories = {
        { "Core of the Problem", "1:29.66", "B", 220597 },
        { "Not What I Expected", "1:49.11", "D", 220599 },
        { "The Gravitational Effect", "2:31.52", "F", 220598 },
    } },
    { name = "Atal'Aman", zone = "Zul'Aman", achievementID = 61729, stories = {
        { "Toadly Unbecoming", "1:32.41", "C", 220583 },
        { "Venomous Vapors", "1:46.18", "D", 230851 },
        { "Totem Annihilation", "1:46.19", "D", 220581 },
        { "Ritual Interrupted", "1:57.75", "D", 220582 },
    } },
    { name = "The Shadow Enclave", zone = "Quel'Thalas", achievementID = 61727, stories = {
        { "Traitor's Due", "1:32.89", "C", 220577 },
        { "Mirror Shine", "2:02.17", "F", 220579 },
        { "Shadowy Supplies", "2:07.19", "F", 220578 },
        { "Infiltrate and Ameliorate", "2:41.67", "F" },
    } },
    { name = "Shadowguard Point", zone = "Voidstorm", achievementID = 61733, stories = {
        { "Calamitous", "1:44.91", "C", 220594 },
        { "Basalisk Blitz", "1:58.16", "D", 230854 },
        { "Captured Wildlife", "2:16.98", "F", 220595 },
        { "Stolen Mana", "3:31.77", "F", 220593 },
    } },
    { name = "The Grudge Pit", zone = "Harandar", achievementID = 61724, stories = {
        { "Arena Champion", "1:47.51", "D", 220566 },
        { "Dastardly Rotstalk", "2:19.62", "F", 220565 },
        { "Lightbloom Invasion", "2:26.19", "F", 220567 },
        { "Fungal Pharmacon", "4:09.11", "F", 230853 },
    } },
    { name = "Gnarldor Isle", zone = "The Coiled Isle", achievementID = 63437, stories = {
        { "Speaking Their Language", "2:21.50", "F", 230514 },
        { "Olds and Ends", "2:37.45", "F", 230512 },
        { "Minchi's Osseous Adventure", "2:44.50", "F", 230513 },
    } },
}
