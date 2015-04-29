version = 3
ScenarioInfo = {
    name = 'Aeon Vanilla Campain - Mission 2',
    description = 'This is Zeta Canis. It was once a UEF colony, but it is now in the hands of those cursed Cybrans.\nZeta Canis offers little in resources, but its location makes it a prime staging area for strikes into UEF territory.\nYou will go to Zeta Canis, destroy any Cybran Commanders on the planet, and cleanse the civilian population.\nLeave none alive.',
    type = 'campaign_coop',
    starts = true,
    preview = '',
    size = {512, 512},
    map = '/maps/SCCA_Coop_A02/SCCA_Coop_A02_v03.scmap',
    save = '/maps/SCCA_Coop_A02/SCCA_Coop_A02_v03_save.lua',
    script = '/maps/SCCA_Coop_A02/SCCA_Coop_A02_v03_script.lua',
    Configurations = {
        ['standard'] = {
            teams = {
                { name = 'FFA', armies = {'Player','Cybran','NeutralCybran','Coop1','Coop2','Coop3'} },
            },
            customprops = {
            },
        },
    }}
