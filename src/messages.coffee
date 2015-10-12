async =			require 'async'





# messages in a group
# key prefix is `m:{group}`
module.exports = (orm) ->
	return {

		has: (group, id) ->
			return orm._exists "m:#{group}:#{id}"
			.then (exists) -> !!exists

		get: (group, id) ->
			return orm._get "m:#{group}:#{id}"
			.then (data) ->
				if not data then throw boom.notFound "Message `#{id}` doesn't exist in group `#{group}`."
				data = JSON.parse data
				return {
					date:	data.d
					body:	data.b
				}

		add: (groupId, id, body, date = Date.now()) ->
			self = this
			return orm.groups.get groupId
			.then (group) ->
				if group.locked then throw new Error "The group `#{group}` is locked."
				orm._set "m:#{groupId}:#{id}", JSON.stringify
					d:	0 + date
					b:	body
			.then () -> orm.redis.publish 'm', "#{groupId}:#{id}"

		all: (group) ->
			self = this
			# todo: find a way to stream keys for performance
			return new Promise (resolve, reject) ->
				results = []
				orm._keys "m:#{group}:*"
				.then (ids) ->
					async.eachLimit ids, 50, ((id, cb) ->
						# todo: use [redis transactions](http://redis.io/topics/transactions) or at least [redis pipelining](http://redis.io/topics/pipelining)
						self.get group, id.split(':')[2]
						.then (message) ->
							results.push message
							cb()
					), () ->
						resolve results

		rm: (group, id) -> orm._del "m:#{group}:#{id}"

	}
