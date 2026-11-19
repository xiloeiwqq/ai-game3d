class_name LLMWorldService
extends Node

const MAX_ATTEMPTS := 3

var api_url := ""
var api_key := ""
var model := ""
var last_status := "Не настроено"

func _ready() -> void:
	api_url = OS.get_environment("AI_WORLD_API_URL").strip_edges()
	api_key = OS.get_environment("AI_WORLD_API_KEY").strip_edges()
	model = OS.get_environment("AI_WORLD_MODEL").strip_edges()
	if api_url.is_empty() and not api_key.is_empty():
		api_url = "https://api.openai.com/v1/chat/completions"
	if model.is_empty():
		model = "gpt-4o-mini"
	last_status = "Готово" if is_configured() else "API не настроен — доступен честный офлайн-режим"

func is_configured() -> bool:
	return api_url.begins_with("https://") or api_url.begins_with("http://127.0.0.1") or api_url.begins_with("http://localhost")

func generate_world(description: String, options: Dictionary) -> Dictionary:
	if not is_configured():
		return {"ok": false, "error": "LLM API не настроен. Укажите AI_WORLD_API_URL и при необходимости AI_WORLD_API_KEY.", "attempts": 0}
	var correction := ""
	var previous := ""
	for attempt in range(1, MAX_ATTEMPTS + 1):
		last_status = "Запрос к модели: попытка %d/%d" % [attempt, MAX_ATTEMPTS]
		var prompt := _build_prompt(description, options, correction, previous)
		var response: Dictionary = await _send_request(prompt)
		if not response.ok:
			if attempt == MAX_ATTEMPTS:
				return {"ok": false, "error": response.error, "attempts": attempt}
			correction = "Предыдущий HTTP-запрос завершился ошибкой. Верни только корректный JSON."
			continue
		var parsed := _parse_model_json(str(response.content))
		if not parsed.ok:
			correction = parsed.error
			previous = str(response.content).left(10000)
			continue
		var validation := WorldValidator.validate(parsed.world)
		if validation.valid:
			last_status = "JSON получен и проверен"
			return {"ok": true, "world": parsed.world, "attempts": attempt}
		correction = "Исправь ошибки валидатора:\n- " + "\n- ".join(validation.errors)
		previous = JSON.stringify(parsed.world)
	return {"ok": false, "error": "Модель не смогла вернуть корректный и проходимый уровень за %d попытки." % MAX_ATTEMPTS, "attempts": MAX_ATTEMPTS}

func _send_request(prompt: String) -> Dictionary:
	var request := HTTPRequest.new()
	request.timeout = 35.0
	add_child(request)
	var headers := PackedStringArray(["Content-Type: application/json", "Accept: application/json"])
	if not api_key.is_empty():
		headers.append("Authorization: Bearer %s" % api_key)
	var body := {
		"model": model,
		"temperature": 0.65,
		"response_format": {"type": "json_object"},
		"messages": [
			{"role": "system", "content": "You are a secure game-level planner. Output one JSON object only. Never output code, URLs, or file paths."},
			{"role": "user", "content": prompt}
		]
	}
	var start_error := request.request(api_url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if start_error != OK:
		request.queue_free()
		return {"ok": false, "error": "Не удалось начать API-запрос: %s" % error_string(start_error)}
	var completed: Array = await request.request_completed
	request.queue_free()
	var result_code := int(completed[0])
	var http_code := int(completed[1])
	var raw_body: PackedByteArray = completed[3]
	if result_code != HTTPRequest.RESULT_SUCCESS:
		return {"ok": false, "error": "Сетевая ошибка LLM API (код %d)." % result_code}
	var text := raw_body.get_string_from_utf8()
	if http_code < 200 or http_code >= 300:
		return {"ok": false, "error": "LLM API ответил HTTP %d: %s" % [http_code, text.left(300)]}
	var envelope = JSON.parse_string(text)
	if typeof(envelope) != TYPE_DICTIONARY:
		return {"ok": false, "error": "LLM API вернул не JSON-ответ."}
	var content := ""
	if envelope.has("choices") and envelope.choices is Array and not envelope.choices.is_empty():
		content = str(envelope.choices[0].get("message", {}).get("content", ""))
	elif envelope.has("output_text"):
		content = str(envelope.output_text)
	elif envelope.has("schema_version"):
		content = JSON.stringify(envelope)
	if content.is_empty():
		return {"ok": false, "error": "В ответе LLM API нет текстового JSON-содержимого."}
	return {"ok": true, "content": content}

func _parse_model_json(content: String) -> Dictionary:
	var clean := content.strip_edges()
	if clean.begins_with("```"):
		clean = clean.trim_prefix("```json").trim_prefix("```").trim_suffix("```").strip_edges()
	var first := clean.find("{")
	var last := clean.rfind("}")
	if first < 0 or last <= first:
		return {"ok": false, "error": "Ответ модели не содержит JSON-объект."}
	clean = clean.substr(first, last - first + 1)
	var parsed = JSON.parse_string(clean)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"ok": false, "error": "Ответ модели содержит повреждённый JSON."}
	return {"ok": true, "world": parsed}

func _build_prompt(description: String, options: Dictionary, correction: String, previous: String) -> String:
	var object_ids := ResourceCatalog.ids_for("object")
	var collectible_ids := ResourceCatalog.ids_for("collectible")
	var exit_ids := ResourceCatalog.ids_for("exit")
	var prompt := """Создай проходимый уровень для 3D-игры по описанию пользователя.
Описание: %s
Параметры интерфейса: %s

Верни ТОЛЬКО JSON schema_version 1.0 со строгими полями:
schema_version, world_name, theme_id, seed, map{width,depth,cell_size}, environment{floor_id,sky_id,lighting_id}, player_start{cell_x,cell_z}, objects[], collectibles[ровно 3], exit.
Каждый элемент objects/collectibles и exit: resource_id, cell_x, cell_z, rotation.
Допустимые theme_id: %s
Допустимые object resource_id: %s
Допустимые collectible resource_id: %s
Допустимые exit resource_id: %s
floor_id: %s; sky_id: %s; lighting_id: %s
width/depth: 12..40; cell_size: 2.0..4.0; rotation: 0/90/180/270; objects: максимум 140.
Координаты целые и в границах. Не пересекай объекты. Оставь непрерывные проходы шириной минимум одну клетку от старта ко всем предметам и выходу.
Никаких путей к файлам, кода, markdown или дополнительных полей.""" % [description, JSON.stringify(options), JSON.stringify(ResourceCatalog.THEMES), JSON.stringify(object_ids), JSON.stringify(collectible_ids), JSON.stringify(exit_ids), JSON.stringify(ResourceCatalog.data().get("floors", [])), JSON.stringify(ResourceCatalog.data().get("skies", [])), JSON.stringify(ResourceCatalog.data().get("lighting", []))]
	if not correction.is_empty():
		prompt += "\n\nПРЕДЫДУЩИЙ ОТВЕТ НЕКОРРЕКТЕН. %s" % correction
	if not previous.is_empty():
		prompt += "\nПредыдущий ответ для исправления:\n%s" % previous
	return prompt
