async =			require 'async'





# users subscribed to a group
# key prefix is `s:{group}`
module.exports = (orm) ->
	return {

		has: (group, id) ->
			return orm._exists "s:#{group}:#{id}"
			.then (exists) -> !!exists

		get: (group, id) ->
			return orm._get "s:#{group}:#{id}"
			.then (data) ->
				if not data then throw boom.notFound "User `#{id}` did not subscribe to group `#{group}`."
				return parseInt data

		add: (groupId, id, date = Date.now()) ->
			self = this
			return orm.groups.get groupId
			.then (group) -> orm._set "s:#{groupId}:#{id}", date + ''
			.then () -> orm.redis.publish 'm', groupId

		all: (group) ->
			self = this
			# todo: find a way to stream keys for performance
			return new Promise (resolve, reject) ->
				results = []
				orm._keys "s:#{group}:*"
				.then (ids) ->
					async.eachLimit ids, 50, ((id, cb) ->
						# todo: use [redis transactions](http://redis.io/topics/transactions) or at least [redis pipelining](http://redis.io/topics/pipelining)
						self.get group, id.split(':')[2]
						.then (user) ->
							results.push user
							cb()
					), () ->
						resolve results

		rm: (group, id) -> orm._del "s:#{group}:#{id}"

	}
