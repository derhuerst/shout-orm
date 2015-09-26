Promise =		require 'bluebird'
redis =			require 'redis'
boom =			require 'boom'
async =			require 'async'





module.exports =



	port:		6379
	host:		'localhost'

	redis:		null

	_get:		null
	_set:		null
	_keys:		null
	_exists:	null



	connect: () ->
		return this if @redis   # already connected

		@redis = redis.createClient @port, @host

		@publish = redis.publish
		@subscribe = redis.subscribe

		@_get = Promise.promisify @redis.get, @redis
		@_set = Promise.promisify @redis.set, @redis
		@_keys = Promise.promisify @redis.keys, @redis
		@_exists = Promise.promisify @redis.exists, @redis

		return this



	publish:	null
	subscribe:	null



	getGroup: (name) ->
		return @_get "g:#{name}"
		.then (data) ->
			if not data
				throw boom.notFound "Group `#{name}` doesn't exist."
			data = JSON.parse data
			return {
				key:	data.k
				locked:	data.l
			}

	groupExists: (name) ->
		return @_exists "g:#{name}"
		.then (exists) -> !!exists

	setGroup: (name, key, locked) ->
		data = JSON.stringify
			k:	key
			l:	locked
		return @_set "g:#{name}", data



	getMessage: (group, id) ->
		return @_get "m:#{group}:#{id}"
		.then (data) ->
			if not data
				throw boom.notFound "Message `#{id}` doesn't exist in group `#{group}`."
			data = JSON.parse data
			return {
				date:	data.d
				body:	data.b
			}

	messageExists: (group, id) ->
		return @_exists "m:#{group}:#{id}"
		.then (exists) -> !!exists

	getMessagesOfGroup: (group) ->
		self = this
		# todo: find a way to stream keys for performance
		return new Promise (resolve, reject) ->
			results = []
			self._keys "m:#{group}:*"
			.then (ids) ->
				async.eachLimit ids, 50, ((id, cb) ->
					# todo: use [redis transactions](http://redis.io/topics/transactions) or at least [redis pipelining](http://redis.io/topics/pipelining)
					self.getMessage group, id
					.then (message) ->
						results.push message
				), () ->
					resolve results

	setMessage: (group, id, date, body) ->
		data = JSON.stringify
			d:	date
			b:	body
		self = this
		return @_set "m:#{group}:#{id}", data
		.then () ->
			self.publish 'm', group



	getUser: (group, id) ->
		return @_get "u:#{group}:#{id}"
		.then (data) ->
			if not data
				throw boom.notFound "User `#{id}` doesn't exist in group `#{group}`."
			data = JSON.parse data
			return {
				system:	data.s
				token:	data.t
			}

	userExists: (group, id) ->
		return @_exists "u:#{group}:#{id}"
		.then (exists) -> !!exists

	getUsersOfGroup: (group) ->
		self = this
		# todo: find a way to stream keys for performance
		return new Promise (resolve, reject) ->
			results = []
			self._keys "u:#{group}:*"
			.then (ids) ->
				async.eachLimit ids, 50, ((id, cb) ->
					# todo: use [redis transactions](http://redis.io/topics/transactions) or at least [redis pipelining](http://redis.io/topics/pipelining)
					self.getUser group, id
					.then (user) ->
						results.push user
				), () ->
					resolve results

	setUser: (group, id, system, token) ->
		data = JSON.stringify
			s:	system
			t:	token
		return @_set "u:#{group}:#{id}", data
