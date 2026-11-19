class_name GridPathfinder
extends RefCounted

const DIRECTIONS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

static func reachable(width: int, depth: int, blocked: Dictionary, start: Vector2i) -> Dictionary:
	var visited: Dictionary = {}
	if not _inside(start, width, depth) or blocked.has(start):
		return visited
	var queue: Array[Vector2i] = [start]
	visited[start] = true
	var index := 0
	while index < queue.size():
		var cell := queue[index]
		index += 1
		for direction_value in DIRECTIONS:
			var direction: Vector2i = direction_value
			var next: Vector2i = cell + direction
			if _inside(next, width, depth) and not blocked.has(next) and not visited.has(next):
				visited[next] = true
				queue.append(next)
	return visited

static func path_exists(width: int, depth: int, blocked: Dictionary, start: Vector2i, target: Vector2i) -> bool:
	return reachable(width, depth, blocked, start).has(target)

static func shortest_path(width: int, depth: int, blocked: Dictionary, start: Vector2i, target: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if blocked.has(start) or blocked.has(target):
		return result
	var parents: Dictionary = {start: start}
	var queue: Array[Vector2i] = [start]
	var index := 0
	while index < queue.size():
		var cell := queue[index]
		index += 1
		if cell == target:
			break
		for direction_value in DIRECTIONS:
			var direction: Vector2i = direction_value
			var next: Vector2i = cell + direction
			if _inside(next, width, depth) and not blocked.has(next) and not parents.has(next):
				parents[next] = cell
				queue.append(next)
	if not parents.has(target):
		return result
	var cursor := target
	while cursor != start:
		result.push_front(cursor)
		cursor = parents[cursor]
	result.push_front(start)
	return result

static func _inside(cell: Vector2i, width: int, depth: int) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < depth
