class_name FactorBreakdownList
extends VBoxContainer
## Displays ordered +/- factor attribution rows (rank 4) inside
## `MetricBreakdownPopover` with semantic Yeşim/Köz/Buz indicators.

var _rows: Array[PanelContainer] = []


func _init() -> void:
	name = "FactorBreakdownList"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override(&"separation", 4)


func set_factors(factors: Array[MetricAnalyticsViewModel.FactorContribution]) -> void:
	clear_factors()
	if factors.is_empty():
		var empty_panel: PanelContainer = PanelContainer.new()
		empty_panel.add_theme_stylebox_override(&"panel", OtukenThemeFactory.build_card_style(
			NeoSteppePalette.BRONZE_DARK, 1, NeoSteppePalette.OBSIDIAN_DEEP, 6, 4))
		var empty_lbl: Label = Label.new()
		empty_lbl.theme_type_variation = &"MutedLabel"
		empty_lbl.text = "Aktif sapma etkeni saptanmadı."
		empty_panel.add_child(empty_lbl)
		add_child(empty_panel)
		_rows.append(empty_panel)
		return

	for factor: MetricAnalyticsViewModel.FactorContribution in factors:
		if factor == null:
			continue
		var sem_col: Color = NeoSteppePalette.get_semantic_color(factor.tone_id)
		var card: PanelContainer = PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override(&"panel", OtukenThemeFactory.build_card_style(
			Color(sem_col.r, sem_col.g, sem_col.b, 0.55), 1, NeoSteppePalette.CHARCOAL_SURFACE, 8, 4))

		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_theme_constant_override(&"separation", 6)
		card.add_child(hbox)

		var lbl: Label = Label.new()
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.theme_type_variation = &"CaptionLabel"
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.text = factor.label
		lbl.add_theme_color_override(&"font_color", NeoSteppePalette.TEXT_PRIMARY)
		hbox.add_child(lbl)

		var badge: Label = Label.new()
		badge.theme_type_variation = &"CaptionLabel"
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		badge.text = factor.percent_text
		badge.add_theme_color_override(&"font_color", sem_col)
		hbox.add_child(badge)

		add_child(card)
		_rows.append(card)


func clear_factors() -> void:
	for r: PanelContainer in _rows:
		if r != null and is_instance_valid(r):
			if r.get_parent() == self:
				remove_child(r)
			r.free()
	_rows.clear()
