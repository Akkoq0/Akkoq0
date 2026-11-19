class_name TraditionResearchCatalog
extends RefCounted
## Data factory (rank 1). Supplies the curated 4-branch Steppe Tradition &
## Military Research tree (`Bozkır Harbi`, `Lojistik & Su`, `Töre & Kurultay`,
## `Zanaat & Demir`) with acyclic directed prerequisites and deterministic yields.


static func get_all_nodes() -> Array[TraditionResearchNode]:
	var nodes: Array[TraditionResearchNode] = []

	# === Branch 0: Bozkır Harbi (Steppe Warfare) =============================
	nodes.append(_make_node(
		&"yelme_gozculeri",
		"Yelme Gözcüleri",
		"Öncü hafif süvari keşif hatlarını genişleterek baskın ve manevra hızını artırır.",
		GameEnums.ResearchBranch.STEPPE_WARFARE,
		1,
		PackedStringArray(),
		20,
		1,
		0.05, 0.0, 0.06, 0.0, 0.0, 0.0, 0.0, 0.0,
		"+%5 Saldırı · +%6 Manevra Hızı"
	))
	nodes.append(_make_node(
		&"kurt_kapani_ustaligi",
		"Kurt Kapanı Ustalığı",
		"Sahte ricat sırasında kanatların eşzamanlı dönüş disiplinini keskinleştirir.",
		GameEnums.ResearchBranch.STEPPE_WARFARE,
		2,
		PackedStringArray(["yelme_gozculeri"]),
		35,
		2,
		0.10, 0.03, 0.08, 0.0, 0.0, 0.0, 0.0, 0.0,
		"+%10 Saldırı · +%3 Savunma · +%8 Hız"
	))
	nodes.append(_make_node(
		&"cift_kanat_tolgama",
		"Çift Kanat Tolgama",
		"Orta cepheyi kilitleyip ağır ve hafif kanatları çifte kıskaçta birleştirir.",
		GameEnums.ResearchBranch.STEPPE_WARFARE,
		3,
		PackedStringArray(["kurt_kapani_ustaligi"]),
		55,
		3,
		0.15, 0.10, 0.05, 0.0, 0.0, 0.0, 0.0, 0.0,
		"+%15 Saldırı · +%10 Savunma · +%5 Hız"
	))

	# === Branch 1: Lojistik & Su (Logistics & Water) =========================
	nodes.append(_make_node(
		&"yeralti_kuyu_agi",
		"Yeraltı Kuyu Ağı",
		"Gizli sarnıç ve tulum tedarikiyle Zud ve kuyu sabotajına karşı susuzluk direncini artırır.",
		GameEnums.ResearchBranch.LOGISTICS_AND_WATER,
		1,
		PackedStringArray(),
		20,
		1,
		0.0, 0.0, 0.0, 0.15, 0.08, 0.0, 0.0, 0.0,
		"+%15 Su Dayanımı · +%8 Ulak Hızı"
	))
	nodes.append(_make_node(
		&"kislak_erzak_menzili",
		"Kışlak Erzak Menzili",
		"Kışlak hatları arasında korumalı kervan ambarları kurarak kış yıpranmasını düşürür.",
		GameEnums.ResearchBranch.LOGISTICS_AND_WATER,
		2,
		PackedStringArray(["yeralti_kuyu_agi"]),
		35,
		2,
		0.0, 0.08, 0.0, 0.20, 0.10, 0.04, 0.0, 0.0,
		"+%20 Su Dayanımı · +%8 Savunma · +%10 Ulak"
	))
	nodes.append(_make_node(
		&"bozkir_ulak_menzili",
		"Ötüken Ulak Menzili",
		"Yedek at menzilleriyle emir ulaştırma gecikmesini kısaltır ve pusudan kaçışı kolaylaştırır.",
		GameEnums.ResearchBranch.LOGISTICS_AND_WATER,
		3,
		PackedStringArray(["kislak_erzak_menzili"]),
		50,
		2,
		0.0, 0.04, 0.10, 0.15, 0.25, 0.0, 0.0, 0.0,
		"+%25 Ulak Hızı · +%10 Sefer Hızı · +%15 Su"
	))

	# === Branch 2: Töre & Kurultay (Law & Sovereignty) =======================
	nodes.append(_make_node(
		&"toy_ulus_tuzugu",
		"Toy & Ülüş Tüzüğü",
		"Boylara dağıtılan Toy paylarını yazılı ilkelere bağlayarak vergi ve sadakat kaybını azaltır.",
		GameEnums.ResearchBranch.TORE_AND_KURULTAY,
		1,
		PackedStringArray(),
		25,
		1,
		0.0, 0.0, 0.0, 0.0, 0.0, 0.08, 4.0, 0.0,
		"+%8 Vergi Verimi · +4 Kut Dengesi"
	))
	nodes.append(_make_node(
		&"ak_sakallilar_yargisi",
		"Ak Sakallılar Yargısı",
		"Kurultay meclisinde hanedan veraset ve töre uzlaşmasını kurumsallaştırır.",
		GameEnums.ResearchBranch.TORE_AND_KURULTAY,
		2,
		PackedStringArray(["toy_ulus_tuzugu"]),
		40,
		2,
		0.0, 0.05, 0.0, 0.0, 0.0, 0.10, 8.0, 0.0,
		"+%10 Vergi Verimi · +8 Kut Dengesi · +%5 Savunma"
	))
	nodes.append(_make_node(
		&"otuken_il_yasasi",
		"Ötüken İl Yasası",
		"Cihanşümul İl töresiyle merkez otoriteyi pekiştirir ve koalisyon baskısını dengeler.",
		GameEnums.ResearchBranch.TORE_AND_KURULTAY,
		3,
		PackedStringArray(["ak_sakallilar_yargisi"]),
		60,
		3,
		0.04, 0.08, 0.0, 0.0, 0.0, 0.14, 12.0, 0.0,
		"+%14 Vergi Verimi · +12 Kut · +%8 Savunma"
	))

	# === Branch 3: Zanaat & Demir (Crafts & Iron) ============================
	nodes.append(_make_node(
		&"koruklu_ocak_ustaligi",
		"Körüklü Ocak Ustalığı",
		"Göçer demirci ocaklarında hava akışını güçlendirerek çelik ergitme verimini yükseltir.",
		GameEnums.ResearchBranch.CRAFTS_AND_IRON,
		1,
		PackedStringArray(),
		25,
		1,
		0.03, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.12,
		"+%12 Çelik Verimi · +%3 Saldırı"
	))
	nodes.append(_make_node(
		&"sert_su_verme_celigi",
		"Sert Su Verme Çeliği",
		"Zırh plakaları ve temren uçlarına su vererek deliş ve dayanıklılığı artırır.",
		GameEnums.ResearchBranch.CRAFTS_AND_IRON,
		2,
		PackedStringArray(["koruklu_ocak_ustaligi"]),
		40,
		2,
		0.08, 0.06, 0.0, 0.0, 0.0, 0.0, 0.0, 0.15,
		"+%15 Çelik Verimi · +%8 Saldırı · +%6 Savunma"
	))
	nodes.append(_make_node(
		&"gok_demiri_isleme",
		"Gök Demiri İşleme",
		"Meteor demirini usta ellerde işleyerek seçkin Börü mızraklarına üstün zırh ve saldırı kazandırır.",
		GameEnums.ResearchBranch.CRAFTS_AND_IRON,
		3,
		PackedStringArray(["sert_su_verme_celigi", "yelme_gozculeri"]),
		65,
		3,
		0.14, 0.12, 0.0, 0.0, 0.0, 0.0, 0.0, 0.25,
		"+%25 Çelik Verimi · +%14 Saldırı · +%12 Savunma"
	))

	return nodes


