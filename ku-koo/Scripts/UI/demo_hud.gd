class_name DemoHUD
extends CanvasLayer
## Demo-only overlay: controls legend (F1), pigeon debug line, and a visual
## cue for the partner's call (stands in for the stereo-panned sound).
## Not part of the final game UI, which shows only the painted world.

@export var pigeon: Pigeon
@export var partner: PartnerCall
@export var help_label: Label
@export var status_label: Label
@export var partner_cue: Label
@export var show_status: bool = true
## Replaces the controls legend when not empty (each demo has its own).
@export_multiline var help_text: String = ""

const STATE_NAMES := {
	Pigeon.State.IDLE: "parado",
	Pigeon.State.WALK: "a andar",
	Pigeon.State.AIR: "no ar",
	Pigeon.State.PECK: "a bicar",
	Pigeon.State.COO: "a arrulhar",
	Pigeon.State.PUSH: "a empurrar/puxar",
	Pigeon.State.HANG: "pendurado",
}

var _cue_tween: Tween


func _ready() -> void:
	partner_cue.modulate.a = 0.0
	if help_text != "":
		help_label.text = help_text
	if partner:
		partner.called.connect(_on_partner_called)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_help"):
		help_label.visible = not help_label.visible
		status_label.visible = help_label.visible and show_status
	elif event.is_action_pressed(&"reset_demo"):
		get_tree().reload_current_scene()


func _process(_delta: float) -> void:
	if pigeon == null or not status_label.visible:
		return
	var beak := "vazio"
	if pigeon.hold.is_carrying():
		beak = pigeon.hold.carried.display_name
	elif pigeon.hold.is_grabbing():
		beak = "a agarrar"
	var focus := "-"
	if pigeon.peck_ability.focused:
		focus = pigeon.peck_ability.focused.prompt
	var flaps := "inf" if pigeon.max_air_flaps < 0 else str(pigeon.max_air_flaps - pigeon.flaps_used)
	status_label.text = "Estado: %s   |   Bico: %s   |   Bicar: %s   |   Bater asas: %s" % [
		STATE_NAMES.get(pigeon.state, "?"), beak, focus, flaps]


func _on_partner_called(from_position: Vector2) -> void:
	var camera := get_viewport().get_camera_2d()
	var screen := get_viewport().get_visible_rect().size
	var center := camera.get_screen_center_position() if camera else from_position
	var dir := (from_position - center)
	var on_right := dir.x >= 0.0
	partner_cue.text = ("ku-koo  >>" if on_right else "<<  ku-koo")
	partner_cue.reset_size()
	var margin := 24.0
	var y := clampf(screen.y * 0.35 + dir.y * 0.05, margin, screen.y - margin - partner_cue.size.y)
	var x := screen.x - partner_cue.size.x - margin if on_right else margin
	partner_cue.position = Vector2(x, y)
	if _cue_tween:
		_cue_tween.kill()
	partner_cue.modulate.a = 1.0
	_cue_tween = create_tween()
	_cue_tween.tween_interval(1.0)
	_cue_tween.tween_property(partner_cue, "modulate:a", 0.0, 1.2)
