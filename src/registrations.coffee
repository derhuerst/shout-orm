shortid =		require 'shortid'
boom =			require 'boom'





# users pending for activation
# key prefix is `r`
module.exports = (orm) ->
	return {

		has: (id) ->
			return orm._exists "r:#{id}"
			.then (exists) -> !!exists

		add: (id, token, ttl = 300) ->
			self = this
			code = shortid.generate()   # activation code
			return orm._set "r:#{id}", code
			.then () -> orm._expire "r:#{id}", 200
			.then () -> orm.redis.publish 'r', "#{token}:#{code}"
			.then () -> return code

		get: (id) ->
			return orm._get "r:#{id}"
			.then (data) ->
				if not data then throw boom.notFound "Registration `#{id}` doesn't exist."
				return data

		activate: (id, code, system, token) ->
			self = this
			return @get id
			.then (storedCode) ->
				if code isnt storedCode then throw boom.unauthorized "Wrong activation code."
				return orm.users.add id, system, token
			.then () -> orm._del "r:#{id}"

		rm: (id) -> orm._del "r:#{id}"

	}
