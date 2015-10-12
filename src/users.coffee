# key prefix is `u`
module.exports = (orm) ->
	return {

		has: (id) ->
			return orm._exists "u:#{id}"
			.then (exists) -> !!exists

		add: (id, system, token) ->
			return orm._set "u:#{id}", JSON.stringify
				s:	system   # todo: use abbreviations
				t:	token

		get: (id) ->
			return orm._get "u:#{id}"
			.then (data) ->
				if not data then throw boom.notFound "User `#{id}` doesn't exist."
				data = JSON.parse data
				return {
					system:	data.s
					token:	data.t
				}

		rm: (id) -> orm._del "u:#{id}"

	}
