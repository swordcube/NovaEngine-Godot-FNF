class_name StrumLine extends Node2D

@export var opponent:bool = true

@onready var receptors:Node2D = $Receptors
@onready var notes:CanvasGroup = $Notes

var scroll_speed:float = -INF
var downscroll:bool = false

func _ready():
	for receptor in receptors.get_children():
		receptor = receptor as Receptor
		var dir_str:String = Global.dir_to_str(receptor.direction)
		receptor.add_anim("static", "%s static" % dir_str, 24)
		receptor.add_anim("press", "%s press" % dir_str, 24, false)
		receptor.add_anim("confirm", "%s confirm" % dir_str, 24, false)
		receptor.play_anim("static")

func dir_from_event(event:InputEventKey):
	for i in receptors.get_child_count():
		var action:StringName = "note_%s" % Global.dir_to_str(i)
		if event.is_action_pressed(action) or event.is_action_released(action):
			return i
	return -1

func _unhandled_key_input(event:InputEvent):
	if opponent: return
	event = event as InputEventKey
	
	var dir:int = dir_from_event(event)
	if dir == -1: return
	
	var action:StringName = "note_%s" % Global.dir_to_str(dir)
	if event.is_pressed():
		_on_key_down(dir, action)
	else:
		_on_key_up(dir, action)
	
func _on_key_down(dir:int, action:StringName):
	var receptor:Receptor = receptors.get_child(dir)
	if receptor.pressed: return
	receptor.pressed = true
	
	var possible_notes:Array[Node] = notes.get_children().filter(func(note:Note):
		var can_be_hit:bool = (note.time > Conductor.position - Conductor.safe_zone_offset and note.time < Conductor.position + (Conductor.safe_zone_offset * 1.5))
		var too_late:bool = (note.time < Conductor.position - Conductor.safe_zone_offset and not note.was_already_hit)
		return note.strumline == self and note.direction == dir and can_be_hit and not too_late
	)
	if possible_notes.size() > 0:
		possible_notes.sort_custom(sort_hit_notes)
		# delete stacked notes
		for i in possible_notes.size():
			if i == 0: continue
			var note:Note = possible_notes[i]
			if absf(note.time - possible_notes[0].time) <= 5:
				note.queue_free()
			else:
				break
		# delete the real note
		good_note_hit(possible_notes[0])
	
	receptor.play_anim("confirm" if possible_notes.size() > 0 else "press")
	
func good_note_hit(note:Note):
	note.queue_free()

func sort_hit_notes(a:Note, b:Note):
	if not a.should_hit and b.should_hit: return 0
	elif a.should_hit and not b.should_hit: return 1
	return a.time < b.time
	
func _on_key_up(dir:int, action:StringName):
	var receptor:Receptor = receptors.get_child(dir)
	receptor.pressed = false
	receptor.play_anim("static")
