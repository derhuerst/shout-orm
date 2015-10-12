# key prefix is `g`
module.exports = (orm) ->
	return {

		has: (name) ->
			return orm._exists "g:#{name}"
			.then (exists) -> !!exists

		# todo: rename to `set`?
		add: (name, key, locked = false) ->
			return orm._set "g:#{name}", JSON.stringify
				k:	key
				l:	locked

		get: (name) ->
			return orm._get "g:#{name}"
			.then (data) ->
				if not data then throw boom.notFound "Group `#{name}` doesn't exist."
				data = JSON.parse data
				return {
					key:	data.k
					locked:	data.l
				}

		lock: (name) ->
			self = this
			return @get name
			.then (group) ->
				if group.locked then return   # already locked
				else return self.add name, group.key, true

		rm: (name) -> orm._del "g:#{name}"

	}