static func get_nodes_for_branch(branch: GameEnums.ResearchBranch) -> Array[TraditionResearchNode]:
	var filtered: Array[TraditionResearchNode] = []
	for node: TraditionResearchNode in get_all_nodes():
		if node != null and node.branch == branch:
			filtered.append(node)
	return filtered


static func get_node_by_id(node_id: StringName) -> TraditionResearchNode:
	if node_id == &"":
		return null
	for node: TraditionResearchNode in get_all_nodes():
		if node != null and node.node_id == node_id:
			return node
	return null


static func get_all_branches() -> Array[GameEnums.ResearchBranch]:
	return [
		GameEnums.ResearchBranch.STEPPE_WARFARE,
		GameEnums.ResearchBranch.LOGISTICS_AND_WATER,
		GameEnums.ResearchBranch.TORE_AND_KURULTAY,
		GameEnums.ResearchBranch.CRAFTS_AND_IRON,
	]


static func format_branch_name(branch: GameEnums.ResearchBranch) -> String:
	match branch:
		GameEnums.ResearchBranch.STEPPE_WARFARE:
			return "Bozkır Harbi"
		GameEnums.ResearchBranch.LOGISTICS_AND_WATER:
			return "Lojistik & Su"
		GameEnums.ResearchBranch.TORE_AND_KURULTAY:
			return "Töre & Kurultay"
		GameEnums.ResearchBranch.CRAFTS_AND_IRON:
			return "Zanaat & Demir"
	return "Gelenek"


static func _make_node(
		p_id: StringName,
		p_title: String,
		p_desc: String,
		p_branch: GameEnums.ResearchBranch,
		p_tier: int,
		p_prereqs: PackedStringArray,
		p_cost: int,
		p_duration: int,
		p_atk: float,
		p_def: float,
		p_spd: float,
		p_water: float,
		p_courier: float,
		p_tax: float,
		p_kut: float,
		p_steel: float,
		p_summary: String) -> TraditionResearchNode:
	var n: TraditionResearchNode = TraditionResearchNode.new()
	n.node_id = p_id
	n.title = p_title
	n.description = p_desc
	n.branch = p_branch
	n.tier = p_tier
	n.prerequisites = p_prereqs
	n.silver_cost = p_cost
	n.duration_seasons = p_duration
	n.melee_attack_bonus = p_atk
	n.defense_bonus = p_def
	n.speed_bonus = p_spd
	n.water_resilience_bonus = p_water
	n.courier_speed_bonus = p_courier
	n.tax_efficiency_bonus = p_tax
	n.kut_stability_bonus = p_kut
	n.steel_craft_bonus = p_steel
	n.effect_summary = p_summary
	return n
