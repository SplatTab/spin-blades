@tool
extends EditorPlugin

const BUTTON_ID := 2_029_033_232
const ICON_PROCESS_MODE_PAUSABLE := preload("assets/pausable.svg")
const ICON_PROCESS_MODE_WHEN_PAUSED := preload("assets/when_paused.svg")
const ICON_PROCESS_MODE_ALWAYS := preload("assets/always.svg")
const ICON_PROCESS_MODE_DISABLED := preload("assets/disabled.svg")
const ICON_PROCESS_MODE_INHERIT := preload("assets/inherit.svg")


## Reference to the EditorInterface.
var _editor_interface: EditorInterface
## Reference to the SceneTreeDock node in the editor interface.
var _scene_tree: Tree
var _scene_tree_dock: Node
## Reference to the current open scene.
var _scene_root: Node


## Called when the plugin is initialized.
func _enter_tree() -> void:
	_editor_interface = get_editor_interface()
	var base_control := _editor_interface.get_base_control()

	var scene_tree_dock := _locate_scene_tree_dock(base_control)
	if not scene_tree_dock:
		push_error(tr(&"SceneTreeDock not found in the editor interface."))
		return

	_scene_tree = _locate_scene_tree(scene_tree_dock)
	if not _scene_tree:
		push_error(tr(&"Scene Tree not found in the editor interface."))
		return

	_scene_tree.button_clicked.connect(_on_button_clicked)

	# Keep a reference to the dock so we can listen for tree refreshes if available
	_scene_tree_dock = scene_tree_dock
	if _scene_tree_dock and _scene_tree_dock.has_signal("tree_changed"):
		_scene_tree_dock.connect("tree_changed", Callable(self, "_on_tree_changed"))

	self.scene_changed.connect(_on_scene_changed)
	_on_scene_changed(_editor_interface.get_edited_scene_root())


## Called when the plugin is removed or the editor exits.
func _exit_tree() -> void:
	var tree_item := _scene_tree.get_root()
	while tree_item:
		var button_index := tree_item.get_button_by_id(0, BUTTON_ID)
		if button_index != -1:
			tree_item.erase_button(0, button_index)
		tree_item = tree_item.get_next_in_tree()

	self.scene_changed.disconnect(_on_scene_changed)
	if _scene_tree_dock and _scene_tree_dock.is_connected("tree_changed", Callable(self, "_on_tree_changed")):
		_scene_tree_dock.disconnect("tree_changed", Callable(self, "_on_tree_changed"))
	if _scene_tree:
		_scene_tree.button_clicked.disconnect(_on_button_clicked)

	_scene_tree = null


## When the _scene_root is null, we continuously poll until the editor has a scene loaded.
func _process(_delta: float) -> void:
	var edited_scene_root := _editor_interface.get_edited_scene_root()
	if edited_scene_root:
		_on_scene_changed(edited_scene_root)

func get_selected_node() -> Node:
	var selected_scene = _editor_interface.get_selection().get_selected_nodes()
	if selected_scene.size() > 0:
		return selected_scene[0]
	return null

## Called when the Process Mode indicator button is clicked in the SceneTree.
func _on_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int):
	if column != 0 or id != BUTTON_ID:
		return

	_scene_tree.set_selected(item, 0)
	var selected_node := get_selected_node()
	if not selected_node:
		return

	if mouse_button_index == MOUSE_BUTTON_LEFT:
		selected_node.process_mode = PROCESS_MODE_INHERIT if selected_node.process_mode != PROCESS_MODE_INHERIT else PROCESS_MODE_DISABLED
	elif mouse_button_index == MOUSE_BUTTON_RIGHT:
		selected_node.process_mode = (selected_node.process_mode + 1) % 4

## Called when the edited scene changes.
func _on_scene_changed(scene_root: Node) -> void:
	_scene_root = scene_root
	if _scene_root:
		# Find the TreeItem corresponding to the edited scene root and start there so
		# the TreeItem <-> Node mapping stays aligned even after saving.
		var root_item := _scene_tree.get_root()
		for child in root_item.get_children():
			if child.get_text(0) == _scene_root.name:
				_update_process_mode_indicator.call_deferred(child, _scene_root)
				return
		# Fallback: update from the generic root if no matching child found
		_update_process_mode_indicator.call_deferred()


func _on_tree_changed() -> void:
	# Called when SceneTreeDock signals the tree was rebuilt/refreshed. Re-apply indicators.
	_update_process_mode_indicator.call_deferred()

## This function is called to add the Process Mode indicator buttons in the SceneTree.
## It now traverses using actual Node references to avoid NodePath mismatches after save.
func _update_process_mode_indicator(tree_item: TreeItem = null, node: Node = null) -> void:
	if not _scene_root:
		return

	if not tree_item:
		tree_item = _scene_tree.get_root()

	if not node:
		node = _scene_root

	# Only connect if the node actually exposes the signal to avoid runtime errors
	if node and node.has_signal("editor_state_changed"):
		if not node.editor_state_changed.is_connected(_update_process_mode_indicator.call_deferred):
			node.editor_state_changed.connect(_update_process_mode_indicator.call_deferred)

	var should_add_button := tree_item.get_button_by_id(0, BUTTON_ID) == -1
	var process_mode_text: String
	var process_mode_icon: Texture2D
	match node.process_mode:
		PROCESS_MODE_PAUSABLE:
			process_mode_text = tr(&"Process mode: Pausable")
			process_mode_icon = ICON_PROCESS_MODE_PAUSABLE
		PROCESS_MODE_WHEN_PAUSED:
			process_mode_text = tr(&"Process mode: When Paused")
			process_mode_icon = ICON_PROCESS_MODE_WHEN_PAUSED
		PROCESS_MODE_ALWAYS:
			process_mode_text = tr(&"Process mode: Always")
			process_mode_icon = ICON_PROCESS_MODE_ALWAYS
		PROCESS_MODE_DISABLED:
			process_mode_text = tr(&"Process mode: Disabled")
			process_mode_icon = ICON_PROCESS_MODE_DISABLED
		PROCESS_MODE_INHERIT:
			process_mode_text = tr(&"Process mode: Inherit")
			process_mode_icon = ICON_PROCESS_MODE_INHERIT
		_:
			print("Unknown process mode for node %s: %d" % [node.name, node.process_mode])
			should_add_button = false

	if should_add_button:
		tree_item.add_button(0, process_mode_icon, BUTTON_ID, false, process_mode_text)
		var custom_color := tree_item.get_custom_color(0)
		if custom_color:
			var button_index := tree_item.get_button_by_id(0, BUTTON_ID)
			tree_item.set_button_color(0, button_index, custom_color)

	# Recurse using child node lookups relative to the current node
	for child_tree_item in tree_item.get_children():
		var child_name := child_tree_item.get_text(0)
		var child_node: Node = null
		# If the TreeItem represents the same node (happens for the scene root), match by name
		if node.name == child_name:
			child_node = node
		else:
			child_node = node.get_node_or_null(child_name)
		if child_node:
			_update_process_mode_indicator(child_tree_item, child_node)


## Recursively searches for the Tree control in the editor interface.
func _locate_scene_tree(node: Node) -> Control:
	if node is Tree:
		return node

	for child in node.get_children():
		var found := _locate_scene_tree(child)
		if found:
			return found

	return null

## Recursively searches for the SceneTreeDock node in the editor interface.
func _locate_scene_tree_dock(node: Node) -> Control:
	if node.get_class() == "SceneTreeDock":
		return node

	for child in node.get_children():
		var found := _locate_scene_tree_dock(child)
		if found:
			return found

	return null
